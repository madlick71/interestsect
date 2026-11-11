-- interestsect: Reddit-Pipeline Batch 2 (32 kuratierte Einträge)
--
-- Kuratiert aus den tiefen Rängen der Top-2500-Subreddit-Liste
-- (umbrae/reddit-top-2.5-million, öffentlich). Größte Lücken dieses
-- Durchlaufs: Motorsport, Elternschaft/Erziehung, ASMR, Nassrasur,
-- Kryptowährungen, Informatik/Ingenieurwesen, Graffiti & Street Art,
-- Innenarchitektur, Nageldesign, Everyday Carry, Mashups,
-- Aufbausimulationen, Paranormales.
--
-- Idempotent (ON CONFLICT DO NOTHING).

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- Motorsport & Kampfsport
  ('sport-bewegung','formel-1','Formel 1',array['grand prix','boxenstop']),
  ('sport-bewegung','motorsport-dtm-rallye','Motorsport (DTM & Rallye)',array['rallye','strecke']),
  ('sport-bewegung','mma','MMA & Kampfsport',array['ufc','grappling']),

  -- Wissen, Technik & Wirtschaft
  ('bildung-wissenschaft','kryptowaehrungen','Kryptowährungen & Bitcoin',array['btc','wallet']),
  ('bildung-wissenschaft','informatik','Informatik',array['algorithmen','rechnen']),
  ('bildung-wissenschaft','selbststaendigkeit-startups','Selbstständigkeit & Startups',array['gründen','geschäftsmodell']),
  ('bildung-wissenschaft','zitate-aphorismen','Zitate & Aphorismen',array['sprüche','sammlung']),
  ('bildung-wissenschaft','paedagogik-bildung','Pädagogik & Bildungsthemen',array['lernen','schule']),
  ('bildung-wissenschaft','was-waere-wenn-geschichte','Was-wäre-wenn-Geschichte',array['kontrafaktisch','szenarien']),
  ('technik-digital','systemadministration','Systemadministration',array['server','admin']),
  ('technik-digital','energiewende-technik','Energiewende & Energietechnik',array['strom','speicher']),
  ('technik-digital','ingenieurwesen','Ingenieurwesen & Konstruktion',array['technik','bauweise']),
  ('technik-digital','autoliebhaberei-tuning','Autoliebhaberei & Tuning',array['ps','motoren']),
  ('technik-digital','edc','Everyday Carry (EDC)',array['taschenmesser','gear']),

  -- Körper, Pflege & Wohlbefinden
  ('medizin-gesundheit','asmr','ASMR',array['tingeln','flüstern']),
  ('medizin-gesundheit','nassrasur','Nassrasur & Safety Razor',array['rasierhobel','pinsel']),
  ('medizin-gesundheit','soziale-kompetenzen','Soziale Kompetenzen & Smalltalk',array['gespräche','sicherheit']),
  ('medizin-gesundheit','fitness-ernaehrung','Fitness-Ernährung',array['makros','mahlzeiten']),
  ('medizin-gesundheit','frisuren-haare','Frisuren & Haare',array['schnitt','färben']),

  -- Küche
  ('kochen-genuss','guenstig-kochen','Günstig kochen',array['budget','resteverwertung']),
  ('kochen-genuss','paleo-ernaehrung','Paleo & Steinzeiternährung',array['urzeit','ohne getreide']),

  -- Kreativität & Wohnen
  ('kunst-kreativ','graffiti-streetart','Graffiti & Street Art',array['walls','sprühdosen']),
  ('kunst-kreativ','nageldesign','Nageldesign',array['gelnägel','lackieren']),
  ('bau-renovierung','einrichten-innenarchitektur','Einrichten & Innenarchitektur',array['möbel','raumkonzept']),

  -- Spiele, Musik, Film & Kurioses
  ('spiele-gesellschaft','aufbau-simulationsspiele','Aufbau- & Simulationsspiele',array['anno','wirtschaftssim']),
  ('musik-klang','mashups-remixes','Mashups & Remixes',array['bootleg','blend']),
  ('filmkunst','cyberpunk','Cyberpunk',array['blade runner','dystopie']),
  ('sprachen-kultur','south-park','South Park',array['cartman','kenny']),
  ('sammeln-kurioses','paranormales-geisterjagd','Paranormales & Geisterjagd',array['spuk','emf']),

  -- Gesellschaft
  ('gesellschaft-engagement','elternschaft-erziehung','Elternschaft & Erziehung',array['kinder','familie'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
