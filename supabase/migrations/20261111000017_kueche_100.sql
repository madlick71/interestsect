-- interestsect: Kochen & Genuss — Richtungen, Desserts & Cocktails (+100)
--
-- Anlass: Kochrichtungen waren dünn (< 10 sichtbare Richtungen pro Lager).
-- Erweiterung um Welt- & Regionalküchen, Dessert-/Backwerk-Richtungen
-- und Cocktail-/Getränkekultur (inkl. alkoholfrei).
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- ============================================================
  -- Weltküchen
  -- ============================================================
  ('kochen-genuss','thai-kueche','Thailändische Küche',array['curry','wok']),
  ('kochen-genuss','italienische-kueche','Italienische Küche',array['antipasti','olio']),
  ('kochen-genuss','spanische-kueche','Spanische Küche & Tapas',array['tapas','pimientos']),
  ('kochen-genuss','portugiesische-kueche','Portugiesische Küche',array['bacalhau','cataplana']),
  ('kochen-genuss','griechische-kueche','Griechische Küche',array['meze','feta']),
  ('kochen-genuss','franzoesische-kueche','Französische Küche',array['bistro','beurre']),
  ('kochen-genuss','britische-kueche','Britische Küche',array['sunday roast','pie']),
  ('kochen-genuss','irische-kueche','Irische Küche',array['stew','soda bread']),
  ('kochen-genuss','ungarische-kueche','Ungarische Küche',array['gulasch','paprika']),
  ('kochen-genuss','tschechische-kueche','Tschechische Küche',array['svíčková','knedlik']),
  ('kochen-genuss','ukrainische-kueche','Ukrainische Küche',array['borschtsch','wareniki']),
  ('kochen-genuss','armenische-kueche','Armenische Küche',array['lavash','dolma']),
  ('kochen-genuss','usbekische-kueche','Usbekische Küche',array['plov','samsa']),
  ('kochen-genuss','persische-kueche','Persische Küche',array['saffran','tahdig']),
  ('kochen-genuss','afghanische-kueche','Afghanische Küche',array['mantu','naan']),
  ('kochen-genuss','sri-lankische-kueche','Sri-Lankische Küche',array['hoppers','kokos']),
  ('kochen-genuss','indonesische-kueche','Indonesische Küche',array['nasi goreng','rendang']),
  ('kochen-genuss','philippinische-kueche','Philippinische Küche',array['adobo','lumpia']),
  ('kochen-genuss','suedafrikanische-kueche','Südafrikanische Küche',array['braai','biltong']),
  ('kochen-genuss','nigerianische-kueche','Nigerianische Küche',array['jollof','egusi']),
  ('kochen-genuss','aegyptische-kueche','Ägyptische Küche',array['koshari','molokhia']),
  ('kochen-genuss','tunesische-kueche','Tunesische Küche',array['harissa','brik']),
  ('kochen-genuss','syrische-kueche','Syrische Küche',array['mezze','kibbeh']),
  ('kochen-genuss','kubanische-kueche','Kubanische Küche',array['moro','flan']),
  ('kochen-genuss','argentinische-kueche','Argentinische Küche & Asado',array['asado','chimichurri']),
  ('kochen-genuss','venezolanische-kueche','Venezolanische Küche',array['arepas','tequeños']),
  ('kochen-genuss','tex-mex','Tex-Mex & BBQ-Kreuzung',array['chili','ribs']),
  ('kochen-genuss','mittelmeer-kueche','Mittelmeer-Küche',array['olivenöl','gemüse']),

  -- ============================================================
  -- Deutsche Regionalküchen
  -- ============================================================
  ('kochen-genuss','bayrische-kueche','Bayerische Küche',array['schweinshaxe','brezn']),
  ('kochen-genuss','schwaebische-kueche','Schwäbische Küche',array['maultaschen','brägele']),
  ('kochen-genuss','hessische-kueche','Hessische Küche',array['grüne soße','handkäs']),
  ('kochen-genuss','rheinische-kueche','Rheinische Küche',array['himmel und äd','halve hahn']),
  ('kochen-genuss','pfaelzer-kueche','Pfälzer Küche',array['saumagen','dampfnudeln']),
  ('kochen-genuss','fraenkische-kueche','Fränkische Küche',array['schäufele','karpfen']),
  ('kochen-genuss','saechsische-kueche','Sächsische Küche',array['quarkkeulchen','sauerbraten']),
  ('kochen-genuss','thueringer-kueche','Thüringer Küche',array['klöße','rostbratwurst']),
  ('kochen-genuss','berliner-kueche','Berliner Küche',array['currywurst','eisbein']),
  ('kochen-genuss','hamburger-kueche','Hamburger Küche',array['labskaus','fischbrötchen']),

  -- ============================================================
  -- Desserts & Backwerk
  -- ============================================================
  ('kochen-genuss','cheesecake','Cheesecakes',array['new york','boden']),
  ('kochen-genuss','tiramisu','Tiramisu & italienische Desserts',array['savoiardi','mascarpone']),
  ('kochen-genuss','creme-brulee','Crème brûlée & Cremes',array['karamellkruste','vanille']),
  ('kochen-genuss','panna-cotta','Panna Cotta',array['gelatine','sahne']),
  ('kochen-genuss','mousse-au-chocolat','Mousse au Chocolat',array['luftig','dunkel']),
  ('kochen-genuss','souffles','Soufflés',array['aufgehen','ofen']),
  ('kochen-genuss','crumble-cobbler','Crumble & Cobbler',array['streusel','obst']),
  ('kochen-genuss','pies-tarts','Pies & Tarts',array['mürbeteig','rand']),
  ('kochen-genuss','strudel-backen','Strudel backen',array['apfelstrudel','blätterteig']),
  ('kochen-genuss','cupcakes','Cupcakes & Frosting',array['tüllchen','buttercreme']),
  ('kochen-genuss','brownies-blondies','Brownies & Blondies',array['fudgy','schokoladig']),
  ('kochen-genuss','makronen','Makronen',array['kokos','mandeln']),
  ('kochen-genuss','baiser','Baiser',array['eiweiß','spritzbeutel']),
  ('kochen-genuss','windbeutel','Windbeutel & Brandteig',array['profiteroles','creme']),
  ('kochen-genuss','eclairs','Éclairs',array['ganache','lange']),
  ('kochen-genuss','gelee-fruchtgummi','Gelee & Fruchtgummi',array['guss','fruchtig']),
  ('kochen-genuss','marzipan','Marzipan formen',array['rosen','figur']),
  ('kochen-genuss','nougat','Nougat',array['montélimar','nuss']),
  ('kochen-genuss','sandkuchen-ruehrkuchen','Rühr- & Sandkuchen',array['butter','klassiker']),
  ('kochen-genuss','obstkuchen','Obstkuchen & Blechkuchen',array['rhabarber','pflaumen']),
  ('kochen-genuss','gugelhupf','Gugelhupf',array['kranz','marmor']),
  ('kochen-genuss','panettone','Panettone & Festtagsgebäck',array['weihnachten','italien']),
  ('kochen-genuss','stollen','Stollen backen',array['dresdner','marzipan']),
  ('kochen-genuss','lebkuchen','Lebkuchen',array['honig','gewürz']),
  ('kochen-genuss','crepes-waffeln','Crêpes & Waffeln',array['eisen','pfannkuchen']),
  ('kochen-genuss','kaesekuchen','Käsekuchen',array['quark','boden']),
  ('kochen-genuss','schwarzwaelder-kirschtorte','Schwarzwälder Kirschtorte',array['kirsche','sahne']),
  ('kochen-genuss','linzer-torte','Linzer Torte',array['gitter','marmelade']),
  ('kochen-genuss','milchreis-griessbrei','Milchreis & Grießbrei',array['zimt','warm']),
  ('kochen-genuss','schokoladenfondue','Schokoladenfondue',array['töpfe','spieße']),
  ('kochen-genuss','rumtopf','Rumtopf ansetzen',array['früchte','rum']),

  -- ============================================================
  -- Cocktails & Getränke
  -- ============================================================
  ('kochen-genuss','tiki-cocktails','Tiki-Cocktails',array['mai tai','rum']),
  ('kochen-genuss','sour-cocktails','Sour-Cocktails',array['zitrone','eiweiß']),
  ('kochen-genuss','negroni-cocktails','Negroni & Bitter-Klassiker',array['campari','gin']),
  ('kochen-genuss','martini-manhattan','Martini & Manhattan',array['vermouth','gerührt']),
  ('kochen-genuss','mojito-style','Mojito & Muddler-Drinks',array['minze','kalk']),
  ('kochen-genuss','aperitivo-spritz','Aperitivo & Spritz',array['aperol','prosecco']),
  ('kochen-genuss','highballs','Highballs',array['soda','eis']),
  ('kochen-genuss','mocktails','Alkoholfreie Cocktails',array['virgin','alkoholfrei']),
  ('kochen-genuss','margarita','Margaritas',array['salzrand','tequila']),
  ('kochen-genuss','daiquiri-frozen','Daiquiri & Frozen Drinks',array['blended','limette']),
  ('kochen-genuss','kaffee-cocktails','Kaffee-Cocktails',array['espresso martini','irish']),
  ('kochen-genuss','wein-cocktails','Wein-Cocktails',array['sangria','tinto']),
  ('kochen-genuss','bier-cocktails','Bier-Cocktails',array['radler','berliner']),
  ('kochen-genuss','bowle-punsch','Bowle & Punsch',array['früchte','kessel']),
  ('kochen-genuss','gluehwein','Glühwein & Heißgetränke',array['winter','gewürz']),
  ('kochen-genuss','eistee-eiskaffee','Eistee & Eiskaffee',array['kalt','aufgegossen']),
  ('kochen-genuss','milchshakes','Milchshakes',array['eis','milch']),
  ('kochen-genuss','irish-coffee','Irish Coffee',array['creme','whisky']),
  ('kochen-genuss','gin-verkosten','Gin verkosten',array['botanicals','tonic']),
  ('kochen-genuss','rum-verkosten','Rum verkosten',array['karibik','molasse']),
  ('kochen-genuss','tequila-mezcal','Tequila & Mezcal',array['agave','joven']),
  ('kochen-genuss','grappa','Grappa & Tresterbrände',array['trester','italien']),
  ('kochen-genuss','obstler-edelbrand','Obstler & Edelbrände',array['brennerei','frucht']),
  ('kochen-genuss','sake','Sake verkosten',array['reis','japan']),

  -- ============================================================
  -- Richtungen & Techniken
  -- ============================================================
  ('kochen-genuss','streetfood','Streetfood',array['hallen','imbiss']),
  ('kochen-genuss','fusion-kueche','Fusion-Küche',array['kombination','cross-over']),
  ('kochen-genuss','regional-kueche','Regionale Küche & Heimatprodukte',array['herkunft','erzeuger']),
  ('kochen-genuss','wok-kueche','Wok-Küche',array['pfannenrühren','asien']),
  ('kochen-genuss','daempfen','Dämpfen',array['körbchen','schonend']),
  ('kochen-genuss','frittieren','Frittieren',array['fritteuse','panade']),
  ('kochen-genuss','kandieren','Kandieren & Einzuckern',array['früchte','sirup'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
