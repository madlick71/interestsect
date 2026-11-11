-- interestsect: Musiker & Bands auf 200 Einträge erweitern (+155)
--
-- Verteilung über Genre-Lager mit Fokus auf deutschsprachige Fangemeinden:
-- Classic Rock, Hardrock/Metal, Punk & Post-Punk, Deutschrock/NDW,
-- Hip-Hop, Electronic, Pop & Soul, Blues & Guitar Heroes, Jazz,
-- Klassik (Komponisten & Interpreten), Country/Bluegrass, Reggae, Welt.
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- Classic Rock & Bands
  ('musiker-bands','the-who','The Who',array['pete','my generation']),
  ('musiker-bands','the-doors','The Doors',array['morrison','lizard']),
  ('musiker-bands','creedence','Creedence Clearwater Revival',array['swamp','bayou']),
  ('musiker-bands','the-eagles','Eagles',array['hotel california','harmonien']),
  ('musiker-bands','fleetwood-mac','Fleetwood Mac',array['rumours','nicks']),
  ('musiker-bands','genesis','Genesis',array['gabriel','collins']),
  ('musiker-bands','yes','Yes',array['prog','roundabout']),
  ('musiker-bands','king-crimson','King Crimson',array['court','fripp']),
  ('musiker-bands','dire-straits','Dire Straits',array['sultans','knopfler']),
  ('musiker-bands','u2','U2',array['bono','joshua']),
  ('musiker-bands','red-hot-chili-peppers','Red Hot Chili Peppers',array['flea','funky']),
  ('musiker-bands','foo-fighters','Foo Fighters',array['grohl','everlong']),
  ('musiker-bands','soundgarden','Soundgarden',array['cornell','superunknown']),
  ('musiker-bands','pearl-jam','Pearl Jam',array['vedder','ten']),
  ('musiker-bands','pixies','Pixies',array['black','quietloud']),
  ('musiker-bands','the-smiths','The Smiths',array['morrisey','jangle']),
  ('musiker-bands','the-cure','The Cure',array['smith','disintegration']),
  ('musiker-bands','joy-division','Joy Division',array['curtis','unknown']),
  ('musiker-bands','the-clash','The Clash',array['london','punk']),
  ('musiker-bands','sex-pistols','Sex Pistols',array['rotten','anarchy']),
  ('musiker-bands','ramones','Ramones',array['blitzkrieg','hey ho']),
  ('musiker-bands','talking-heads','Talking Heads',array['byrne','psycho']),
  ('musiker-bands','lou-reed','Lou Reed',array['berlin','velvet']),
  ('musiker-bands','velvet-underground','The Velvet Underground',array['nico','warhol']),
  ('musiker-bands','leonard-cohen','Leonard Cohen',array['halleluja','dichter']),

  -- Hardrock & Metal
  ('musiker-bands','deep-purple','Deep Purple',array['smoke','machine head']),
  ('musiker-bands','black-sabbath','Black Sabbath',array['paranoid','iommi']),
  ('musiker-bands','iron-maiden','Iron Maiden',array['eddie','bruce']),
  ('musiker-bands','judas-priest','Judas Priest',array['halford','metal']),
  ('musiker-bands','motorhead','Motörhead',array['lemmy','ace']),
  ('musiker-bands','metallica','Metallica',array['hetfield','puppets']),
  ('musiker-bands','slayer','Slayer',array['reign','thrash']),
  ('musiker-bands','system-of-a-down','System of a Down',array['toxicity','armenien']),
  ('musiker-bands','tool','Tool',array['lateralus','polyrhythm']),
  ('musiker-bands','opeth','Opeth',array['progressiv','death']),
  ('musiker-bands','rammstein','Rammstein',array['feuer','stadion']),
  ('musiker-bands','nine-inch-nails','Nine Inch Nails',array['reznor','industrial']),

  -- Modern Rock & Indie
  ('musiker-bands','arctic-monkeys','Arctic Monkeys',array['turner','am']),
  ('musiker-bands','the-strokes','The Strokes',array['casablancas','garage']),
  ('musiker-bands','linkin-park','Linkin Park',array['shinoda','hybrid']),
  ('musiker-bands','green-day','Green Day',array['armstrong','dookie']),
  ('musiker-bands','oasis','Oasis',array['gallagher','wonderwall']),
  ('musiker-bands','blur','Blur',array['albarn','parklife']),
  ('musiker-bands','smashing-pumpkins','The Smashing Pumpkins',array['corgan','siamese']),
  ('musiker-bands','gorillaz','Gorillaz',array['albarn','clint']),
  ('musiker-bands','the-white-stripes','The White Stripes',array['jack','seven nation']),

  -- Deutschrock, NDW & deutsche Ikonen
  ('musiker-bands','die-toten-hosen','Die Toten Hosen',array['campino','düsseldorf']),
  ('musiker-bands','die-aerzte','Die Ärzte',array['farin','belafarina']),
  ('musiker-bands','nena','Nena',array['luftballons','ndw']),
  ('musiker-bands','udo-lindenberg','Udo Lindenberg',array['panic','special']),
  ('musiker-bands','ton-stein-scherben','Ton Steine Scherben',array['rio','macht']),
  ('musiker-bands','rio-reiser','Rio Reiser',array['könig','solo']),
  ('musiker-bands','bap','BAP',array['kölsch','niedeckens']),
  ('musiker-bands','peter-maffay','Peter Maffay',array['drachen','tabaluga']),
  ('musiker-bands','nina-hagen','Nina Hagen',array['punk','bandits']),

  -- Hip-Hop
  ('musiker-bands','tupac','2Pac',array['shakur','westcoast']),
  ('musiker-bands','notorious-big','The Notorious B.I.G.',array['biggie','brooklyn']),
  ('musiker-bands','eminem','Eminem',array['slim','detroit']),
  ('musiker-bands','jay-z','JAY-Z',array['brooklyn','dynasty']),
  ('musiker-bands','kendrick-lamar','Kendrick Lamar',array['pimp','pulitzer']),
  ('musiker-bands','dr-dre','Dr. Dre',array['chronic','beats']),
  ('musiker-bands','snoop-dogg','Snoop Dogg',array['doggy','lbc']),
  ('musiker-bands','wu-tang-clan','Wu-Tang Clan',array['rza','shaolin']),
  ('musiker-bands','outkast','OutKast',array['andre','speakerboxx']),
  ('musiker-bands','public-enemy','Public Enemy',array['chuck','fight']),
  ('musiker-bands','fantastischen-vier','Die Fantastischen Vier',array['fanta','smudo']),

  -- Electronic
  ('musiker-bands','daft-punk','Daft Punk',array['homework','helmets']),
  ('musiker-bands','prodigy','The Prodigy',array['firestarter','rave']),
  ('musiker-bands','massive-attack','Massive Attack',array['trip hop','bristol']),
  ('musiker-bands','portishead','Portishead',array['beth','glory']),
  ('musiker-bands','bjoerk','Björk',array['island','swan']),
  ('musiker-bands','aphex-twin','Aphex Twin',array['windowlicker','idm']),
  ('musiker-bands','depeche-mode','Depeche Mode',array['dave','violator']),
  ('musiker-bands','new-order','New Order',array['blue monday','synth']),
  ('musiker-bands','chemical-brothers','The Chemical Brothers',array['dig','block']),
  ('musiker-bands','paul-kalkbrenner','Paul Kalkbrenner',array['berlin','sky']),
  ('musiker-bands','sven-vaeth','Sven Väth',array['cocoon','ptt']),

  -- Pop & Soul
  ('musiker-bands','michael-jackson','Michael Jackson',array['moonwalk','thriller']),
  ('musiker-bands','madonna','Madonna',array['material','pop']),
  ('musiker-bands','tina-turner','Tina Turner',array['simply','nutbush']),
  ('musiker-bands','james-brown','James Brown',array['godfather','funky']),
  ('musiker-bands','aretha-franklin','Aretha Franklin',array['respect','queen']),
  ('musiker-bands','stevie-wonder','Stevie Wonder',array['sunshine','keys']),
  ('musiker-bands','otis-redding','Otis Redding',array['dock','soul']),
  ('musiker-bands','sam-cooke','Sam Cooke',array['change','gospel']),
  ('musiker-bands','marvin-gaye','Marvin Gaye',array['grape','tamla']),
  ('musiker-bands','curtis-mayfield','Curtis Mayfield',array['superfly','move']),
  ('musiker-bands','earth-wind-fire','Earth, Wind & Fire',array['september','horns']),
  ('musiker-bands','whitney-houston','Whitney Houston',array['houston','voice']),
  ('musiker-bands','elton-john','Elton John',array['rocket','piano']),
  ('musiker-bands','adele','Adele',array['hello','balladen']),
  ('musiker-bands','taylor-swift','Taylor Swift',array['eras','songwriting']),
  ('musiker-bands','billie-eilish','Billie Eilish',array['bad','whisper']),
  ('musiker-bands','beyonce','Beyoncé',array['homecoming','destiny']),
  ('musiker-bands','amy-winehouse','Amy Winehouse',array['back','soul']),
  ('musiker-bands','coldplay','Coldplay',array['chris','yellow']),
  ('musiker-bands','abba','ABBA',array['mamma','schwedisch']),
  ('musiker-bands','helene-fischer','Helene Fischer',array['schlager','atmen']),

  -- Singer-Songwriter & Folk
  ('musiker-bands','joni-mitchell','Joni Mitchell',array['blue','saiten']),
  ('musiker-bands','nick-drake','Nick Drake',array['pink','leise']),
  ('musiker-bands','elliott-smith','Elliott Smith',array['either','leise']),
  ('musiker-bands','jeff-buckley','Jeff Buckley',array['grace','halleluja']),
  ('musiker-bands','simon-and-garfunkel','Simon & Garfunkel',array['silence','bridge']),

  -- Blues & Guitar Heroes
  ('musiker-bands','robert-johnson','Robert Johnson',array['kreuz','delta']),
  ('musiker-bands','muddy-waters','Muddy Waters',array['chicago','hoochie']),
  ('musiker-bands','howlin-wolf','Howlin Wolf',array['moan','chicago']),
  ('musiker-bands','buddy-guy','Buddy Guy',array['strat','damn']),
  ('musiker-bands','freddie-king','Freddie King',array['hide','guitar']),
  ('musiker-bands','peter-green','Peter Green',array['albatross','fleetwood']),
  ('musiker-bands','rory-gallagher','Rory Gallagher',array['irland','strat']),
  ('musiker-bands','jerry-reed','Jerry Reed',array['guitar','eastbound']),
  ('musiker-bands','ritchie-blackmore','Ritchie Blackmore',array['deep','rainbow']),
  ('musiker-bands','tony-iommi','Tony Iommi',array['riffs','sabbath']),
  ('musiker-bands','brian-may','Brian May',array['red special','queen']),
  ('musiker-bands','keith-richards','Keith Richards',array['open g','stones']),
  ('musiker-bands','wes-montgomery','Wes Montgomery',array['octaven','thumb']),
  ('musiker-bands','george-benson','George Benson',array['breezin','scat']),
  ('musiker-bands','al-di-meola','Al Di Meola',array['elegant','romantic']),
  ('musiker-bands','john-mclaughlin','John McLaughlin',array['mahavishnu','fusion']),
  ('musiker-bands','paco-de-lucia','Paco de Lucía',array['flamenco','festival']),

  -- Jazz
  ('musiker-bands','louis-armstrong','Louis Armstrong',array['satchmo','hello']),
  ('musiker-bands','duke-ellington','Duke Ellington',array['caravan','orchester']),
  ('musiker-bands','billie-holiday','Billie Holiday',array['day','swing']),
  ('musiker-bands','charlie-parker','Charlie Parker',array['bird','bebop']),
  ('musiker-bands','bill-evans','Bill Evans',array['waltz','trio']),
  ('musiker-bands','dave-brubeck','Dave Brubeck',array['take five','quartett']),
  ('musiker-bands','chet-baker','Chet Baker',array['my funny','trompete']),
  ('musiker-bands','weather-report','Weather Report',array['jaco','heavy']),
  ('musiker-bands','snarky-puppy','Snarky Puppy',array['fusion','band']),

  -- Klassik: Komponisten
  ('musiker-bands','johannes-brahms','Johannes Brahms',array['ungarische','requiem']),
  ('musiker-bands','franz-schubert','Franz Schubert',array['winterreise','lieder']),
  ('musiker-bands','joseph-haydn','Joseph Haydn',array['sinfonien','streichquartett']),
  ('musiker-bands','georg-friedrich-haendel','Georg Friedrich Händel',array['messias','wassermusik']),
  ('musiker-bands','antonio-vivaldi','Antonio Vivaldi',array['vier jahreszeiten','roter']),
  ('musiker-bands','claude-debussy','Claude Debussy',array['impressionismus','mond']),
  ('musiker-bands','maurice-ravel','Maurice Ravel',array['bolero','orchestrierung']),
  ('musiker-bands','igor-strawinski','Igor Strawinski',array['frühling','feuervogel']),
  ('musiker-bands','robert-schumann','Robert Schumann',array['dichterliebe','klavier']),
  ('musiker-bands','gustav-mahler','Gustav Mahler',array['sinfonien','lieder']),
  ('musiker-bands','tschaikowski','Pjotr Tschaikowski',array['schwanensee','pathétique']),
  ('musiker-bands','dvorak','Antonín Dvořák',array['neue welt','cello']),
  ('musiker-bands','erik-satie','Erik Satie',array['gymnopédie','minimal']),
  ('musiker-bands','rachmaninow','Sergei Rachmaninow',array['klavierkonzert','glocken']),

  -- Klassik: Interpreten
  ('musiker-bands','glenn-gould','Glenn Gould',array['goldberg','humming']),
  ('musiker-bands','martha-argerich','Martha Argerich',array['rasch','klavier']),
  ('musiker-bands','herbert-von-karajan','Herbert von Karajan',array['dirigent','berliner']),
  ('musiker-bands','yo-yo-ma','Yo-Yo Ma',array['cello','bach']),

  -- Country & Bluegrass
  ('musiker-bands','willie-nelson','Willie Nelson',array['on the road','outlaw']),
  ('musiker-bands','dolly-parton','Dolly Parton',array['jolene','9']),
  ('musiker-bands','hank-williams','Hank Williams',array['lonesome','honky']),
  ('musiker-bands','bill-monroe','Bill Monroe',array['vater','bluegrass']),
  ('musiker-bands','alison-krauss','Alison Krauss',array['union station','sopran']),

  -- Reggae & Welt
  ('musiker-bands','bob-marley','Bob Marley',array['wailer','rasta']),
  ('musiker-bands','peter-tosh','Peter Tosh',array['legalize','wailer']),
  ('musiker-bands','fela-kuti','Fela Kuti',array['afrobeat','lagos']),
  ('musiker-bands','astor-piazzolla','Astor Piazzolla',array['tango nuevo','bandoneon']),
  ('musiker-bands','ravi-shankar','Ravi Shankar',array['sitar','beatles'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
