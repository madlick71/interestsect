-- Ergänzt "Schach" als allgemeine Interesse neben dem spezifischen
-- "Vereinsschach" (Gelegenheitsspieler sollen Schach ebenfalls finden).
-- Idempotent: mehrfaches Ausführen ist sicher.

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, 'schach', 'Schach', array['brettspiel', 'strategie', 'schachspiel']
from public.interest_categories c
where c.slug = 'spiele-gesellschaft'
on conflict (slug) do nothing;
