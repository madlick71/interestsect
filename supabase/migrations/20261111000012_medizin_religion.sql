-- interestsect: Medizin & Gesundheit + Religion & Spiritualität (neue
-- Kategorien), Aufstockung der dünnsten Felder
--
-- Quellen (recherchiert 2026-11):
--   * Medizin: öffentliche Gesundheitsportale (BZgA-Themen), DRK/JRC-
--     Erste-Hilfe-Curricula, Laienmedizin-Szenen (Quantified Self,
--     Mikrobiom, Langlebigkeit/Blue Zones), Kneipp/Sauna-Kultur (DE)
--   * Religion: Wikipedia-Überblicksartikel zu Buddhismus-Richtungen
--     (Theravada/Mahayana/Zen/Vajrayana/Reines Land), Religionsgemein-
--     schaften in Deutschland (REMID-Datenbasis) — kuratiert als
--     Identitäts-Interessen, konfessionell neutral formuliert
--   * Schwachfelder nach Zählung: Gesellschaft & Engagement (64),
--     Musik machen (72), Spiele (73), Kochen & Genuss (76)
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interest_categories (slug, name_de, name_en, sort_order) values
  ('medizin-gesundheit',     'Medizin & Gesundheit',    'Medicine & Health',       6),
  ('religion-spiritualitaet','Religion & Spiritualität','Religion & Spirituality', 10)
on conflict (slug) do nothing;

-- Alphabetische Gesamtsortierung inkl. neuer Kategorien
update public.interest_categories c
set sort_order = v.neu
from (values
  ('bildung-wissenschaft',      1),
  ('gesellschaft-engagement',   2),
  ('handwerk-making',           3),
  ('kochen-genuss',             4),
  ('kunst-kreativ',             5),
  ('medizin-gesundheit',        6),
  ('musik-klang',               7),
  ('musikrichtungen',           8),
  ('outdoor-natur',             9),
  ('religion-spiritualitaet',  10),
  ('sammeln-kurioses',         11),
  ('spiele-gesellschaft',      12),
  ('sport-bewegung',           13),
  ('sprachen-kultur',          14),
  ('technik-digital',          15)
) as v(slug, neu)
where c.slug = v.slug
  and c.sort_order is distinct from v.neu;

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- ============================================================
  -- Medizin & Gesundheit
  -- ============================================================
  ('medizin-gesundheit','erstehilfe-kurse','Erste-Hilfe-Kurse & Auffrischung',array['notfall','drk']),
  ('medizin-gesundheit','reanimation-aed','Reanimation & AED-Training',array['bls','defi']),
  ('medizin-gesundheit','kindernotfaelle','Kinder-Notfälle & Erste Hilfe',array['kinder','notfall']),
  ('medizin-gesundheit','notfallmedizin-rettungsdienst','Notfallmedizin & Rettungsdienst',array['sani','notarzt']),
  ('medizin-gesundheit','anatomie-pathologie','Anatomie & Pathologie (Laienwissen)',array['organe','präparate']),
  ('medizin-gesundheit','medizinmuseen','Medizinhistorische Museen',array['museum','instrumente']),
  ('medizin-gesundheit','medizin-podcasts-buecher','Medizin-Bücher & Podcasts',array['fachliteratur','wissen']),
  ('medizin-gesundheit','medizinethik','Medizinethik diskutieren',array['ethik','entscheidungen']),
  ('medizin-gesundheit','naturheilkunde','Naturheilkunde',array['heilkunde','pflanzen']),
  ('medizin-gesundheit','heilpflanzen-hausapotheke','Heilpflanzen & Hausapotheke',array['tee','salbe']),
  ('medizin-gesundheit','hausmittel-wickel','Hausmittel & Wickel',array['auflagen','rezepte']),
  ('medizin-gesundheit','tcm','Traditionelle Chinesische Medizin',array['akupunktur','qi']),
  ('medizin-gesundheit','ayurveda','Ayurveda',array['doshas','ernährung']),
  ('medizin-gesundheit','kneipp-hydrotherapie','Kneipp & Hydrotherapie',array['wassertreten','güsse']),
  ('medizin-gesundheit','sauna-kultur','Sauna-Kultur',array['aufguss','dampfbad']),
  ('medizin-gesundheit','fasten-heilfasten','Heilfasten & Intervallfasten',array['kur','16:8']),
  ('medizin-gesundheit','atemarbeit','Atemtechniken & Atemarbeit',array['pranayama','atmung']),
  ('medizin-gesundheit','meditation','Meditation',array['stille','sitzkissen']),
  ('medizin-gesundheit','achtsamkeit-mbsr','Achtsamkeit (MBSR)',array['mindfulness','übungen']),
  ('medizin-gesundheit','pmr','Progressive Muskelentspannung',array['pmr','entspannung']),
  ('medizin-gesundheit','autogenes-training','Autogenes Training',array['formeln','ruhe']),
  ('medizin-gesundheit','quantified-self','Selbstvermessung (Quantified Self)',array['wearable','tracking']),
  ('medizin-gesundheit','schlaf-hygiene','Schlaf & Schlafhygiene',array['schlaf','rhythmus']),
  ('medizin-gesundheit','traeume-traumdeutung','Träume & Traumdeutung',array['traumbuch','symbole']),
  ('medizin-gesundheit','fussreflexzonenmassage','Fußreflexzonenmassage',array['zonen','druckpunkte']),
  ('medizin-gesundheit','massage-lernen','Massage lernen',array['rücken','griffe']),
  ('medizin-gesundheit','physiotherapie-wissen','Physiotherapie & Bewegungslehre',array['übung','haltung']),
  ('medizin-gesundheit','sportmedizin','Sportmedizin (Wissen)',array['belastung','puls']),
  ('medizin-gesundheit','rueckenschule','Rückenschule & Rückengesundheit',array['wirbelsäule','haltung']),
  ('medizin-gesundheit','taping-sportverletzungen','Taping & Sportverletzungen',array['kinesio','bandagen']),
  ('medizin-gesundheit','hautpflege-dermatologie','Hautpflege & Dermatologie-Wissen',array['haut','pflege']),
  ('medizin-gesundheit','allergien-intoleranzen','Allergien & Intoleranzen',array['heuschnupfen','laktose']),
  ('medizin-gesundheit','blutwerte-labor','Blutwerte & Labor verstehen',array['werte','diagnostik']),
  ('medizin-gesundheit','infektionsschutz','Infektionsschutz & Hygienekunde',array['keime','impfen']),
  ('medizin-gesundheit','virologie-immunologie','Virologie & Immunologie',array['viren','immunsystem']),
  ('medizin-gesundheit','genetik-verstehen','Genetik verstehen',array['dna','vererbung']),
  ('medizin-gesundheit','epigenetik-alterung','Epigenetik & Alterungsforschung',array['telomere','forschung']),
  ('medizin-gesundheit','langlebigkeit','Langlebigkeit & Anti-Aging',array['blue zones','altern']),
  ('medizin-gesundheit','medizintechnik-prothetik','Medizintechnik & Prothetik',array['implantat','geräte']),
  ('medizin-gesundheit','kindermedizin-eltern','Kindermedizin für Eltern',array['kinder','fieber']),
  ('medizin-gesundheit','hormonwissen','Hormone & Schilddrüse verstehen',array['schilddrüse','wechseljahre']),
  ('medizin-gesundheit','darmgesundheit-mikrobiom','Darmgesundheit & Mikrobiom',array['darmflora','probiotika']),
  ('medizin-gesundheit','zahnmedizin-wissen','Zahnmedizin-Wissen',array['zähne','prophylaxe']),
  ('medizin-gesundheit','psychoedukation','Psychische Gesundheit & Psychoedukation',array['seele','störungen']),
  ('medizin-gesundheit','resilienz-selbstfuersorge','Resilienz & Selbstfürsorge',array['stress','stärke']),
  ('medizin-gesundheit','neurodiversitaet','Neurodiversität verstehen',array['adhs','autismus']),
  ('medizin-gesundheit','patientenverfuegung','Patientenverfügung & Vorsorge',array['vollmacht','wille']),
  ('medizin-gesundheit','organspende-aufklaerung','Organspende-Aufklärung',array['spende','transplantation']),
  ('medizin-gesundheit','tier-erste-hilfe','Erste Hilfe am Tier',array['hund','notfall']),
  ('medizin-gesundheit','tiermedizin-wissen','Tiermedizin & Tiergesundheit',array['krankheiten','tierarzt']),
  ('medizin-gesundheit','tierernaehrung','Tierernährung (BARF & Co.)',array['barf','futter']),
  ('medizin-gesundheit','ernaehrungswissenschaft','Ernährungswissenschaft',array['makros','studien']),

  -- ============================================================
  -- Religion & Spiritualität
  -- ============================================================
  ('religion-spiritualitaet','buddhismus','Buddhismus',array['dharma','buddha']),
  ('religion-spiritualitaet','theravada','Theravada',array['pali','kloster']),
  ('religion-spiritualitaet','mahayana','Mahayana',array['bodhisattva','sutra']),
  ('religion-spiritualitaet','zen-buddhismus','Zen-Buddhismus',array['zazen','koan']),
  ('religion-spiritualitaet','tibetischer-buddhismus','Tibetischer Buddhismus (Vajrayana)',array['mantra','lama']),
  ('religion-spiritualitaet','reines-land','Reines-Land-Buddhismus',array['amitabha','nembutsu']),
  ('religion-spiritualitaet','vipassana','Vipassana-Meditation',array['einkehr','kurse']),
  ('religion-spiritualitaet','metta-meditation','Metta & Loving-Kindness',array['güte','wünsche']),
  ('religion-spiritualitaet','dharma-studium','Dharma-Studium & Sutras',array['texte','lehre']),
  ('religion-spiritualitaet','sangha-retreats','Sangha & Retreats',array['gemeinschaft','schweigen']),
  ('religion-spiritualitaet','engagierter-buddhismus','Engagierter Buddhismus',array['mitgefühl','handeln']),
  ('religion-spiritualitaet','buddhistische-feste','Buddhistische Feste (Vesak & Co.)',array['vesak','feiertage']),
  ('religion-spiritualitaet','christentum','Christentum',array['glaube','kirche']),
  ('religion-spiritualitaet','katholisches-leben','Katholisches Leben',array['messe','heilige']),
  ('religion-spiritualitaet','evangelisches-leben','Evangelisches Leben',array['gottesdienst','gemeinde']),
  ('religion-spiritualitaet','orthodoxe-kirchen','Orthodoxe Kirchen',array['ikonen','liturgie']),
  ('religion-spiritualitaet','freikirchen-gemeinschaften','Freikirchen & Gemeinschaften',array['gemeinschaft','glaubenstaufe']),
  ('religion-spiritualitaet','taize-gebet','Taizé-Gebet & Gesang',array['taize','lieder']),
  ('religion-spiritualitaet','kontemplation-exerzitien','Kontemplation & Exerzitien',array['stille','wege']),
  ('religion-spiritualitaet','bibelkreis','Bibelkreis & Bibel-Teilen',array['bibel','austausch']),
  ('religion-spiritualitaet','geistliche-lieder','Geistliche Lieder & Choräle',array['choral','gesang']),
  ('religion-spiritualitaet','kirchenjahr-brauchtum','Kirchenjahr & Brauchtum',array['advent','ostern']),
  ('religion-spiritualitaet','wallfahrten','Wallfahrten & Pilgerorte',array['wallfahrt','heiligtum']),
  ('religion-spiritualitaet','kloster-auf-zeit','Kloster auf Zeit',array['gästehaus','schweigen']),
  ('religion-spiritualitaet','christliche-meditation','Christliche Meditation & Gebet',array['gebet','inneres']),
  ('religion-spiritualitaet','gebetskreis','Gebetskreise',array['gemeinsam','fürbitte']),
  ('religion-spiritualitaet','islam','Islam',array['glaube','umma']),
  ('religion-spiritualitaet','sufismus','Sufismus & Dhikr',array['derwisch','dhikr']),
  ('religion-spiritualitaet','ramadan-feste','Ramadan & Islamische Feste',array['fasten','opferfest']),
  ('religion-spiritualitaet','koran-studium','Koran-Studium',array['koran','tafsir']),
  ('religion-spiritualitaet','judentum','Judentum (Leben & Tradition)',array['thora','koscher']),
  ('religion-spiritualitaet','schabbat-feste','Schabbat & Jüdische Feste',array['schabbat','pe sach']),
  ('religion-spiritualitaet','hinduismus','Hinduismus',array['tempel','götter']),
  ('religion-spiritualitaet','bhakti-kirtan','Bhakti & Kirtan (Mantras)',array['mantra','gesang']),
  ('religion-spiritualitaet','yoga-philosophie','Yoga-Philosophie & Sutras',array['patanjali','acht glieder']),
  ('religion-spiritualitaet','vedanta','Vedanta-Philosophie',array['upanishaden','einheit']),
  ('religion-spiritualitaet','sikhismus','Sikhismus',array['guru','gurdwara']),
  ('religion-spiritualitaet','bahaitum','Bahaitum',array['bahai','einheit']),
  ('religion-spiritualitaet','daoismus','Daoismus',array['dao','wu wei']),
  ('religion-spiritualitaet','schamanismus','Schamanismus & Trommelreisen',array['trommel','reise']),
  ('religion-spiritualitaet','asatro','Germanisches Heidentum (Ásatrú)',array['edda','runen']),
  ('religion-spiritualitaet','neuheidentum','Neuheidentum & Naturspiritualität',array['natur','rituale']),
  ('religion-spiritualitaet','mystik','Mystik (alle Traditionen)',array['einheit','kontemplation']),
  ('religion-spiritualitaet','interreligioeser-dialog','Interreligiöser Dialog',array['dialog','begegnung']),
  ('religion-spiritualitaet','anthroposophie','Anthroposophie',array['steiner','goetheanum']),
  ('religion-spiritualitaet','saekularer-humanismus','Säkularer Humanismus',array['vernunft','ethik']),
  ('religion-spiritualitaet','atheismus-agnostizismus','Atheismus & Agnostizismus',array['weltbild','diskurs']),

  -- ============================================================
  -- Gesellschaft & Engagement (Aufstockung)
  -- ============================================================
  ('gesellschaft-engagement','tafel-fahrer','Lieferfahren für Tafeln',array['transport','ausgabe']),
  ('gesellschaft-engagement','benefizkonzerte','Benefizkonzerte organisieren',array['spenden','musik']),
  ('gesellschaft-engagement','bibliotheksdienst','Bibliotheks- & Bücherbus-Dienst',array['bücher','ausleihe']),
  ('gesellschaft-engagement','vorlesestunden','Vorlesestunden (Bibliothek)',array['bilderbuch','kinder']),
  ('gesellschaft-engagement','hausaufgabencafe','Hausaufgaben-Café',array['schüler','lernen']),
  ('gesellschaft-engagement','ferienlager','Ferienlager betreuen',array['zeltlager','kinder']),
  ('gesellschaft-engagement','jugendtreff','Offener Jugendtreff betreuen',array['treff','jugend']),
  ('gesellschaft-engagement','schulbegleitung','Schulbegleitung',array['integration','unterstützung']),
  ('gesellschaft-engagement','warme-mahlzeiten','Warme Mahlzeiten ausgeben',array['suppenküche','küche']),
  ('gesellschaft-engagement','flussreinigung','Fluss- & Seenreinigung',array['müll','gewässer']),
  ('gesellschaft-engagement','baumpflanzaktionen','Baumpflanzaktionen',array['pflanzen','aufforstung']),
  ('gesellschaft-engagement','gruenflaechen-patenschaft','Grünflächen-Patenschaft',array['park','beete']),
  ('gesellschaft-engagement','bluehpatenschaften','Blühpatenschaften',array['bienen','wiesen']),
  ('gesellschaft-engagement','faire-woche','Faire Woche organisieren',array['fair','aktionen']),
  ('gesellschaft-engagement','nachbarschaftsfest','Nachbarschaftsfeste organisieren',array['fest','straße']),
  ('gesellschaft-engagement','seniorensport-anleiten','Seniorensport anleiten',array['gymnastik','gruppen']),
  ('gesellschaft-engagement','demenzcafe','Demenz-Café begleiten',array['demenz','café']),
  ('gesellschaft-engagement','adventsbasar','Adventsbasar & Basare',array['basar','handarbeit']),
  ('gesellschaft-engagement','vereinsheim-pflege','Vereinsheim & Platzpflege',array['platz','heim']),
  ('gesellschaft-engagement','jugendfeuerwehr-betreuen','Jugendfeuerwehr betreuen',array['jugend','einsatz']),

  -- ============================================================
  -- Musik machen (Aufstockung)
  -- ============================================================
  ('musik-klang','panfloete','Panflöte',array['rohr','rumänien']),
  ('musik-klang','nyckelharpa','Nyckelharpa',array['schlüssel','fiedel']),
  ('musik-klang','dulcimer','Appalachian Dulcimer',array['zither','saiten']),
  ('musik-klang','noten-sammeln','Noten & Partituren sammeln',array['noten','antiquariat']),
  ('musik-klang','klavier-stimmen','Klavier stimmen lernen',array['stimmhammer','ton']),
  ('musik-klang','instrumenten-restauration','Instrumente restaurieren',array['geige','lack']),
  ('musik-klang','community-singing','Singabende (Community Singing)',array['lieder','kreis']),
  ('musik-klang','chor-reisen','Chor-Reisen & Austausch',array['reise','konzert']),
  ('musik-klang','musikvermittlung','Musikvermittlung & Konzertführungen',array['konzert','pädagogik']),
  ('musik-klang','partitur-lesen','Partiturlesen lernen',array['partitur','partei']),
  ('musik-klang','gehoerbildung','Gehörbildung',array['intervalle','diktat']),
  ('musik-klang','songbooks-fakebooks','Songbooks & Fakebooks spielen',array['akkorde','standards']),
  ('musik-klang','open-mic-auftritte','Open-Mic-Auftritte (Musik)',array['bühne','solist']),
  ('musik-klang','midi-sequencing','MIDI & Sequencing',array['midi','daw']),
  ('musik-klang','strassenmusik','Straßenmusik',array['busken','stadt']),

  -- ============================================================
  -- Kochen & Genuss (Aufstockung)
  -- ============================================================
  ('kochen-genuss','afrikanische-kueche','Westafrikanische Küche',array['jollof','fufu']),
  ('kochen-genuss','aethiopische-kueche','Äthiopisch & Injera',array['teff','wot']),
  ('kochen-genuss','marokkanische-kueche','Marokkanische Küche',array['tagine','ras el']),
  ('kochen-genuss','libanesische-mezze','Libanesisch & Mezze',array['hummus','tabbouleh']),
  ('kochen-genuss','georgische-kueche','Georgische Küche & Supra',array['khinkali','chatschapuri']),
  ('kochen-genuss','russische-osteuropaeische','Russische & Osteuropäische Küche',array['borschtsch','pelmeni']),
  ('kochen-genuss','polnische-kueche','Polnische Küche',array['pierogi','bigos']),
  ('kochen-genuss','nordische-kueche','Nordische Küche',array['smörrebröd','fika']),
  ('kochen-genuss','oesterreichische-kueche','Österreichische Küche',array['wiener','torte']),
  ('kochen-genuss','schweizer-kueche','Schweizer Küche',array['rösti','käse']),
  ('kochen-genuss','karibische-kueche','Karibische Küche',array['jerk','plantains']),
  ('kochen-genuss','peruanische-kueche','Peruanische Küche',array['ceviche','nikkei']),
  ('kochen-genuss','brasilianische-kueche','Brasilianische Küche',array['feijoada','moqueca']),
  ('kochen-genuss','japanisches-homecooking','Japanisches Homecooking',array['donburi','okonomiyaki']),
  ('kochen-genuss','vietnamesische-kueche','Vietnamesische Küche',array['pho','bun']),
  ('kochen-genuss','schneidetechniken','Schneidetechniken (Knife Skills)',array['messer','schnippeln']),
  ('kochen-genuss','slow-cooker-dutch-oven','Slow Cooker & Dutch Oven',array['crockpot','gusseisen']),
  ('kochen-genuss','kochen-mit-kindern','Kochen mit Kindern',array['familie','einfach']),
  ('kochen-genuss','bowls-meal-prep','Bowls & Meal-Prep',array['bowl','vorbereiten']),
  ('kochen-genuss','sekt-champagner','Sekt & Champagner verkosten',array['crémant','perlen']),

  -- ============================================================
  -- Spiele & Gesellschaft (Aufstockung)
  -- ============================================================
  ('spiele-gesellschaft','uno-abende','Uno & Schnelle Familienspiele',array['uno','runden']),
  ('spiele-gesellschaft','activity-party','Activity & Party-Spiele',array['pantomime','begriffe']),
  ('spiele-gesellschaft','tabu-alias','Tabu & Alias',array['umschreiben','teams']),
  ('spiele-gesellschaft','codenames-wortspiele','Codenames & Wortspiele',array['begriffe','teams']),
  ('spiele-gesellschaft','just-one','Just One & Kooperations-Raten',array['hinweise','gemeinsam']),
  ('spiele-gesellschaft','carcassonne-legespiele','Carcassonne & Legespiele',array['legen','landschaft']),
  ('spiele-gesellschaft','catan-abende','Catan & Handelspiele',array['handeln','ressourcen']),
  ('spiele-gesellschaft','ticket-to-ride','Ticket to Ride & Routenspiele',array['strecken','züge']),
  ('spiele-gesellschaft','azul-muster','Azul & Muster-Legespiele',array['azul','muster']),
  ('spiele-gesellschaft','solo-rollenspiel','Solo-Rollenspiele (Journaling)',array['solo','tagebuch']),
  ('spiele-gesellschaft','mobile-games','Mobile Games',array['handy','kurz']),
  ('spiele-gesellschaft','nintendo-abende','Nintendo & Konsolen-Abende',array['switch','mario']),
  ('spiele-gesellschaft','mariokart-runden','Mario Kart & Fun-Racer',array['kart','items']),
  ('spiele-gesellschaft','ea-fc-fussballspiele','EA FC & Fußball-Videospiele',array['fifa','kicken'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
