#!/usr/bin/env python3
"""InterestSect Massen-Harvest Richtung 100k Interessen.

Quellen (alle öffentlich):
  - Wikidata SPARQL: Personen (Musiker, Bands, Schauspieler, Fußballer,
    Autoren, Regisseure), Werke (Filme, Serien, Videospiele), Musik-
    genres, Städte >100k, Fußballvereine  — jeweils nach Sitelinks
    (Beliebtheit) absteigend, nur mit deutschem Label.
  - Every Noise at Once: komplette Genre-Liste (6291 Genres, HTML).
  - OpenLibrary: Top-Subjects (Buchthemen).

Nutzung:
  python3 scripts/wikidata_harvest.py            # alle Wellen
  Ergebnis: /tmp/harvest/<welle>.json

Hinweis: Wikidata rate-limittet (~30 Queries/Tag pro IP getestet).
Bei HTTP 429/Timeouts: am nächsten Tag fortsetzen. Der Cursor-Ansatz
(Sitelinks-Fenster statt OFFSET) macht Wellen wiederaufnahmefähig.
"""

import json
import os
import re
import time
import unicodedata
import urllib.parse
import urllib.request

OUT = "/tmp/harvest"
os.makedirs(OUT, exist_ok=True)
UA = {"User-Agent": "interestsect-research/0.2 (dev@interestsect.example)"}
MIG = "/Users/stefan/myAiProjects/interestsect/supabase/migrations/"


def http_get(url, accept=None, retries=4):
    h = dict(UA)
    if accept:
        h["Accept"] = accept
    for a in range(retries):
        try:
            req = urllib.request.Request(url, headers=h)
            with urllib.request.urlopen(req, timeout=90) as r:
                return r.read().decode("utf-8", "replace")
        except Exception as e:
            print(f"    retry {a+1}: {e}", flush=True)
            time.sleep(8 * (a + 1))
    raise RuntimeError(f"GET fehlgeschlagen: {url[:80]}")


def sparql(query):
    url = "https://query.wikidata.org/sparql?" + urllib.parse.urlencode(
        {"query": query, "format": "json"}
    )
    return json.loads(http_get(url, accept="application/sparql-results+json"))


def q_entities(where, limit, chunk=10000):
    """Entities mit de-Label nach Sitelinks absteigend; Cursor über Sitelinks-Fenster."""
    rows = []
    cursor = None
    while len(rows) < limit:
        c = f"FILTER(?sl < {cursor})" if cursor is not None else ""
        q = f"""
SELECT ?labelDe ?sl WHERE {{
  {where}
  ?e rdfs:label ?labelDe . FILTER(LANG(?labelDe) = "de")
  ?e wikibase:sitelinks ?sl .
  {c}
}}
ORDER BY DESC(?sl)
LIMIT {chunk}
"""
        try:
            d = sparql(q)
        except Exception as e:
            print(f"    SPARQL-Fehler ({e}) – breche Welle bei {len(rows)} ab", flush=True)
            break
        b = d.get("results", {}).get("bindings", [])
        if not b:
            break
        for x in b:
            rows.append((x["labelDe"]["value"], int(x["sl"]["value"])))
        cursor = b[-1]["sl"]["value"]
        print(f"    … {len(rows)} (Sitelinks-Fenster endet bei {cursor})", flush=True)
        if len(b) < chunk:
            break
    return rows[:limit]


def norm(s):
    s = unicodedata.normalize("NFKD", s.lower())
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def slugify(s):
    s = norm(s).replace(" ", "-")
    return re.sub(r"-+", "-", s)[:80].strip("-")


def load_catalog_keys():
    row = re.compile(r"\('([a-z-]+)','([a-z0-9-]+)','([^']+)',array\[([^\]]*)\]\)")
    names, slugs = set(), set()
    import glob
    for f in sorted(glob.glob(MIG + "20261111*.sql")):
        if "init_schema" in f:
            continue
        t = open(f, encoding="utf-8").read()
        for neu, _s in re.findall(r"set name_de = '([^']+)'\nwhere slug = '([a-z0-9-]+)'", t):
            names.add(norm(neu))
        for cat, slug, name, kws in row.findall(t):
            names.add(norm(name))
            slugs.add(slug)
    return names, slugs


def run_wave(tag, where, limit, category, keywords):
    print(f"[{tag}] Ziel: {limit}", flush=True)
    rows = q_entities(where, limit)
    out = []
    seen = set()
    for name, sl in rows:
        n = norm(name)
        s = slugify(name)
        if not s or n in KAT_NAMES or s in KAT_SLUGS or n in seen:
            continue
        seen.add(n)
        KAT_NAMES.add(n)
        KAT_SLUGS.add(s)
        out.append({"name": name, "slug": s, "sl": sl, "cat": category, "kw": keywords})
    print(f"[{tag}] übernommen: {len(out)}", flush=True)
    json.dump(out, open(f"{OUT}/{tag}.json", "w"), ensure_ascii=False)
    return out


KAT_NAMES, KAT_SLUGS = load_catalog_keys()
print(f"Katalog-Basis: {len(KAT_NAMES)} Namen / {len(KAT_SLUGS)} Slugs", flush=True)

total = []

# ---- Welle A: Personen ----
total += run_wave("musiker", "?e wdt:P106 wd:Q639669 .", 8000, "musiker-bands", ["musik", "star"])
total += run_wave("bands", "?e wdt:P31 wd:Q215627 .", 5000, "musiker-bands", ["band", "musik"])
total += run_wave("schauspieler", "?e wdt:P106 wd:Q33999 .", 8000, "schauspieler-stars", ["film", "star"])
total += run_wave("fussballspieler", "?e wdt:P106 wd:Q937857 .", 5000, "sportler-teams", ["fussball", "idol"])
total += run_wave("autoren", "?e wdt:P106 wd:Q482980 .", 5000, "autoren", ["autor", "buch"])
total += run_wave("regisseure", "?e wdt:P106 wd:Q2526255 .", 1200, "filmkunst", ["regie", "film"])

# ---- Welle B: Werke ----
total += run_wave("filme", "?e wdt:P31 wd:Q11424 .", 22000, "filme-serien", ["film", "klassiker"])
total += run_wave("serien", "?e wdt:P31 wd:Q5398426 .", 5000, "filme-serien", ["serie", "streaming"])
total += run_wave("videospiele", "?e wdt:P31 wd:Q7889 .", 8000, "videospiele", ["spiel", "titel"])

# ---- Welle C: Genres ----
total += run_wave("genres", "?e wdt:P31 wd:Q188451 .", 4000, "musikrichtungen", ["genre", "stil"])

# ---- Welle D: Städte & Vereine ----
total += run_wave(
    "staedte",
    "?e wdt:P31/wdt:P279* wd:Q515 . ?e p:P1082 ?p2 . ?p2 ps:P1082 ?pop . FILTER(?pop > 100000)",
    5000,
    "reiseziele",
    ["stadt", "reise"],
)
total += run_wave("vereine", "?e wdt:P31 wd:Q476028 .", 4000, "sportler-teams", ["verein", "fussball"])

print(f"\nWIKIDATA-GESAMT: {len(total)}", flush=True)
json.dump(total, open(f"{OUT}/wikidata_all.json", "w"), ensure_ascii=False)
