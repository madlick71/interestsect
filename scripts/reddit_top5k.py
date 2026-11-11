#!/usr/bin/env python3
"""InterestSect Reddit-Top-5k-Pipeline (Batch 4+).

Voraussetzung: Registrierte Reddit-App (Typ script) mit Client-ID/Secret
sowie Bot-Konto (Benutzername + Passwort, hier: GrapeAcceptable7171).

Aufruf:
  python3 reddit_top5k.py <client_id> <client_secret> <bot_user> <bot_pass>

Schritte:
  1. OAuth-Token per password-grant holen
  2. /subreddits/popular seitenweise abrufen (100/Seite) bis ~5.000
     oder Listenende; speichert name, subscribers, public_description
  3. Gegen den InterestSect-Katalog (alle Migrationen) matchen
  4. Rankliste unverdeckter Kandidaten + Beschreibungen ausgeben
     (für die manuelle Kuratierung -> Batch-4-Migration)
Ergebnisdateien: reddit_top5k_raw.json, reddit_top5k_gaps.txt
"""
import json
import re
import sys
import time
import unicodedata
import glob
import urllib.parse
import urllib.request

MIGRATIONS = "/Users/stefan/myAiProjects/interestsect/supabase/migrations/"
TARGET = 5000
PAGE = 100


def token(client_id, secret, user, pw):
    data = urllib.parse.urlencode(
        {
            "grant_type": "password",
            "username": user,
            "password": pw,
        }
    ).encode()
    req = urllib.request.Request(
        "https://www.reddit.com/api/v1/access_token",
        data=data,
        headers={
            "User-Agent": "interestsect-pipeline/0.1 by GrapeAcceptable7171",
            "Content-Type": "application/x-www-form-urlencoded",
        },
    )
    import base64

    basic = base64.b64encode(f"{client_id}:{secret}".encode()).decode()
    req.add_header("Authorization", f"Basic {basic}")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)["access_token"]


def fetch_page(tok, after=None):
    url = f"https://oauth.reddit.com/subreddits/popular?limit={PAGE}"
    if after:
        url += f"&after={after}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {tok}",
            "User-Agent": "interestsect-pipeline/0.1 by GrapeAcceptable7171",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def norm(s):
    s = unicodedata.normalize("NFKD", s.lower())
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9 ]", "", s).strip()


def load_catalog():
    row = re.compile(r"\('([a-z-]+)','([a-z0-9-]+)','([^']+)',array\[([^\]]*)\]\)")
    norms = set()
    for f in sorted(glob.glob(MIGRATIONS + "20261111*.sql")):
        if "init_schema" in f:
            continue
        text = open(f, encoding="utf-8").read()
        for neu, _slug in re.findall(
            r"set name_de = '([^']+)'\nwhere slug = '([a-z0-9-]+)'", text
        ):
            norms.add(norm(neu))
        for _cat, slug, name, kws in row.findall(text):
            norms.add(norm(name))
            norms.add(norm(slug.replace("-", " ")))
            norms |= {norm(k.strip("'")) for k in kws.split(",")}
    return norms


def main():
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)
    client_id, secret, user, pw = sys.argv[1:5]

    print("Hole OAuth-Token ...")
    tok = token(client_id, secret, user, pw)
    print("Token OK.")

    subs, after = [], None
    while len(subs) < TARGET:
        try:
            d = fetch_page(tok, after)
        except Exception as e:
            print("Fehler beim Abruf:", e, "– warte 10s und versuche weiter")
            time.sleep(10)
            continue
        children = d.get("data", {}).get("children", [])
        if not children:
            break
        for c in children:
            s = c["data"]
            subs.append(
                {
                    "name": s["display_name"],
                    "subscribers": s.get("subscribers", 0),
                    "desc": (s.get("public_description") or "")[:200],
                    "over18": s.get("over18", False),
                }
            )
        after = children[-1]["data"].get("name")
        print(f"  {len(subs)} Subreddits gesammelt ...")
        time.sleep(1.1)  # Rate-Limit schonen
        if not after:
            break

    json.dump(subs, open("reddit_top5k_raw.json", "w"), ensure_ascii=False, indent=1)
    print(f"Rohdaten: {len(subs)} Subreddits -> reddit_top5k_raw.json")

    kat = load_catalog()
    gaps = []
    for s in subs:
        if s["over18"]:
            continue
        n = norm(s["name"])
        covered = any(n == k or (len(n) >= 5 and (n in k.split() or k in n.split())) for k in kat)
        if not covered:
            gaps.append(s)
    gaps.sort(key=lambda x: -x["subscribers"])
    with open("reddit_top5k_gaps.txt", "w", encoding="utf-8") as f:
        for g in gaps:
            f.write(f"{g['name']:28} {g['subscribers']:>10,}  {g['desc']}\n")
    print(f"Unverdeckte Kandidaten: {len(gaps)} -> reddit_top5k_gaps.txt")
    print("Top 60:")
    for g in gaps[:60]:
        print(f"  {g['name']:26} {g['subscribers']:>10,}  {g['desc'][:60]}")


if __name__ == "__main__":
    main()
