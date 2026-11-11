-- Kategorien alphabetisch nach name_de anordnen (sort_order 1-13)
-- Idempotent: update nur bei abweichender Sortierung.

update public.interest_categories c
set sort_order = v.neu
from (values
  ('bildung-wissenschaft',      1),
  ('gesellschaft-engagement',   2),
  ('handwerk-making',           3),
  ('kochen-genuss',             4),
  ('kunst-kreativ',             5),
  ('musik-klang',               6),
  ('musikrichtungen',           7),
  ('outdoor-natur',             8),
  ('sammeln-kurioses',          9),
  ('spiele-gesellschaft',      10),
  ('sport-bewegung',           11),
  ('sprachen-kultur',          12),
  ('technik-digital',          13)
) as v(slug, neu)
where c.slug = v.slug
  and c.sort_order is distinct from v.neu;
