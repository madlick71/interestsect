-- interestsect: Filmkunst als eigene Kategorie (Autorenfilm & Cinephilie)
--
-- Quellen (recherchiert 2026-11):
--   * Wikipedia-Listen "List of film directors" / Autorenfilm-Artikel,
--     Sight & Sound-Bestenlisten-Umfeld (BFI) als Bekanntheitsreferenz
--   * Filmgeschichtliche Bewegungen (Nouvelle Vague, Neorealismus,
--     Deutscher Expressionismus, New Hollywood, Dogma 95, Film noir)
-- Kuratiert als Fan-/Kenner-Interessen; konfessionell neutrale, auf
-- das Werk bezogene Keywords.
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interest_categories (slug, name_de, name_en, sort_order) values
  ('filmkunst', 'Filmkunst', 'Film Art', 2)
on conflict (slug) do nothing;

-- Alphabetische Gesamtsortierung inkl. Filmkunst
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
  ('musik-klang',               8),
  ('musikrichtungen',           9),
  ('outdoor-natur',            10),
  ('religion-spiritualitaet',  11),
  ('sammeln-kurioses',         12),
  ('spiele-gesellschaft',      13),
  ('sport-bewegung',           14),
  ('sprachen-kultur',          15),
  ('technik-digital',          16)
) as v(slug, neu)
where c.slug = v.slug
  and c.sort_order is distinct from v.neu;

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- ============================================================
  -- Autorenfilmer & Regisseure
  -- ============================================================
  ('filmkunst','pasolini','Pier Paolo Pasolini',array['salò','trilogie des lebens']),
  ('filmkunst','fellini','Federico Fellini',array['dolce vita','zirkus']),
  ('filmkunst','antonioni','Michelangelo Antonioni',array['entfremdung','trilogie']),
  ('filmkunst','visconti','Luchino Visconti',array['senso','dekadenz']),
  ('filmkunst','rossellini','Roberto Rossellini',array['neorealismus','rom']),
  ('filmkunst','de-sica','Vittorio De Sica',array['fahrraddiebe','nachkrieg']),
  ('filmkunst','bertolucci','Bernardo Bertolucci',array['konformist','1900']),
  ('filmkunst','godard','Jean-Luc Godard',array['nouvelle vague','sprünge']),
  ('filmkunst','truffaut','François Truffaut',array['doinel','nouvelle vague']),
  ('filmkunst','rohmer','Éric Rohmer',array['moralisten','dialoge']),
  ('filmkunst','bresson','Robert Bresson',array['minimalismus','modell']),
  ('filmkunst','bunuel','Luis Buñuel',array['surreal','andalusien']),
  ('filmkunst','bergman','Ingmar Bergman',array['persona','schären']),
  ('filmkunst','tarkowski','Andrei Tarkowski',array['stalker','langsam']),
  ('filmkunst','kurosawa','Akira Kurosawa',array['samurai','ronin']),
  ('filmkunst','ozu','Yasujirō Ozu',array['tokio','still']),
  ('filmkunst','miyazaki','Hayao Miyazaki (Anime-Kino)',array['ghibli','anime']),
  ('filmkunst','wong-kar-wai','Wong Kar-wai',array['hongkong','melancholie']),
  ('filmkunst','jarmusch','Jim Jarmusch',array['dead man','understatement']),
  ('filmkunst','coen-brueder','Coen-Brüder',array['lebowski','sarkasmus']),
  ('filmkunst','wes-anderson','Wes Anderson',array['symmetrie','pastell']),
  ('filmkunst','almodovar','Pedro Almodóvar',array['melodram','spanien']),
  ('filmkunst','herzog','Werner Herzog',array['fitzcarraldo','ekstase']),
  ('filmkunst','fassbinder','Rainer Werner Fassbinder',array['brd-trilogie','melodram']),
  ('filmkunst','wenders','Wim Wenders',array['roadmovie','himmel']),
  ('filmkunst','haneke','Michael Haneke',array['kalt','gewalt']),
  ('filmkunst','hitchcock','Alfred Hitchcock',array['suspense','thriller']),
  ('filmkunst','kubrick','Stanley Kubrick',array['uhrwerk','raumfahrt']),
  ('filmkunst','orson-welles','Orson Welles',array['citizen kane','tiefenschärfe']),
  ('filmkunst','billy-wilder','Billy Wilder',array['boulevard','komödie']),
  ('filmkunst','tarantino','Quentin Tarantino',array['pulp','dialoge']),
  ('filmkunst','lynch','David Lynch',array['mulholland','surreal']),
  ('filmkunst','farhadi','Asghar Farhadi',array['iran','drama']),

  -- ============================================================
  -- Filmgeschichtliche Bewegungen
  -- ============================================================
  ('filmkunst','nouvelle-vague','Nouvelle Vague',array['frankreich','60er']),
  ('filmkunst','neorealismus','Italienischer Neorealismus',array['strassen','nachkrieg']),
  ('filmkunst','deutscher-expressionismus','Deutscher Expressionismus',array['caligari','schatten']),
  ('filmkunst','new-hollywood','New Hollywood',array['70er','rebellen']),
  ('filmkunst','dogma95','Dogma 95',array['handkamera','geluebde']),
  ('filmkunst','film-noir','Film noir',array['schwarz','detective']),
  ('filmkunst','heimatfilm','Heimatfilm-Klassiker',array['50er','schwarzwald']),

  -- ============================================================
  -- Filmgenres & Formen
  -- ============================================================
  ('filmkunst','sf-kino','Science-Fiction-Kino',array['dystopie','weltraum']),
  ('filmkunst','horror-aesthetik','Horrorfilm-Ästhetik',array['giallo','practical effects']),
  ('filmkunst','giallo','Giallo',array['argento','mystery']),
  ('filmkunst','western','Western & Italowestern',array['duell','morricone']),
  ('filmkunst','animationsfilm','Animationsfilm (Weltkino)',array['trickfilm','zeichentrick']),
  ('filmkunst','experimentalfilm','Experimentalfilm & Avantgarde',array['material','struktur']),
  ('filmkunst','essayfilm','Essayfilm',array['montage','reflexion']),

  -- ============================================================
  -- Cinephilie & Praxis
  -- ============================================================
  ('filmkunst','filmfestivals','Filmfestivals (Berlinale & Co.)',array['competition','premieren']),
  ('filmkunst','filmclubs','Filmclub & Kinogruppen',array['diskussion','reihe']),
  ('filmkunst','filmkritik','Filmkritik schreiben',array['rezension','blog']),
  ('filmkunst','filmtheorie','Filmtheorie & Montage',array['eisenstein','poetik']),
  ('filmkunst','filmsammlungen','Filme sammeln (Editionen & Criterion)',array['blu-ray','booklet']),
  ('filmkunst','kinogeschichte','Kinogeschichte & Lichtspieltheater',array['kinopalast','projektor']),
  ('filmkunst','stummfilm-live','Stummfilme mit Live-Musik',array['klavier','restauration']),
  ('filmkunst','drehbuch-schreiben','Drehbücher schreiben',array['skript','dramaturgie'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
