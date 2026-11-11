-- interestsect: Musikrichtungen als eigene Kategorie (Hören & Fandom)
--
-- Quelle: Wikipedia "List of music genres and styles" (EN, via Wikidata
-- Q843744; in 25+ Sprachen gepflegt). Die Wikipedia-Liste ist extrem tief
-- (Rawstyle, Drift Phonk, Nortec ...); hier kuratiert auf ~60 Richtungen
-- in Granularität, die im deutschsprachigen Raum als Hör-/Fandom-Identität
-- gelebt werden. bewusst getrennt von "musik-klang" (aktives Musizieren).
--
-- Zusätzlich übernimmt diese Migration die per Table Editor angelegten
-- Einträge (Hardware-/Software-/Vintage-Synthesizer, Stratocaster,
-- Telecaster, Jazz) ins Repo, damit der Katalog aus den Migrationen
-- vollständig rekonstruierbar bleibt.
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interest_categories (slug, name_de, name_en, sort_order) values
  ('musikrichtungen', 'Musikrichtungen', 'Music Genres', 13)
on conflict (slug) do nothing;

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- Klassik & Jazz
  ('musikrichtungen','klassik','Klassik',array['orchester','komponist']),
  ('musikrichtungen','alte-musik','Alte Musik (Renaissance & Barock)',array['barock','renaissance']),
  ('musikrichtungen','neue-musik','Neue Musik (zeitgenössisch)',array['moderne','ensemble']),
  ('musikrichtungen','jazz','Jazz',array['swing','standards']),
  ('musikrichtungen','blues','Blues',array['delta','gitarre']),
  ('musikrichtungen','gospel','Gospel',array['chor','spiritual']),
  ('musikrichtungen','soul','Soul & Motown',array['motown','gesang']),
  ('musikrichtungen','funk','Funk',array['groove','bass']),
  ('musikrichtungen','rnb','R&B',array['rnb','beats']),

  -- Rock & Metal
  ('musikrichtungen','rock-klassiker','Rock (Klassiker)',array['classic rock','gitarren']),
  ('musikrichtungen','metal','Metal',array['heavy','riffs']),
  ('musikrichtungen','power-metal','Power Metal',array['episch','fantasy']),
  ('musikrichtungen','metalcore','Metalcore',array['breakdown','melodisch']),
  ('musikrichtungen','death-black-metal','Death & Black Metal',array['growls','blastbeats']),
  ('musikrichtungen','ndh','Neue Deutsche Härte',array['industrial','deutsch']),
  ('musikrichtungen','punk','Punk',array['pogo','diy']),
  ('musikrichtungen','pop-punk','Pop-Punk & Emo',array['powerchords','jugend']),
  ('musikrichtungen','grunge','Grunge',array['seattle','90er']),
  ('musikrichtungen','indie-alternative','Indie & Alternative',array['gitarrenpop','buehnen']),
  ('musikrichtungen','prog-rock','Progressive Rock',array['kunstrock','episch']),

  -- Elektronische Musik
  ('musikrichtungen','techno','Techno',array['clubs','rave']),
  ('musikrichtungen','house','House',array['dancefloor','groove']),
  ('musikrichtungen','trance','Trance',array['uplifting','melodisch']),
  ('musikrichtungen','hardstyle','Hardstyle',array['reverse bass','festivals']),
  ('musikrichtungen','gabber','Gabber & Happy Hardcore',array['rotterdam','schnell']),
  ('musikrichtungen','drum-and-bass','Drum & Bass / Jungle',array['breakbeat','liquid']),
  ('musikrichtungen','dubstep','Dubstep',array['bass','wobble']),
  ('musikrichtungen','idm','IDM & Electronica',array['experimental','glitch']),
  ('musikrichtungen','ambient','Ambient',array['klanglandschaft','ruhig']),
  ('musikrichtungen','chillout','Chillout & Downtempo',array['lounge','entspannt']),
  ('musikrichtungen','lofi','Lo-fi Beats',array['chillen','studieren']),
  ('musikrichtungen','eurodance','Eurodance & 90er-Dance',array['90er','dancefloor']),
  ('musikrichtungen','disco','Disco',array['70er','glitzer']),
  ('musikrichtungen','synth-pop','Synth-Pop & Electropop',array['synthesizer','pop']),
  ('musikrichtungen','synthwave','Synthwave & Retrowave',array['80er','neon']),

  -- Deutschsprachige Spezialitäten
  ('musikrichtungen','ndw','Neue Deutsche Welle',array['ndw','80er']),
  ('musikrichtungen','krautrock','Krautrock & Kosmische Musik',array['berliner schule','synthesizer']),
  ('musikrichtungen','gothic-darkwave','Gothic & Dark Wave',array['schwarze szene','80er']),
  ('musikrichtungen','industrial-ebm','Industrial & EBM',array['maschinen','ebm']),
  ('musikrichtungen','schlager','Schlager',array['stimmung','party']),
  ('musikrichtungen','volksmusik','Volksmusik & Alpenländisches',array['alpenlaendisch','volkstuemlich']),

  -- Hip-Hop & Urban
  ('musikrichtungen','hip-hop','Hip-Hop & Rap',array['boom bap','rap']),
  ('musikrichtungen','deutschrap','Deutschrap',array['deutsche texte','rap']),
  ('musikrichtungen','trap','Trap',array['808','hi-hats']),
  ('musikrichtungen','drill','Drill & Grime',array['uk','street']),
  ('musikrichtungen','reggae-dancehall','Reggae & Dancehall',array['dub','skank']),
  ('musikrichtungen','ska','Ska',array['offbeat','two tone']),
  ('musikrichtungen','afrobeats','Afrobeats',array['westafrika','tanz']),
  ('musikrichtungen','latin-reggaeton','Latin & Reggaeton',array['dembow','spanisch']),

  -- Folk, Weltmusik & Pop
  ('musikrichtungen','folk','Folk & Singer-Songwriter',array['akustik','lieder']),
  ('musikrichtungen','country','Country',array['western','fiddle']),
  ('musikrichtungen','irish-folk','Irish Folk',array['fiddle','pub']),
  ('musikrichtungen','klezmer-balkan','Klezmer & Balkan',array['jiddisch','brass']),
  ('musikrichtungen','arabesk-tuerkisch','Arabesk & Türkische Musik',array['tuerkisch','baglama']),
  ('musikrichtungen','flamenco','Flamenco',array['spanien','gitarre']),
  ('musikrichtungen','k-pop','K-Pop',array['korea','fandom']),
  ('musikrichtungen','j-pop-anime','J-Pop & Anime-Soundtracks',array['anime','opening']),
  ('musikrichtungen','bossa-nova','Bossa Nova & Brasilianisches',array['samba','brasilien']),
  ('musikrichtungen','pop','Pop',array['charts','melodien']),
  ('musikrichtungen','swing','Swing & Electro Swing',array['electro swing','30er']),
  ('musikrichtungen','filmmusik','Filmmusik & Soundtracks',array['score','soundtrack']),

  -- Per Table Editor angelegte Einträge (musik-klang) → im Repo festschreiben
  ('musik-klang','hardware-synthesizer','Synthesizer (Hardware)',array['analog','modular']),
  ('musik-klang','synthesizer-software','Synthesizer (Software)',array['vst','plugin']),
  ('musik-klang','synthesizer-vintage','Synthesizer (Vintage)',array['retro','analog']),
  ('musik-klang','stratocaster','Stratocaster',array['e-gitarre','fender']),
  ('musik-klang','telecaster','Telecaster',array['e-gitarre','fender'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;

-- "Jazz" wurde per Table Editor in musik-klang angelegt; als Musikrichtung
-- gehört es in die neue Kategorie (Musizieren deckt jazz-improvisation ab).
update public.interests i
set category_id = c.id
from public.interest_categories c
where c.slug = 'musikrichtungen'
  and i.slug = 'jazz'
  and i.category_id <> c.id;
