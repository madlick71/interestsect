-- Geocoding im Profil: Koordinaten der gewählten Region speichern,
-- damit die Karte („Treffer auf der Karte") Nutzer exakt verorten kann.
-- Quelle: Google Places (New) Details, siehe /api/places/details.

alter table public.profiles
  add column if not exists lat double precision,
  add column if not exists lng double precision;

-- find_matches um lat/lng erweitern, damit die /map-Seite die Treffer
-- in einer Abfrage inklusive Koordinaten laden kann.
-- Rückgabetyp-Änderung erfordert DROP (create or replace allein darf
-- die OUT-Signatur nicht ändern).
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
  group by p.id, p.display_name, p.region, p.bio, p.lat, p.lng
  having count(*) >= min_common
  order by common_interests desc, p.display_name
  limit max_results;
$$;

revoke all on function public.find_matches(int, text, int) from public;
grant execute on function public.find_matches(int, text, int) to authenticated;
