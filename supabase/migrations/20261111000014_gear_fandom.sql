-- interestsect: Musik-Equipment (Gear) und Musiker & Bands (Fandom)
--
-- Anlass: Musiker-Perspektive — Verstärker & Instrumenten-Modelle
-- (Fender-Amps, Gibson Les Paul ...) und Fan-Interessen an Musikern
-- (z. B. Albert Lee) fehlten. Bestehende Gear-Einträge (Stratocaster,
-- Telecaster, Synthesizer, Modular) werden aus "Musik machen" hierher
-- verschoben — dort bleibt das aktive Musizieren.
--
-- Kuratiert; Namen und Keywords beziehen sich auf das Werk/das Gerät.
--
-- Idempotent: Inserts ON CONFLICT DO NOTHING, Updates mit Bedingung.

insert into public.interest_categories (slug, name_de, name_en, sort_order) values
  ('musik-equipment', 'Musik-Equipment', 'Music Gear',                 8),
  ('musiker-bands',   'Musiker & Bands', 'Musicians & Bands',          9)
on conflict (slug) do nothing;

-- Alphabetische Gesamtsortierung (18 Kategorien)
update public.interest_categories c
set sort_order = v.neu
from (values
  ('bildung-wissenschaft',      1),
  ('filmkunst',                 2),
  ('gesellschaft-engagement',   3),
  ('handwerk-making',           4),
  ('kochen-genuss',             5),
  ('kunst-kreativ',             6),
  ('medizin-gesundheit',        7),
  ('musik-equipment',           8),
  ('musiker-bands',             9),
  ('musik-klang',              10),
  ('musikrichtungen',          11),
  ('outdoor-natur',            12),
  ('religion-spiritualitaet',  13),
  ('sammeln-kurioses',         14),
  ('spiele-gesellschaft',      15),
  ('sport-bewegung',           16),
  ('sprachen-kultur',          17),
  ('technik-digital',          18)
) as v(slug, neu)
where c.slug = v.slug
  and c.sort_order is distinct from v.neu;

-- Gear-Einträge aus "Musik machen" richtig einordnen
update public.interests i
set category_id = c.id
from public.interest_categories c
where c.slug = 'musik-equipment'
  and i.slug in ('stratocaster','telecaster','hardware-synthesizer',
                 'synthesizer-software','synthesizer-vintage','modular-synth')
  and i.category_id <> c.id;

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- ============================================================
  -- Musik-Equipment
  -- ============================================================
  ('musik-equipment','fender-amps','Fender-Verstärker',array['twin reverb','deluxe']),
  ('musik-equipment','marshall','Marshall-Verstärker',array['plexi','jcm']),
  ('musik-equipment','vox-ac30','Vox AC30',array['top boost','chime']),
  ('musik-equipment','orange-amps','Orange-Verstärker',array['britisch','gain']),
  ('musik-equipment','bassamps','Bassamps & -boxen',array['4x10','ampeg']),
  ('musik-equipment','gibson-les-paul','Gibson Les Paul',array['sunburst','paf']),
  ('musik-equipment','gibson-sg','Gibson SG',array['teufelshörner','rock']),
  ('musik-equipment','gibson-es335','Gibson ES-335',array['halbresonanz','jazz']),
  ('musik-equipment','gretsch','Gretsch-Gitarren',array['hollowbody','filtertron']),
  ('musik-equipment','rickenbacker','Rickenbacker',array['jangle','beat']),
  ('musik-equipment','prs','PRS-Gitarren',array['vögel','modern']),
  ('musik-equipment','martin-gitarren','Martin & Akustikgitarren',array['dreadnought','massivholz']),
  ('musik-equipment','pedal-steel','Pedal-Steel-Gitarre',array['country','hebel']),
  ('musik-equipment','effekt-pedale','Effekt-Pedale',array['overdrive','delay']),
  ('musik-equipment','boutique-pedale','Boutique-Pedale',array['handgebaut','small batch']),
  ('musik-equipment','pedalboard-aufbau','Pedalboard planen & aufbauen',array['kabel','loops']),
  ('musik-equipment','amp-sims','Amp-Simulationen & Modeler',array['kemper','helix']),
  ('musik-equipment','moog','Moog-Synthesizer',array['minimoog','ladder']),
  ('musik-equipment','roland-vintage-synths','Roland Vintage-Synths',array['juno','jupiter']),
  ('musik-equipment','mischpulte','Mischpulte',array['kanäle','fader']),
  ('musik-equipment','studiomikrofone','Studiomikrofone',array['kondensator','niere']),
  ('musik-equipment','abhoermonitore','Abhörumonitore',array['nearfield','raum']),
  ('musik-equipment','plattenspieler-tonabnehmer','Plattenspieler & Tonabnehmer',array['riemen','mm']),
  ('musik-equipment','drum-tuning','Drum-Kits & Tuning',array['felle','kessel']),
  ('musik-equipment','becken-cymbals','Becken & Cymbals',array['zildjian','paiste']),
  ('musik-equipment','e-drums','E-Drumsets',array['mesh','module']),
  ('musik-equipment','homestudio-einrichten','Homestudio einrichten',array['akustik','platten']),

  -- ============================================================
  -- Musiker & Bands (Fandom)
  -- ============================================================
  ('musiker-bands','albert-lee','Albert Lee',array['country','telecaster']),
  ('musiker-bands','chet-atkins','Chet Atkins',array['fingerstyle','nashville']),
  ('musiker-bands','django-reinhardt','Django Reinhardt',array['manouche','quintett']),
  ('musiker-bands','jimi-hendrix','Jimi Hendrix',array['experience','wah']),
  ('musiker-bands','eric-clapton','Eric Clapton',array['slowhand','bluesbreaker']),
  ('musiker-bands','jeff-beck','Jeff Beck',array['strat','wired']),
  ('musiker-bands','jimmy-page','Jimmy Page',array['les paul','riff']),
  ('musiker-bands','mark-knopfler','Mark Knopfler',array['fingerpicking','dire straits']),
  ('musiker-bands','david-gilmour','David Gilmour',array['pink floyd','sustain']),
  ('musiker-bands','bb-king','B.B. King',array['lucille','vibrato']),
  ('musiker-bands','stevie-ray-vaughan','Stevie Ray Vaughan',array['srv','texas']),
  ('musiker-bands','gary-moore','Gary Moore',array['parisienne','blues']),
  ('musiker-bands','carlos-santana','Carlos Santana',array['europa','latin']),
  ('musiker-bands','van-halen','Van Halen',array['tapping','brown']),
  ('musiker-bands','ry-cooder','Ry Cooder',array['slide','film']),
  ('musiker-bands','pat-metheny','Pat Metheny',array['gitarrensynth','group']),
  ('musiker-bands','frank-zappa','Frank Zappa',array['mothers','ironie']),
  ('musiker-bands','miles-davis','Miles Davis',array['kind of blue','trompete']),
  ('musiker-bands','john-coltrane','John Coltrane',array['a love supreme','sheets']),
  ('musiker-bands','thelonious-monk','Thelonious Monk',array['midnight','winklig']),
  ('musiker-bands','keith-jarrett','Keith Jarrett',array['köln','improvisation']),
  ('musiker-bands','herbie-hancock','Herbie Hancock',array['headhunters','rhodes']),
  ('musiker-bands','jaco-pastorius','Jaco Pastorius',array['fretless','weather']),
  ('musiker-bands','bach','Johann Sebastian Bach',array['kantor','fuge']),
  ('musiker-bands','mozart','Wolfgang Amadeus Mozart',array['zauberflöte','wien']),
  ('musiker-bands','beethoven','Ludwig van Beethoven',array['sinfonien','klavier']),
  ('musiker-bands','chopin','Frédéric Chopin',array['nocturne','etüde']),
  ('musiker-bands','wagner','Richard Wagner',array['ring','bayreuth']),
  ('musiker-bands','frank-sinatra','Frank Sinatra',array['swing','ol blue']),
  ('musiker-bands','ella-fitzgerald','Ella Fitzgerald',array['scat','songbook']),
  ('musiker-bands','nina-simone','Nina Simone',array['gefühl','songs']),
  ('musiker-bands','bob-dylan','Bob Dylan',array['songwriter','folk']),
  ('musiker-bands','neil-young','Neil Young',array['rust','heart of gold']),
  ('musiker-bands','johnny-cash','Johnny Cash',array['sun','black']),
  ('musiker-bands','prince','Prince',array['purple','virtuos']),
  ('musiker-bands','david-bowie','David Bowie',array['ziggy','verwandlung']),
  ('musiker-bands','beatles','The Beatles',array['liverpool','fab four']),
  ('musiker-bands','rolling-stones','Rolling Stones',array['keith','riff']),
  ('musiker-bands','pink-floyd','Pink Floyd',array['dark side','sound']),
  ('musiker-bands','led-zeppelin','Led Zeppelin',array['bonham','riff']),
  ('musiker-bands','queen','Queen',array['freddie','bohemian']),
  ('musiker-bands','nirvana','Nirvana',array['kurt','grunge']),
  ('musiker-bands','radiohead','Radiohead',array['ok computer','kreativ']),
  ('musiker-bands','kraftwerk','Kraftwerk',array['düsseldorf','man machine']),
  ('musiker-bands','can','CAN',array['krautrock','groove'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
