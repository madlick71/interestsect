-- Lokaler Rauchtest: Trigger, Trial, Match-RPC, Entitlement
-- Ausführen: supabase db sql --local -f supabase/tests/smoke_test.sql
-- (Nur für die lokale Entwicklung; legt Testnutzer an.)

begin;

-- Zwei Testnutzer direkt in auth.users (lokal erlaubt)
insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'anna@test.de'),
  ('22222222-2222-2222-2222-222222222222', 'ben@test.de')
on conflict (id) do nothing;

-- 1) Trigger hat Profil + Subscription angelegt?
select 'profile_anna' as check,
       (select count(*) from public.profiles where id = '11111111-1111-1111-1111-111111111111') as should_be_1;
select 'trial_laeuft' as check,
       (select status = 'trialing'
             and trial_end > now()
             and trial_end <= now() + interval '31 days'
        from public.subscriptions
        where user_id = '11111111-1111-1111-1111-111111111111') as should_be_true;

-- 2) Seed-Umfang plausibel?
select 'kategorien' as check, count(*) as anzahl from public.interest_categories; -- 12 erwartet
select 'interessen' as check, count(*) as anzahl from public.interests;          -- ~180 erwartet

-- 3) Gemeinsame Interessen anlegen: 3 für beide, 1 nur für Anna
insert into public.user_interests (user_id, interest_id)
select '11111111-1111-1111-1111-111111111111', id
from public.interests
where slug in ('bouldern-halle', 'imkerei', 'amateurfunk', 'geocaching');

insert into public.user_interests (user_id, interest_id)
select '22222222-2222-2222-2222-222222222222', id
from public.interests
where slug in ('bouldern-halle', 'imkerei', 'amateurfunk', 'sauerteig-brot');

-- 4) Match-RPC als Anna aufrufen
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select 'match_ben' as check,
       user_id = '22222222-2222-2222-2222-222222222222' as should_be_true,
       common_interests as should_be_3,
       shared_interests
from public.find_matches(2, null, 20);

select 'entitlement_trial' as check,
       public.has_active_entitlement() as should_be_true;

commit;
