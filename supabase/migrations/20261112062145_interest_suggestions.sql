-- Interessen-Vorschläge: Nutzer können fehlende Interessen vorschlagen,
-- sie landen zuerst in einer separaten Tabelle und werden erst nach
-- Prüfung durch einen Admin in den Katalog (public.interests) übernommen.
--
-- Admins: Tabelle public.app_admins (Email madlick71@gmail.com wird unten
-- automatisch eingetragen, falls der Account existiert). Nachtragen später
-- per SQL, siehe supabase/snippets/make_admin.sql.

-- =====================================================================
-- 1) ADMINS — wer Vorschläge genehmigen darf
-- =====================================================================
create table public.app_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.app_admins enable row level security;

-- Jeder sieht nur seine eigene Zeile (non-admins sehen also nichts)
create policy "app_admins: eigene Zeile lesen"
  on public.app_admins for select to authenticated
  using ((select auth.uid()) = user_id);

-- =====================================================================
-- 2) VORSCHLAGS-TABELLE
-- =====================================================================
create table public.interest_suggestions (
  id           uuid primary key default gen_random_uuid(),
  category_id  uuid not null references public.interest_categories(id) on delete cascade,
  name_de      text not null check (length(btrim(name_de)) between 1 and 80),
  status       text not null default 'pending'
               check (status in ('pending', 'approved', 'rejected')),
  interest_id  uuid references public.interests(id) on delete set null,
  suggested_by uuid not null references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  decided_at   timestamptz,
  decided_by   uuid references auth.users(id) on delete set null
);

create index interest_suggestions_status_idx
  on public.interest_suggestions (status, created_at);

alter table public.interest_suggestions enable row level security;

-- Vorschläge: eigene sehen, Admins sehen alle
-- ((select auth.uid()) cached die JWT-Auswertung pro Query, s. Linter)
create policy "suggestions: eigene oder admin lesen"
  on public.interest_suggestions for select to authenticated
  using (
    (select auth.uid()) = suggested_by
    or exists (
      select 1 from public.app_admins a
      where a.user_id = (select auth.uid())
    )
  );

-- Selbst einreichen (RLS erzwingt die eigene User-ID); Ändern/Löschen
-- nur über die Admin-RPCs oder die Service Role
create policy "suggestions: selbst einreichen"
  on public.interest_suggestions for insert to authenticated
  with check ((select auth.uid()) = suggested_by);

-- Explizite Grants (falls das Projekt neue Tabellen nicht automatisch
-- über die Data API freigibt); RLS bleibt der eigentliche Schutz
grant select, insert on public.interest_suggestions to authenticated;
grant select on public.app_admins to authenticated;

-- =====================================================================
-- 3) DUPLIKAT-SCHUTZ beim Einreichen
--    (exakt gleicher Name wie im Katalog oder wie ein offener Vorschlag)
-- =====================================================================
create or replace function public.interest_suggestions_check_duplicate()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.interests i
    where lower(btrim(i.name_de)) = lower(btrim(new.name_de))
  ) then
    raise exception '„%" existiert bereits im Katalog', btrim(new.name_de);
  end if;

  if exists (
    select 1 from public.interest_suggestions s
    where s.status = 'pending'
      and lower(btrim(s.name_de)) = lower(btrim(new.name_de))
  ) then
    raise exception '„%" wurde bereits vorgeschlagen und wartet auf Prüfung', btrim(new.name_de);
  end if;

  return new;
end;
$$;

create trigger interest_suggestions_no_duplicates
  before insert on public.interest_suggestions
  for each row execute function public.interest_suggestions_check_duplicate();

-- =====================================================================
-- 4) SLUG-HELPER (kleingeschrieben, Umlaute ausgeschrieben, Bindestriche)
-- =====================================================================
create or replace function public.slugify_interest_name(p_name text)
returns text
language sql
immutable
set search_path = public
as $$
  select nullif(trim(both '-' from regexp_replace(
    replace(replace(replace(replace(lower(coalesce(p_name, '')),
      'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue'), 'ß', 'ss'),
    '[^a-z0-9]+', '-', 'g'
  )), '')
$$;

-- =====================================================================
-- 5) ADMIN-RPCs: genehmigen / ablehnen
--    Genehmigen legt die Interest an (unique Slug) bzw. verlinkt einen
--    inzwischen bereits existierenden und markiert den Vorschlag.
-- =====================================================================
create or replace function public.approve_interest_suggestion(p_suggestion_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sug         public.interest_suggestions%rowtype;
  v_base        text;
  v_slug        text;
  v_n           int := 0;
  v_interest_id uuid;
begin
  if not exists (select 1 from public.app_admins where user_id = auth.uid()) then
    raise exception 'Nur Admins dürfen Vorschläge genehmigen';
  end if;

  select * into v_sug
  from public.interest_suggestions
  where id = p_suggestion_id
  for update;

  if not found then
    raise exception 'Vorschlag nicht gefunden';
  end if;
  if v_sug.status <> 'pending' then
    raise exception 'Vorschlag wurde bereits entschieden (%)', v_sug.status;
  end if;

  -- Existiert der Name (oder der daraus erzeugte Slug) inzwischen schon
  -- im Katalog? Dann nur verlinken statt ein Duplikat anlegen.
  select id into v_interest_id
  from public.interests
  where lower(btrim(name_de)) = lower(btrim(v_sug.name_de))
     or slug = public.slugify_interest_name(v_sug.name_de)
  limit 1;

  if v_interest_id is null then
    v_base := public.slugify_interest_name(v_sug.name_de);
    if v_base is null then
      raise exception 'Aus „%" lässt sich kein Slug erzeugen', v_sug.name_de;
    end if;

    v_slug := v_base;
    loop
      exit when not exists (select 1 from public.interests i where i.slug = v_slug);
      v_n := v_n + 1;
      v_slug := v_base || '-' || v_n;
    end loop;

    insert into public.interests (category_id, slug, name_de, keywords)
    values (v_sug.category_id, v_slug, btrim(v_sug.name_de), '{}'::text[])
    returning id into v_interest_id;
  end if;

  update public.interest_suggestions
  set status      = 'approved',
      interest_id = v_interest_id,
      decided_at  = now(),
      decided_by  = auth.uid()
  where id = p_suggestion_id;

  return v_interest_id;
end;
$$;

create or replace function public.reject_interest_suggestion(p_suggestion_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.app_admins where user_id = auth.uid()) then
    raise exception 'Nur Admins dürfen Vorschläge ablehnen';
  end if;

  update public.interest_suggestions
  set status     = 'rejected',
      decided_at = now(),
      decided_by = auth.uid()
  where id = p_suggestion_id and status = 'pending';

  if not found then
    raise exception 'Vorschlag nicht gefunden oder bereits entschieden';
  end if;
end;
$$;

revoke all on function public.approve_interest_suggestion(uuid) from public;
grant execute on function public.approve_interest_suggestion(uuid) to authenticated;
revoke all on function public.reject_interest_suggestion(uuid) from public;
grant execute on function public.reject_interest_suggestion(uuid) to authenticated;

-- =====================================================================
-- 6) Projekt-Owner (madlick71@gmail.com) als Admin eintragen,
--    falls der Account schon existiert (idempotent)
-- =====================================================================
insert into public.app_admins (user_id)
select id from auth.users where email = 'madlick71@gmail.com'
on conflict (user_id) do nothing;
