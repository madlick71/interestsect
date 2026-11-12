# InterestSect

Das soziale Netzwerk für **echte Treffen**. Kein Newsfeed, keine Likes, keine
Profilbild-Galerien — die Grundlage jeder Kontaktaufnahme sind gemeinsame
Interessen. 30 Tage kostenlos testen, danach 1 €/Monat. Keine Werbung.

Die Produktvision liegt in [`about.txt`](./about.txt).

## Architektur

```
Flutter-App ────────▶ Supabase (eu-central-1/Frankfurt)  ← alle Nutzerdaten
Next.js (Cloudflare) ▶   Postgres · Auth (RLS) · REST-API · Edge Functions
                              │
                              └──▶ Stripe Billing (1 €/Monat, Zahlung nur im Web)
```

- **Backend:** [Supabase](https://supabase.com) — Postgres, Auth mit
  Row-Level-Security, automatisch generierte REST-API. Schema liegt als
  versionierte Migrationen im Repo (Infrastructure as Code).
- **Web:** Next.js 16 (App Router, TypeScript, Tailwind) in [`web/`](./web) —
  gehostet auf Cloudflare Workers (OpenNext-Adapter), Domain `interestsect.com`
- **Mobile:** Flutter 3 in [`mobile/`](./mobile)
- **Payments:** Stripe Checkout + Webhook-Edge-Functions; der 30-Tage-Trial
  läuft app-seitig über `subscriptions.trial_end`.

## Struktur

```
├── about.txt              # Produktvision
├── supabase/
│   ├── config.toml        # Supabase-CLI-Konfiguration
│   ├── migrations/        # Versioniertes DB-Schema + Taxonomie-Seed
│   │                      # (Seed als Migration → gilt auch für Produktion)
│   ├── functions/         # Edge Functions (stripe-checkout, stripe-webhook)
│   └── tests/             # SQL-Rauchtest
├── web/                   # Next.js-App
└── mobile/                # Flutter-App (iOS/Android)
```

## Interessen-Vorschläge (Moderation)

Fehlt ein Interesse im Katalog, können Nutzer es auf der Interessen-Seite
(Kategorie + Freitext) vorschlagen. Vorschläge landen in
`public.interest_suggestions` (Status `pending`) — **erst nach Genehmigung**
über die Admin-Seite `/admin` (RPCs `approve_interest_suggestion` /
`reject_interest_suggestion`) werden sie in den Katalog `public.interests`
übernommen. Die Kategorie eines offenen Vorschlags kann der Admin vorher
korrigieren (`set_interest_suggestion_category`).

Admins werden in `public.app_admins` verwaltet (`madlick71@gmail.com` ist
eingetragen); weitere Konten per [snippets/make_admin.sql](./supabase/snippets/make_admin.sql).

## Stripe einrichten (Test-Modus)

Einmalig:

```bash
stripe login                                        # Browser-Freigabe
stripe products create --name="interestsect" --description="interestsect-Mitgliedschaft"
stripe prices create --product=prod_XXX --unit-amount=100 --currency=eur \
  --recurring=interval=month                        # price_XXX merken

# Secrets als Function-Secrets setzen
supabase secrets set STRIPE_SECRET_KEY=sk_test_XXX
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_XXX   # aus Dashboard/Listener
```

Testkarte: `4242 4242 4242 4242`, beliebiges Zukunftsdatum, CVC 123.

## Deployment

1. Supabase-Projekt in **eu-central-1 (Frankfurt)** anlegen und verknüpfen:
   `supabase link --project-ref <REF>`
2. Migrationen + Seed ausrollen: `supabase db push`
3. Edge Functions deployen: `supabase functions deploy stripe-checkout` und
   `supabase functions deploy stripe-webhook`
4. Web-App manuell auf Cloudflare Workers deployen (OpenNext-Adapter, eigene
   Domain `interestsect.com` / `www.interestsect.com`, Konfiguration in
   [`web/wrangler.jsonc`](./web/wrangler.jsonc)):

   ```bash
   cd web && pnpm deploy    # = opennextjs-cloudflare build && deploy
   ```

   `NEXT_PUBLIC_*`-Variablen werden zur Build-Zeit aus `web/.env.local`
   eingebrannt (Cloud-Zugangsdaten des Supabase-Projekts, Vorlage:
   `web/.env.local.example`). Runtime-Secrets einmalig pro Worker setzen:
   `npx wrangler secret put GOOGLE_PLACES_API_KEY`. Alle Nutzerdaten bleiben
   in Frankfurt; Cloudflare sieht nur anonyme UI-Requests.
5. Mobile: `flutter build appbundle` / `flutter build ipa` mit
   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

**Branding/Icons:** Favicon-Satz (Schnittmengen-Motiv) und Open-Graph-Bild
liegen als Datei-Konventionen in `web/src/app/` (`favicon.ico`, `icon.svg`,
`icon.png`, `apple-icon.png`, `opengraph-image.png`); Quell-SVGs und
Design-Vorschläge in `web/design/proposals/`. Akzentfarbe: `#FF5A36` (Koralle).

**Google Search Console:** Inhaberverifikation als Domain-Property über den
DNS-TXT-Record `google-site-verification=…` (in Cloudflare gepflegt); der
zugehörige Meta-Tag liegt als Fallback in `web/src/app/layout.tsx`
(`metadata.verification.google`). `sitemap.xml` und `robots.txt` erzeugt
Next.js automatisch aus `web/src/app/sitemap.ts` bzw. `robots.ts` — in der
Search Console genügt die Eingabe von `sitemap.xml` unter *Sitemaps*.

Später lässt sich die [Supabase-GitHub-Integration](https://supabase.com/docs/guides/deployment/branching/github-integration)
aktivieren (Preview-Branches sind ein Pro-Feature); die Struktur im Repo ist
dafür bereits vorbereitet.

## Nächste Schritte

- [ ] Kontaktanfragen-UI (Tabelle + RLS stehen)
- [ ] Events/Treffen mit Geo (Tabelle steht; PostGIS später)
- [ ] Profilseite mit Region/Persönlichem
- [x] Interessen-Taxonomie gemeinsam erweitern (Vorschlags-Workflow inkl. Moderation, s. o.)
- [ ] App Store / Play Store: Mobile-Abos prüfen (Zahlung läuft übers Web)
