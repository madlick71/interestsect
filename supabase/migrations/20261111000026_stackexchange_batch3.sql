-- interestsect: Stack-Exchange-Pipeline Batch 3 (10 kuratierte Einträge)
--
-- Quelle: öffentliche Stack-Exchange-API (Tags nach Popularität, Sites:
-- gardening, photo, bicycles, homebrew, music, gaming, fitness, travel,
-- diy, outdoors), anonym abrufbar, gegen den Katalog gedifft und manuell
-- kuratiert. Neue Lücken: Rasenpflege, Kamera-Systeme, Schaltgruppen,
-- Kegs, Harmonielehre, Spiel-Mods, Cardio, Flugreisen.
--
-- Idempotent (ON CONFLICT DO NOTHING).

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  ('outdoor-natur','rasenpflege','Rasenpflege & Rasen',array['mähen','unkraut']),
  ('outdoor-natur','blumengarten','Blumengarten & Beete',array['stauden','sommerblumen']),
  ('kunst-kreativ','canon-system','Canon-Kamerasystem',array['eos','rf']),
  ('kunst-kreativ','nikon-system','Nikon-Kamerasystem',array['z','f-mount']),
  ('kunst-kreativ','sony-alpha','Sony Alpha',array['e-mount','fe']),
  ('handwerk-making','fahrrad-komponenten','Fahrradkomponenten & Schaltgruppen',array['shimano','sram']),
  ('kochen-genuss','kegs-zapfanlagen','Kegs & Zapfanlagen',array['fass','hahn']),
  ('musik-klang','harmonielehre-akkorde','Harmonielehre & Akkorde',array['progressionen','stufen']),
  ('spiele-gesellschaft','mods-modding','Mods & Modding',array['mods','workshop']),
  ('sport-bewegung','cardio-ausdauer','Cardio & Ausdauertraining',array['puls','laufen']),
  ('reiseziele','flugreisen-airports','Flugreisen & Airports',array['vielflieger','lounges'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
