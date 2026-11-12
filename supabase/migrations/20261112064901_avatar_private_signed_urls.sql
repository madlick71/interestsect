-- Profilbilder: Bucket auf privat stellen — Bilder sind nur noch über
-- kurzlebige Signed URLs (Server signiert den Storage-Pfad) abrufbar,
-- nicht mehr über öffentliche, teilbare URLs.
--
-- profiles.avatar_url enthält damit den Storage-Pfad (<user-id>/avatar.jpg)
-- statt der vollen Public-URL; signiert wird beim Rendern (dynamische
-- Seiten), expire 1 h. Lesen bleibt allen angemeldeten Nutzern erlaubt
-- (Policy „avatars: lesen für angemeldete" aus 20261112060941) — nötig,
-- damit Treffer-Listen/Karten fremde Avatare signieren dürfen.

update storage.buckets
  set public = false
  where id = 'avatars';

-- Defensive Umstellung evtl. bereits gespeicherter Public-URLs auf Pfade:
-- https://<ref>.supabase.co/storage/v1/object/public/avatars/<uid>/avatar.jpg?v=…
--   → <uid>/avatar.jpg
update public.profiles
set avatar_url = regexp_replace(
      split_part(avatar_url, '?', 1),
      '^.*object/public/avatars/',
      ''
    )
where avatar_url like '%/object/public/avatars/%';
