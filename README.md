# interestsect

Das soziale Netzwerk für **echte Treffen**. Kein Newsfeed, keine Likes, keine
Profilbild-Galerien — die Grundlage jeder Kontaktaufnahme sind gemeinsame
Interessen. 30 Tage kostenlos testen, danach 1 €/Monat. Keine Werbung.

Die Produktvision liegt in [`about.txt`](./about.txt).

## Architektur

```
Flutter-App ────────▶ Supabase (eu-central-1/Frankfurt)  ← alle Nutzerdaten
Next.js (Vercel) ───▶   Postgres · Auth (RLS) · REST-API · Edge Functions
                              │
                              └──▶ Stripe Billing (1 €/Monat, Zahlung nur im Web)
```

- **Backend:** [Supabase](https://supabase.com) — Postgres, Auth mit
  Row-Level-Security, automatisch generierte REST-API. Schema liegt als
  versionierte Migrationen im Repo (Infrastructure as Code).
- **Web:** Next.js 16 (App Router, TypeScript, Tailwind) in [`web/`](./web)
- **Mobile:** Flutter 3 in [`mobile/`](./mobile)
- **Payments:** Stripe Checkout + Webhook-Edge-Functions; der 30-Tage-Trial
  läuft app-seitig über `subscriptions.trial_end`.

## Struktur

```
├── about.txt              # Produktvision
├── supabase/
│   ├── config.toml        # Lokale Konfiguration (Ports 553xx, s.u.)
│   ├── migrations/        # Versioniertes DB-Schema
│   ├── seed.sql           # Interessen-Taxonomie (12 Kategorien, 187 Interessen)
│   ├── functions/         # Edge Functions (stripe-checkout, stripe-webhook)
│   └── tests/             # SQL-Rauchtest
├── web/                   # Next.js-App
└── mobile/                # Flutter-App (iOS/Android)
```

## Lokale Entwicklung

Voraussetzungen: Node ≥ 24, Flutter, Supabase CLI, Docker (z. B. colima).

```bash
# 1) Lokalen Supabase-Stack starten (Migrationen + Seed laufen automatisch)
supabase start

# 2) Zugangsdaten für die Web-App übernehmen (in web/.env.local eintragen)
supabase status -o env

# 3) Web-App
cd web && pnpm install && pnpm dev   # http://localhost:3000

# 4) Mobile (Android-Emulator; iOS-Simulator: SUPABASE_URL=http://localhost:55321)
cd mobile && flutter run

# 5) Rauchtest (Trigger, Trial, Match-Query, Entitlement)
supabase db query --local -f supabase/tests/smoke_test.sql
# oder: docker exec -i supabase_db_interestsect psql -U postgres -d postgres < supabase/tests/smoke_test.sql
```

**Port-Hinweis:** interestsect nutzt lokal den **553xx**-Bereich
(API 55321, DB 55322, Studio 55323, Mailpit 55324), damit weitere lokale
Supabase-Projekte (Standard 54321ff) parallel laufen können.

E-Mail-Links (Magic Login) landen lokal in [Mailpit](http://127.0.0.1:55324).

## Stripe einrichten (Test-Modus)

Einmalig:

```bash
stripe login                                        # Browser-Freigabe
stripe products create --name="interestsect" --description="interestsect-Mitgliedschaft"
stripe prices create --product=prod_XXX --unit-amount=100 --currency=eur \
  --recurring=interval=month                        # price_XXX merken

# Secrets als Function-Secrets setzen (lokal & remote)
supabase secrets set STRIPE_SECRET_KEY=sk_test_XXX
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_XXX   # aus Dashboard/Listener

# Webhook lokal testen
stripe listen --forward-to localhost:55321/functions/v1/stripe-webhook
```

Testkarte: `4242 4242 4242 4242`, beliebiges Zukunftsdatum, CVC 123.

## Deployment

1. Supabase-Projekt in **eu-central-1 (Frankfurt)** anlegen und verknüpfen:
   `supabase link --project-ref <REF>`
2. Migrationen + Seed ausrollen: `supabase db push`
3. Edge Functions deployen: `supabase functions deploy stripe-checkout` und
   `supabase functions deploy stripe-webhook`
4. Web-App auf Vercel (Env-Variablen aus `web/.env.local.example`) — alle
   Nutzerdaten bleiben in Frankfurt; Vercel sieht nur anonyme UI-Requests.
5. Mobile: `flutter build appbundle` / `flutter build ipa` mit
   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

Später lässt sich die [Supabase-GitHub-Integration](https://supabase.com/docs/guides/deployment/branching/github-integration)
aktivieren (Preview-Branches sind ein Pro-Feature); die Struktur im Repo ist
dafür bereits vorbereitet.

## Nächste Schritte

- [ ] Kontaktanfragen-UI (Tabelle + RLS stehen)
- [ ] Events/Treffen mit Geo (Tabelle steht; PostGIS später)
- [ ] Profilseite mit Region/Persönlichem
- [ ] Interessen-Taxonomie gemeinsam erweitern (Seed ist idempotent)
- [ ] App Store / Play Store: Mobile-Abos prüfen (Zahlung läuft übers Web)
