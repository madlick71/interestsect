-- interestsect: Serverseitige Interessen-Suche (Lazy Loading)
--
-- Der Katalog ist auf >22.000 Einträge gewachsen; der Web-Client lädt ihn
-- nicht mehr vollständig, sondern sucht serverseitig und blättert pro
-- Kategorie. Diese Funktionen bilden die bisherige Client-Normalform ab
-- (kleingeschrieben, Umlaute transliteriert), damit "kraeuter" weiterhin
-- "Kräuter" findet:
--   interest_norm()            — Normalform eines Textes
--   search_interests()         — Suche über name_de/slug/keywords mit
--                                Limit/Offset (max. 200 pro Aufruf)
--   interest_category_counts() — Zeilenzahl pro Kategorie für die Header
--
-- Funktionen laufen als Invoker; das SELECT-RLS auf public.interests
-- (nur authenticated) bleibt wirksam. Ausführungsrechte nur für
-- authenticated — anon ruft nichts davon auf.

create or replace function public.interest_norm(s text)
returns text
language sql
immutable
as $$
  select replace(replace(replace(replace(lower(s),
    'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue'), 'ß', 'ss')
$$;

create or replace function public.search_interests(
  q text,
  cat uuid default null,
  lmt int default 100,
  offs int default 0
)
returns table (id uuid, category_id uuid, slug text, name_de text, keywords text[])
language sql
stable
as $$
  select i.id, i.category_id, i.slug, i.name_de, i.keywords
  from public.interests i
  where (cat is null or i.category_id = cat)
    and (
      nullif(trim(q), '') is null
      or public.interest_norm(i.name_de) like '%' || public.interest_norm(q) || '%'
      or public.interest_norm(i.slug)      like '%' || public.interest_norm(q) || '%'
      or exists (
        select 1
        from unnest(i.keywords) k
        where public.interest_norm(k) like '%' || public.interest_norm(q) || '%'
      )
    )
  order by i.name_de
  limit least(greatest(lmt, 1), 200)
  offset greatest(offs, 0)
$$;

create or replace function public.interest_category_counts()
returns table (category_id uuid, n bigint)
language sql
stable
as $$
  select i.category_id, count(*)::bigint
  from public.interests i
  group by i.category_id
$$;

revoke execute on function public.interest_norm(text) from public, anon;
revoke execute on function public.search_interests(text, uuid, int, int) from public, anon;
revoke execute on function public.interest_category_counts() from public, anon;
grant execute on function public.interest_norm(text) to authenticated;
grant execute on function public.search_interests(text, uuid, int, int) to authenticated;
grant execute on function public.interest_category_counts() to authenticated;
