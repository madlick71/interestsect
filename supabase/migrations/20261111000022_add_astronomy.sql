-- Ergänzt "Astronomie" als allgemeine Interesse neben den spezifischen
-- Einträgen (Deep Sky, Veränderliche Sterne, Sternbeobachtung).
-- Idempotent: mehrfaches Ausführen ist sicher.

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, 'astronomie', 'Astronomie', array['sterne', 'teleskop', 'himmel', 'weltraum']
from public.interest_categories c
where c.slug = 'bildung-wissenschaft'
on conflict (slug) do nothing;
