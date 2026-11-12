-- Profilbilder: kleines, rundes Bild links neben dem Namen (Trefferliste,
-- Karte) + Upload auf der Profilseite.
--
-- Speichermodell: Upload nach storage://avatars/<user_id>/avatar.jpg
-- (quadratischer Crop client-seitig), in profiles.avatar_url liegt die
-- öffentliche URL inkl. Cache-Buster (?v=…) — Web, Mobile und RPC können
-- sie direkt rendern.

-- 1) Spalte für die öffentliche Avatar-URL
alter table public.profiles
  add column if not exists avatar_url text;

-- 2) Storage-Bucket: öffentlich lesbar, nur Bilder, max. 2 MB nach
--    client-seitiger Komprimierung
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 3) Storage-RLS: lesen dürfen alle angemeldeten Nutzer (Treffer!),
--    schreiben/löschen nur im eigenen Ordner <user_id>/…
--    (Upsert braucht INSERT + SELECT + UPDATE, siehe Supabase-Doku.)
drop policy if exists "avatars: lesen für angemeldete" on storage.objects;
create policy "avatars: lesen für angemeldete"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars');

drop policy if exists "avatars: eigener Ordner hochladen" on storage.objects;
create policy "avatars: eigener Ordner hochladen"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars: eigener Ordner überschreiben" on storage.objects;
create policy "avatars: eigener Ordner überschreiben"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars: eigener Ordner löschen" on storage.objects;
create policy "avatars: eigener Ordner löschen"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4) find_matches um avatar_url erweitern (Signaturänderung → DROP + CREATE)
drop function if exists public.find_matches(int, text, int);
create or replace function public.find_matches(
  min_common int default 2,
  match_region text default null,
  max_results int default 20
)
returns table (
  user_id uuid,
  display_name text,
  region text,
  bio text,
  avatar_url text,
  lat double precision,
  lng double precision,
  common_interests bigint,
  shared_interests text[]
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id,
         p.display_name,
         p.region,
         p.bio,
         p.avatar_url,
         p.lat,
         p.lng,
         count(*) as common_interests,
         array_agg(i.name_de order by i.name_de) as shared_interests
  from public.user_interests mine
  join public.user_interests theirs
    on theirs.interest_id = mine.interest_id
  join public.profiles p
    on p.id = theirs.user_id
  join public.interests i
    on i.id = theirs.interest_id
  where mine.user_id = auth.uid()
    and theirs.user_id <> auth.uid()
    and (match_region is null or p.region = match_region)
  group by p.id, p.display_name, p.region, p.bio, p.avatar_url, p.lat, p.lng
  having count(*) >= min_common
  order by common_interests desc, p.display_name
  limit max_results;
$$;

revoke all on function public.find_matches(int, text, int) from public;
grant execute on function public.find_matches(int, text, int) to authenticated;
