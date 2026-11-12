#!/usr/bin/env python3
"""Baut aus den Wikidata-Harvest-JSONs eine Top-N-Katalog-Migration.

Nimmt pro Welle die N beliebtesten Einträge (nach Sitelinks), dedupliziert
gegen den bestehenden Katalog und gegen frühere Wellen, legt fehlende
Kategorien an und erzeugt eine idempotente SQL-Migration im Stil der
bestehenden (values + join + on conflict do nothing).

Nutzung:
  python3 scripts/build_wikidata_migration.py [N]      # Default N = 2000
  Ergebnis: supabase/migrations/<ts>_wikidata_top<N>.sql
"""

import glob
import json
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARVEST = os.path.join(ROOT, "scripts", "data", "harvest")
MIG = os.path.join(ROOT, "supabase", "migrations")

TOP = int(sys.argv[1]) if len(sys.argv) > 1 else 2000

# Welle -> (Kategorie-Slug, existiert schon?)
WAVES = [
    ("musiker", "musiker-bands"),
    ("bands", "musiker-bands"),
    ("schauspieler", "schauspieler-stars"),
    ("fussballspieler", "sportler-teams"),
    ("autoren", "autoren"),
    ("regisseure", "filmkunst"),
    ("filme", "filme-serien"),
    ("serien", "filme-serien"),
    ("videospiele", "videospiele"),
    ("genres", "musikrichtungen"),
    ("staedte", "reiseziele"),
    ("vereine", "sportler-teams"),
]

NEW_CATEGORIES = [
    ("schauspieler-stars", "Schauspieler & Stars", "Actors & Stars"),
    ("sportler-teams", "Sportler & Teams", "Athletes & Teams"),
    ("autoren", "Autoren & Literatur", "Authors & Literature"),
    ("filme-serien", "Filme & Serien", "Movies & Shows"),
    ("videospiele", "Videospiele", "Video Games"),
]

NOISE = re.compile(r"^(Liste|List of)\b|:|\d{4}[-–]\d{0,4}$")
MAX_NAME = 60


def norm(s):
    s = unicodedata.normalize("NFKD", s.lower())
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def slugify(s):
    return re.sub(r"-+", "-", norm(s).replace(" ", "-"))[:80].strip("-") or None


def clean_name(name):
    # Klammerzusätze entfernen ("Rammstein (Band)" -> "Rammstein")
    return re.sub(r"\s*\([^)]*\)\s*$", "", name).strip()


def sql_str(s):
    return "'" + s.replace("'", "''") + "'"


def load_catalog_keys():
    """Namen+Slugs aus allen bisherigen Migrationen (gleiche Logik wie Harvest)."""
    row = re.compile(r"\('([a-z-]+)','([a-z0-9-]+)','([^']+)',array\[([^\]]*)\]\)")
    names, slugs = set(), set()
    for f in sorted(glob.glob(MIG + "/*.sql")):
        if "init_schema" in f or os.path.basename(f).startswith("20261112143000"):
            continue
        t = open(f, encoding="utf-8").read()
        for neu, _s in re.findall(r"set name_de = '([^']+)'\nwhere slug = '([a-z0-9-]+)'", t):
            names.add(norm(neu))
        for cat, slug, name, kws in row.findall(t):
            names.add(norm(name))
            slugs.add(slug)
    return names, slugs


def main():
    names, slugs = load_catalog_keys()
    print(f"Katalog-Basis: {len(names)} Namen / {len(slugs)} Slugs")
    used = [("KATALOG", 0)]
    out_rows = []
    stats = []
    for wave, cat in WAVES:
        data = json.load(open(os.path.join(HARVEST, f"{wave}.json")))
        data.sort(key=lambda e: -e["sl"])  # nach Sitelinks (Beliebtheit)
        taken = dropped = 0
        for e in data:
            if taken >= TOP:
                break
            name = clean_name(e["name"])
            if (
                NOISE.search(name)
                or len(name) > MAX_NAME
                or not name.strip()
                or norm(name) in names
            ):
                dropped += 1
                continue
            slug = e["slug"]
            if not slug or slug in slugs:
                dropped += 1
                continue
            names.add(norm(name))
            slugs.add(slug)
            kw = ", ".join(sql_str(k) for k in e["kw"])
            out_rows.append(
                f"  ({sql_str(cat)},{sql_str(slug)},{sql_str(name)},array[{kw}])"
            )
            taken += 1
        stats.append((wave, cat, taken, dropped))
        print(f"[{wave:16}] top {taken:5} (übersprungen {dropped}) -> {cat}")

    ts = "20261112143000"
    path = os.path.join(MIG, f"{ts}_wikidata_top{TOP}.sql")
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            f"""-- interestsect: Wikidata-Top-{TOP} pro Welle (Sitelinks = Beliebtheit)
--
-- Quelle: scripts/data/harvest/*.json (Wikidata SPARQL, CC0; erzeugt mit
-- scripts/wikidata_harvest.py). Pro Welle die {TOP} beliebtesten Entitäten
-- mit deutschem Label, dedupliziert gegen den bestehenden Katalog und
-- gegen frühere Wellen. Klammerzusätze im Namen entfernt; Listen- und
-- Jahres-Artefakte gefiltert. Neue Kategorien für Sterne, Teams, Autoren,
-- Filme/Serien und Videospiele.
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interest_categories (slug, name_de, name_en, sort_order) values
"""
        )
        for i, (slug, de, en) in enumerate(NEW_CATEGORIES, start=17):
            comma = "," if i < 16 + len(NEW_CATEGORIES) else ""
            f.write(f"  ({sql_str(slug)}, {sql_str(de)}, {sql_str(en)}, {i}){comma}\n")
        f.write(
            """
on conflict (slug) do nothing;

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
"""
        )
        f.write(",\n".join(out_rows) + "\n")
        f.write(
            """) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
"""
        )
    total = sum(s[2] for s in stats)
    print(f"\nMigration: {path}")
    print(f"Zeilen: {len(out_rows)} (Top {TOP} je Welle, Summe {total})")
    # Verifikation: keine Doppel-Slugs in der Datei
    all_slugs = re.findall(r"^\s*\('[a-z-]+','([a-z0-9-]+)'", open(path).read(), re.M)
    # obiges Format trifft nicht (wir schreiben mit Leerzeichen) – daher generisch:
    file_slugs = re.findall(r"\('[a-z-]+',\s*'([a-z0-9-]+)',", open(path).read())
    assert len(file_slugs) == len(set(file_slugs)), "Doppel-Slugs in Migration!"
    print("Slug-Check: eindeutig ✓")


if __name__ == "__main__":
    main()
