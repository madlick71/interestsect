-- interestsect: Bau & Renovierung (neue Kategorie, 100 Handwerke)
--
-- Anlass: klassische Bau- und Ausbaugewerke fehlten (Dach decken,
-- Fliesenlegen, Innenausbau). Bau/Ausbau/Renovierung ist als Eigen-
-- leistungs-Szene deutlich von "Handwerk & Making" (kreativ-mobil)
-- getrennt.
--
-- Idempotent: Inserts ON CONFLICT DO NOTHING, Update mit Bedingung.

insert into public.interest_categories (slug, name_de, name_en, sort_order) values
  ('bau-renovierung', 'Bau & Renovierung', 'Construction & Renovation', 1)
on conflict (slug) do nothing;

-- Alphabetische Gesamtsortierung (19 Kategorien, Bau zuerst)
update public.interest_categories c
set sort_order = v.neu
from (values
  ('bau-renovierung',           1),
  ('bildung-wissenschaft',      2),
  ('filmkunst',                 3),
  ('gesellschaft-engagement',   4),
  ('handwerk-making',           5),
  ('kochen-genuss',             6),
  ('kunst-kreativ',             7),
  ('medizin-gesundheit',        8),
  ('musik-equipment',           9),
  ('musiker-bands',            10),
  ('musik-klang',              11),
  ('musikrichtungen',          12),
  ('outdoor-natur',            13),
  ('religion-spiritualitaet',  14),
  ('sammeln-kurioses',         15),
  ('spiele-gesellschaft',      16),
  ('sport-bewegung',           17),
  ('sprachen-kultur',          18),
  ('technik-digital',          19)
) as v(slug, neu)
where c.slug = v.slug
  and c.sort_order is distinct from v.neu;

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- Dach & Fassade
  ('bau-renovierung','dachdecken','Dach decken',array['dachziegel','lattung']),
  ('bau-renovierung','dachausbau','Dachausbau',array['dachschräge','gaube']),
  ('bau-renovierung','dachfenster-einbau','Dachfenster einbauen',array['velux','dachfläche']),
  ('bau-renovierung','flachdach-begruenung','Flachdach & Begrünung',array['sedum','bitumenbahn']),
  ('bau-renovierung','reetdach','Reet- & Strohdachdecken',array['reet','nadel']),
  ('bau-renovierung','schieferdecken','Schieferdeckung',array['schiefer','haken']),
  ('bau-renovierung','blechdach-stehfalz','Blechdach & Stehfalz',array['kupfer','falz']),
  ('bau-renovierung','dachrinnen','Dachrinnen & Fallrohre',array['rinne','entwässerung']),
  ('bau-renovierung','vordaecher','Vordächer & Überstände',array['konsolen','blech']),
  ('bau-renovierung','fassade','Fassadengestaltung',array['wdvs','klinker']),
  ('bau-renovierung','daemmen','Dämmen (Wand, Dach, Boden)',array['mineralwolle','wlg']),
  ('bau-renovierung','abdichten','Abdichten & Isolieren',array['bitumen','folie']),

  -- Rohbau & Mauerwerk
  ('bau-renovierung','mauerwerk-arbeiten','Maurerarbeiten',array['mauerwerk','mörtel']),
  ('bau-renovierung','betonarbeiten','Betonarbeiten',array['schalung','bewehrung']),
  ('bau-renovierung','verputzen','Verputzen & Glattstrich',array['kalkputz','abreiben']),
  ('bau-renovierung','estrich','Estrich legen',array['schwimmend','ausgleich']),
  ('bau-renovierung','natursteinmauern','Natursteinmauern mauern',array['bruchstein','fugen']),
  ('bau-renovierung','trockenmauern','Trockenmauern (ohne Mörtel)',array['gesetzt','naturstein']),
  ('bau-renovierung','horizontsperre','Horizontsperre & Trockenlegung',array['injektion','aufsteigend']),
  ('bau-renovierung','kellersanierung','Kellersanierung',array['feuchte','abdruck']),
  ('bau-renovierung','stuck-ornamentik','Stuck & Gipsornamentik',array['stuckleiste','rosette']),
  ('bau-renovierung','steinmetzarbeiten','Steinmetzarbeiten',array['stein','meißel']),
  ('bau-renovierung','fachwerk-restaurieren','Fachwerk restaurieren',array['gefach','ausfachung']),
  ('bau-renovierung','zimmerer-holzbau','Zimmerer & Holzbauweise',array['abbund','balkenlage']),
  ('bau-renovierung','holzrahmenbau','Holzrahmenbau',array['wände','plattenbauweise']),
  ('bau-renovierung','gauben-einbau','Gauben einbauen',array['aufkanten','dachfläche']),
  ('bau-renovierung','anbau-aufstockung','Anbauten & Aufstockungen',array['grundstück','rohbau']),
  ('bau-renovierung','statik-verstehen','Statik verstehen',array['lasten','träger']),
  ('bau-renovierung','unterzuege-stahltraeger','Stahlträger & Unterzüge',array['auflager','abstützung']),
  ('bau-renovierung','moertel-mischen','Mörtel & Bindemittel mischen',array['kalkmörtel','rezeptur']),
  ('bau-renovierung','materialkunde-baustoffe','Baustoffe & Materialkunde',array['eigenschaften','baustoffe']),

  -- Innenausbau
  ('bau-renovierung','innenausbau','Innenausbau',array['stuck','wände']),
  ('bau-renovierung','trockenbau','Trockenbau',array['gipskarton','ständerwerk']),
  ('bau-renovierung','fliesenlegen','Fliesenlegen',array['fliesen','fugen']),
  ('bau-renovierung','terrazzo','Terrazzo gießen & schleifen',array['split','polieren']),
  ('bau-renovierung','mikrozement','Mikrozement & Feinputz',array['spachtelputz','bad']),
  ('bau-renovierung','parkett-verlegen','Parkett verlegen',array['schiffsboden','schleifen']),
  ('bau-renovierung','laminat-vinyl','Laminat & Vinyl verlegen',array['klick','unterlage']),
  ('bau-renovierung','holzdielen','Holzdielen verlegen',array['dielen','schrauben']),
  ('bau-renovierung','streichen-malern','Streichen & Malern',array['farbe','rolle']),
  ('bau-renovierung','tapezieren','Tapezieren',array['tapete','kleister']),
  ('bau-renovierung','lackieren','Lackieren (Türen & Möbel)',array['klarlack','spritz']),
  ('bau-renovierung','spachteltechnik','Spachteltechnik',array['glatt','übergänge']),
  ('bau-renovierung','kalkfarben-anstrich','Kalk- & Leimfarben',array['kasein','atmungsaktiv']),
  ('bau-renovierung','farbgestaltung','Farbgestaltung & Beratung',array['farbwirkung','konzept']),
  ('bau-renovierung','holzschutz-lasieren','Holzschutz & Lasieren',array['lasur','pflege']),
  ('bau-renovierung','treppenbau','Treppenbau',array['stufen','geländer']),
  ('bau-renovierung','tueren-einbauen','Türen einbauen',array['zarge','beschlag']),
  ('bau-renovierung','fenster-einbau','Fenster ein- & ausbauen',array['fensterbank','laibung']),
  ('bau-renovierung','fenster-restaurieren','Alte Fenster restaurieren',array['kitt','flügel']),
  ('bau-renovierung','rolllaeden-jalousien','Rollläden & Jalousien',array['gurt','motor']),
  ('bau-renovierung','einbauschraenke','Einbauschränke bauen',array['schräge','front']),
  ('bau-renovierung','schallschutz','Schallschutz verbessern',array['entkoppelung','masse']),

  -- Haustechnik
  ('bau-renovierung','elektroinstallation','Elektroinstallation',array['steckdose','leitung']),
  ('bau-renovierung','lichtplanung','Lichtplanung',array['spots','schaltung']),
  ('bau-renovierung','netzwerk-verkabelung','Netzwerkverkabelung (LAN)',array['cat7','dosen']),
  ('bau-renovierung','sprechanlagen','Sprech- & Klingelanlagen',array['video','klingel']),
  ('bau-renovierung','sanitaerinstallation','Sanitärinstallation',array['siphon','wasserleitung']),
  ('bau-renovierung','heizungsinstallation','Heizung & Heizkörper',array['thermostat','ventil']),
  ('bau-renovierung','fussbodenheizung','Fußbodenheizung verlegen',array['rohre','wärme']),
  ('bau-renovierung','lueftungsanlage-kwl','Lüftungsanlage (KWL)',array['wärmerückgewinnung','kanäle']),
  ('bau-renovierung','badrenovierung','Bad renovieren',array['dusche','waschtisch']),
  ('bau-renovierung','kuechenmontage','Küche montieren',array['arbeitsplatte','spüle']),
  ('bau-renovierung','solar-montage','Solar- & PV-Montage',array['module','dachhaken']),
  ('bau-renovierung','thermografie-gebaeude','Thermografie am Gebäude',array['wärmekamera','lecks']),
  ('bau-renovierung','einbruchschutz','Einbruchschutz & Sicherheit',array['absicherung','beschlag']),

  -- Außenanlagen
  ('bau-renovierung','balkon-terrassenbau','Balkon & Terrasse bauen',array['wpc','bohlen']),
  ('bau-renovierung','zaeune-tore','Zäune & Tore bauen',array['zaunlatten','tor']),
  ('bau-renovierung','carport','Carport bauen',array['pfosten','dach']),
  ('bau-renovierung','pflastern','Pflastern & Gartenwege',array['pflastersteine','randeinfassung']),
  ('bau-renovierung','gartenhaus-bauen','Gartenhaus bauen',array['fundament','wände']),
  ('bau-renovierung','gewaechshaus-bauen','Gewächshaus bauen',array['folie','gestänge']),
  ('bau-renovierung','pergola','Pergola & Rankgerüste',array['spaliere','holz']),
  ('bau-renovierung','weidenbau','Weidenbau & Flechtzäune',array['weiden','tunnel']),
  ('bau-renovierung','teichbau','Teich- & Schwimmteichbau',array['folie','filter']),
  ('bau-renovierung','bewaesserungsanlagen','Bewässerungsanlagen',array['tröpfchen','steuerung']),
  ('bau-renovierung','gala-garten-landschaftsbau','Garten- & Landschaftsbau',array['bepflanzung','erdarbeiten']),
  ('bau-renovierung','wintergarten','Wintergärten',array['aluminium','glas']),
  ('bau-renovierung','markisen-sonnenschutz','Markisen & Sonnenschutz',array['stoff','kurbel']),
  ('bau-renovierung','sauna-bauen','Sauna selbst bauen',array['holzofen','kabine']),

  -- Metall, Grundlagen & Organisation
  ('bau-renovierung','metallbau','Metallbau & Konstruktionen',array['winkelschleifer','profile']),
  ('bau-renovierung','gerueste','Gerüste & Arbeitsbühnen',array['gerüst','absturzsicherung']),
  ('bau-renovierung','bauplanung','Bauplanung & Zeichnungen',array['grundriss','plan']),
  ('bau-renovierung','eigenleistung-bauen','Hausbau in Eigenleistung',array['selbstbau','gewerke']),
  ('bau-renovierung','heimwerken','Heimwerken (allgemein)',array['diy','werkstatt']),
  ('bau-renovierung','werkzeug-schaerfen','Werkzeug pflegen & schärfen',array['wetzstahl','sägeblatt']),
  ('bau-renovierung','glaserei','Glaserei & Glasbau',array['glasscheibe','kitt']),

  -- Traditionelle Handwerke
  ('bau-renovierung','wagner-stellmacher','Wagner & Stellmacher',array['speichen','holz']),
  ('bau-renovierung','kuefer-boettcher','Küfer & Böttcher',array['dauben','fass']),
  ('bau-renovierung','seilerei','Seilerei',array['taue','garn']),
  ('bau-renovierung','posamenten','Posamenten & Borten',array['quasten','borten']),
  ('bau-renovierung','schuhmacher','Schuhmacher & Schuhreparatur',array['sohle','naht']),
  ('bau-renovierung','glasblasen','Glasblasen',array['glashütte','pfeife']),
  ('bau-renovierung','ziselieren','Ziselieren & Treiben',array['punze','blech']),
  ('bau-renovierung','gravieren','Gravieren & Stempelschnitt',array['stichel','schrift']),
  ('bau-renovierung','hufschmied','Hufbeschlag',array['hufe','schmied']),
  ('bau-renovierung','kuerschnerei','Kürschnerei',array['fell','verarbeitung']),
  ('bau-renovierung','hutmacherei','Hutmacherei (Filzhüte)',array['hut','blocken']),
  ('bau-renovierung','segelmacherei','Segelmacherei',array['segeltuch','nähen']),
  ('bau-renovierung','blaudruck','Blaudruck & Zeugdruck',array['modeldruck','indigo'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
