-- interestsect: Reddit-Pipeline Batch 1 (43 kuratierte Einträge)
--
-- Quelle: umbrae/reddit-top-2.5-million (öffentliche Top-2500-Subreddit-
-- Liste mit Abonnentenzahlen), gematcht gegen den Katalog; die Lücken
-- wurden manuell kuratiert und übersetzt. Größte gefundenen Lücken:
-- Serien-/Film-Fandoms, Game-Fandoms, Finanzthemen, Körper/Stil,
-- Persönlichkeitsentwicklung, Bildbearbeitung/PC-Selbstbau.
--
-- Idempotent (ON CONFLICT DO NOTHING).

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- Serien- & Film-Fandoms
  ('sprachen-kultur','star-wars','Star Wars',array['skywalker','jedi']),
  ('sprachen-kultur','star-trek','Star Trek',array['enterprise','föderation']),
  ('sprachen-kultur','doctor-who','Doctor Who',array['tardis','gallifrey']),
  ('sprachen-kultur','harry-potter','Harry Potter',array['hogwarts','zauberei']),
  ('sprachen-kultur','herr-der-ringe','Der Herr der Ringe',array['mittelerde','tolkien']),
  ('sprachen-kultur','game-of-thrones','Game of Thrones',array['westeros','thron']),
  ('sprachen-kultur','breaking-bad','Breaking Bad',array['heisenberg','albuquerque']),
  ('sprachen-kultur','the-walking-dead','The Walking Dead',array['zombies','survival']),
  ('sprachen-kultur','marvel-fandom','Marvel & MCU',array['avengers','comics']),
  ('sprachen-kultur','dc-fandom','DC & Batman',array['gotham','joker']),
  ('sprachen-kultur','stranger-things','Stranger Things',array['hawkins','80er']),
  ('sprachen-kultur','simpsons','Die Simpsons',array['springfield','homer']),
  ('sprachen-kultur','futurama','Futurama',array['bender','weltraum']),
  ('sprachen-kultur','the-office','The Office (Fandom)',array['dunder','pam']),
  ('sprachen-kultur','sherlock-holmes-fandom','Sherlock Holmes',array['watson','baker street']),
  ('sprachen-kultur','rick-and-morty','Rick and Morty',array['portal','wubba']),

  -- Videospiel-Fandoms
  ('spiele-gesellschaft','league-of-legends','League of Legends',array['lol','moba']),
  ('spiele-gesellschaft','counter-strike','Counter-Strike',array['cs','shooter']),
  ('spiele-gesellschaft','fortnite','Fortnite',array['battle royale','skins']),
  ('spiele-gesellschaft','zelda','The Legend of Zelda',array['hyrule','link']),
  ('spiele-gesellschaft','pokemon-fandom','Pokémon-Fandom',array['kanto','pikachu']),
  ('spiele-gesellschaft','world-of-warcraft','World of Warcraft',array['azeroth','raid']),
  ('spiele-gesellschaft','elder-scrolls','The Elder Scrolls',array['skyrim','tamriel']),
  ('spiele-gesellschaft','final-fantasy','Final Fantasy',array['jrpg','chocobo']),
  ('spiele-gesellschaft','the-witcher','The Witcher',array['geralt','rivia']),
  ('spiele-gesellschaft','dota-2','Dota 2',array['moba','creeps']),

  -- Finanzen & bewusster Konsum
  ('bildung-wissenschaft','etf-sparplan','ETF-Sparpläne',array['index','sparen']),
  ('bildung-wissenschaft','aktien-fonds','Aktien & Fonds verstehen',array['dividende','depot']),
  ('bildung-wissenschaft','fire-finanzunabhaengigkeit','Finanzielle Unabhängigkeit (FIRE)',array['rente mit','sparrate']),
  ('bildung-wissenschaft','frugalismus','Frugalismus & sparsam leben',array['sparen','konsum']),
  ('bildung-wissenschaft','minimalismus','Minimalismus',array['ausmisten','weniger']),
  ('bildung-wissenschaft','schnaeppchen-jagen','Schnäppchen & Deals',array['angebote','rabatte']),
  ('bildung-wissenschaft','finanzbildung','Finanzbildung',array['haushalt','versicherungen']),

  -- Körper & Stil
  ('kunst-kreativ','taetowierungen','Tätowierungen & Motive',array['tattoo','stechen']),
  ('kunst-kreativ','mode-stil','Mode & eigener Stil',array['outfits','garderobe']),
  ('medizin-gesundheit','bartpflege','Bartpflege & Bärte',array['bartöl','trimmen']),
  ('medizin-gesundheit','abnehmen-gewicht','Abnehmen & Gewichtsmanagement',array['kalorien','umstellung']),

  -- Persönlichkeitsentwicklung
  ('medizin-gesundheit','klartraeume','Klarträume',array['luzid','traumbewusstsein']),
  ('medizin-gesundheit','persoenlichkeitsentwicklung','Persönlichkeitsentwicklung',array['wachstum','ziele']),
  ('medizin-gesundheit','habit-tracking','Gewohnheiten aufbauen',array['streaks','routine']),

  -- Technik-Alltag
  ('technik-digital','bildbearbeitung','Bildbearbeitung & Composing',array['photoshop','retusche']),
  ('technik-digital','pc-selbstbau','PC selbst zusammenbauen',array['hardware','kompatibilität']),
  ('technik-digital','lifehacks','Lifehacks',array['tricks','alltag'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
