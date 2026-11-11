-- Kategorie "Musik & Klang" umbenennen in "Musik machen"
-- (schärfert die Abgrenzung zur Kategorie "Musikrichtungen": aktives
-- Musizieren vs. Hören/Fandom). Slug bleibt unverändert.
-- Idempotent: mehrfaches Ausführen ist sicher.

update public.interest_categories
set name_de = 'Musik machen',
    name_en = 'Making Music'
where slug = 'musik-klang'
  and (name_de <> 'Musik machen' or name_en <> 'Making Music');
