-- Rauchtest: Interessen-Vorschläge (Tabelle, RLS, Duplikat-Schutz, RPCs)
-- Ausführen: supabase db query --local -f supabase/tests/interest_suggestions_test.sql
-- Voraussetzung: supabase db reset (läuft alle Migrationen inkl. diesem Feature)

begin;

-- Testnutzer: anna + ben (Normaluser), chef (Admin)
insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'anna@test.de'),
  ('22222222-2222-2222-2222-222222222222', 'ben@test.de'),
  ('33333333-3333-3333-3333-333333333333', 'chef@test.de')
on conflict (id) do nothing;

insert into public.app_admins (user_id)
values ('33333333-3333-3333-3333-333333333333')
on conflict (user_id) do nothing;

-- =====================================================================
-- 1) Als Anna: Vorschlag einreichen
-- =====================================================================
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

insert into public.interest_suggestions (category_id, name_de, suggested_by)
select c.id, 'Supaketwerfen', '11111111-1111-1111-1111-111111111111'
from public.interest_categories c
where c.slug = 'sport-bewegung';

select 'anna_sieht_eigene_vorschlaege' as check,
       count(*) as should_be_1
from public.interest_suggestions
where suggested_by = '11111111-1111-1111-1111-111111111111';

-- Duplikat: gleicher Name mit anderem Case/Whitespace -> Trigger-Exception
do $$
declare v_rows int;
begin
  insert into public.interest_suggestions (category_id, name_de, suggested_by)
  select c.id, '  supaketwerfen ', '11111111-1111-1111-1111-111111111111'
  from public.interest_categories c
  where c.slug = 'sport-bewegung';
  get diagnostics v_rows = row_count;
  if v_rows > 0 then
    raise exception 'FEHLER: Duplikat-Vorschlag wurde akzeptiert';
  end if;
exception when others then
  if position('wurde bereits vorgeschlagen' in sqlerrm) = 0 then
    raise exception 'Test fehlgeschlagen (unerwartet): %', sqlerrm;
  end if;
  raise notice 'OK Duplikat abgelehnt: %', sqlerrm;
end $$;

-- Duplikat: Name existiert schon im Katalog
do $$
declare v_rows int;
begin
  insert into public.interest_suggestions (category_id, name_de, suggested_by)
  select i.category_id, upper(i.name_de), '11111111-1111-1111-1111-111111111111'
  from public.interests i
  where i.slug = 'bouldern-halle';
  get diagnostics v_rows = row_count;
  if v_rows > 0 then
    raise exception 'FEHLER: Katalog-Duplikat wurde akzeptiert';
  end if;
exception when others then
  if position('existiert bereits' in sqlerrm) = 0 then
    raise exception 'Test fehlgeschlagen (unerwartet): %', sqlerrm;
  end if;
  raise notice 'OK Katalog-Duplikat abgelehnt: %', sqlerrm;
end $$;

-- Anna ist kein Admin: Genehmigen verweigert, app_admins unsichtbar
do $$
begin
  perform public.approve_interest_suggestion(
    (select id from public.interest_suggestions where name_de = 'Supaketwerfen'));
  raise exception 'FEHLER: Nicht-Admin konnte genehmigen';
exception when others then
  if position('Nur Admins' in sqlerrm) = 0 then
    raise exception 'Test fehlgeschlagen (unerwartet): %', sqlerrm;
  end if;
  raise notice 'OK Genehmigen verweigert: %', sqlerrm;
end $$;

select 'anna_kein_admin' as check,
       (select count(*) from public.app_admins) as should_be_0;

-- =====================================================================
-- 2) Als Ben: fremde Vorschläge unsichtbar, kein direktes Umschreiben
-- =====================================================================
set local request.jwt.claims =
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select 'ben_sieht_fremde_nicht' as check,
       count(*) as should_be_0
from public.interest_suggestions;

update public.interest_suggestions
set status = 'approved'
where name_de = 'Supaketwerfen';

-- Prüfen muss ein Nutzer, der die Zeile sehen darf (Ben sieht sie nicht)
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select 'ben_kein_update' as check,
       (select count(*) from public.interest_suggestions
        where name_de = 'Supaketwerfen' and status = 'pending') as should_be_1;

-- =====================================================================
-- 3) Als Chef (Admin): sehen, genehmigen, ablehnen
-- =====================================================================
set local request.jwt.claims =
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select 'chef_ist_admin' as check,
       (select count(*) from public.app_admins) as should_be_1;

select 'chef_sieht_alle_offenen' as check,
       count(*) as should_be_1
from public.interest_suggestions
where status = 'pending';

-- Genehmigen: Interest wird angelegt (inkl. sauberem Slug), Vorschlag verlinkt
select public.approve_interest_suggestion(
         (select id from public.interest_suggestions where name_de = 'Supaketwerfen'))
       as genehmigt;

select 'approve_legt_interest_an' as check,
       i.slug as erwarteter_slug_supaketwerfen,
       s.status as should_be_approved,
       (s.interest_id = i.id) as should_be_true
from public.interests i
join public.interest_suggestions s on s.interest_id = i.id
where i.slug = 'supaketwerfen';

-- Erneutes Genehmigen desselben Vorschlags -> Exception
do $$
begin
  perform public.approve_interest_suggestion(
    (select id from public.interest_suggestions where name_de = 'Supaketwerfen'));
  raise exception 'FEHLER: Doppelt genehmigt';
exception when others then
  if position('bereits entschieden' in sqlerrm) = 0 then
    raise exception 'Test fehlgeschlagen (unerwartet): %', sqlerrm;
  end if;
  raise notice 'OK Doppelt genehmigt abgelehnt: %', sqlerrm;
end $$;

-- Ablehnen (Chef schlägt selbst vor)
insert into public.interest_suggestions (category_id, name_de, suggested_by)
select c.id, 'Zweite Runde', '33333333-3333-3333-3333-333333333333'
from public.interest_categories c
where c.slug = 'sport-bewegung';

select public.reject_interest_suggestion(
         (select id from public.interest_suggestions where name_de = 'Zweite Runde'))
       as abgelehnt;

select 'reject_markiert' as check,
       status as should_be_rejected,
       (decided_by = '33333333-3333-3333-3333-333333333333') as should_be_true
from public.interest_suggestions
where name_de = 'Zweite Runde';

-- =====================================================================
-- 4) Kategorie ändern: nur Admins, nur offene Vorschläge
-- =====================================================================
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
insert into public.interest_suggestions (category_id, name_de, suggested_by)
select c.id, 'Dritter Versuch', '11111111-1111-1111-1111-111111111111'
from public.interest_categories c
where c.slug = 'sport-bewegung';

-- Nicht-Admin darf nicht umsortieren
do $$
begin
  perform public.set_interest_suggestion_category(
    (select id from public.interest_suggestions where name_de = 'Dritter Versuch'),
    (select id from public.interest_categories where slug = 'technik-digital'));
  raise exception 'FEHLER: Nicht-Admin konnte Kategorie ändern';
exception when others then
  if position('Nur Admins' in sqlerrm) = 0 then
    raise exception 'Test fehlgeschlagen (unerwartet): %', sqlerrm;
  end if;
  raise notice 'OK Umsortieren verweigert: %', sqlerrm;
end $$;

-- Admin sortiert um, Genehmigung übernimmt die neue Kategorie
set local request.jwt.claims =
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select public.set_interest_suggestion_category(
         (select id from public.interest_suggestions where name_de = 'Dritter Versuch'),
         (select id from public.interest_categories where slug = 'technik-digital'))
       as kategorie_geaendert;

select public.approve_interest_suggestion(
         (select id from public.interest_suggestions where name_de = 'Dritter Versuch'))
       as dritter_genehmigt;

select 'kategorie_geandert' as check,
       c.slug as sollte_technik_digital_sein,
       s.status as should_be_approved
from public.interest_suggestions s
join public.interests i on i.id = s.interest_id
join public.interest_categories c on c.id = i.category_id
where s.name_de = 'Dritter Versuch';

-- Bereits entschiedene Vorschläge sind nicht mehr änderbar
do $$
begin
  perform public.set_interest_suggestion_category(
    (select id from public.interest_suggestions where name_de = 'Dritter Versuch'),
    (select id from public.interest_categories where slug = 'sport-bewegung'));
  raise exception 'FEHLER: Entschiedener Vorschlag wurde geändert';
exception when others then
  if position('bereits entschieden' in sqlerrm) = 0 then
    raise exception 'Test fehlgeschlagen (unerwartet): %', sqlerrm;
  end if;
  raise notice 'OK Entschiedener gesperrt: %', sqlerrm;
end $$;

-- =====================================================================
-- 5) Slug-Kollision: zwei ähnliche Namen -> genau eine Interest,
--    beide Vorschläge zeigen darauf
-- =====================================================================
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
insert into public.interest_suggestions (category_id, name_de, suggested_by)
select c.id, 'Ä Ö Ü Test!', '11111111-1111-1111-1111-111111111111'
from public.interest_categories c
where c.slug = 'sport-bewegung';

set local request.jwt.claims =
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
insert into public.interest_suggestions (category_id, name_de, suggested_by)
select c.id, 'ä-ö-ü-test', '22222222-2222-2222-2222-222222222222'
from public.interest_categories c
where c.slug = 'sport-bewegung';

set local request.jwt.claims =
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select public.approve_interest_suggestion(
         (select id from public.interest_suggestions where name_de = 'Ä Ö Ü Test!'))
       as erste_genehmigt;
select public.approve_interest_suggestion(
         (select id from public.interest_suggestions where name_de = 'ä-ö-ü-test'))
       as zweite_genehmigt_sollte_verlinken;

select 'slug_kollision' as check,
       count(distinct i.id) as distinct_interests_should_be_1,
       count(s.id) as verlinkte_vorschlaege_should_be_2
from public.interests i
join public.interest_suggestions s on s.interest_id = i.id
where i.slug like 'ae-oe-ue-test%';

commit;
