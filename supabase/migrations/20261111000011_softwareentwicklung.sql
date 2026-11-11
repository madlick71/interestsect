-- interestsect: Softwareentwicklung & Programmiersprachen (technik-digital)
--
-- Quellen (recherchiert 2026-11):
--   * TIOBE Index Nov 2026 (Python, C, Java, C++, C#, JavaScript, R, SQL,
--     Go, Rust; Dart neu in den Top 20, Julia & Assembly ebenfalls)
--   * Stack Overflow Developer Survey 2025 (Python #1, JavaScript,
--     TypeScript, Bash, SQL; Antriebsfächer AI/Data Science)
--
-- Idempotent: mehrfaches Ausführen ist sicher (ON CONFLICT DO NOTHING).

insert into public.interests (category_id, slug, name_de, keywords)
select c.id, v.slug, v.name_de, v.keywords
from (values
  -- Grundbegriffe
  ('technik-digital','programmieren','Programmieren',array['code','lernen']),
  ('technik-digital','softwareentwicklung','Softwareentwicklung',array['projekte','engineering']),

  -- Programmiersprachen (TIOBE / SO Survey)
  ('technik-digital','python','Python',array['skripte','data science']),
  ('technik-digital','javascript','JavaScript',array['web','frontend']),
  ('technik-digital','typescript','TypeScript',array['typen','web']),
  ('technik-digital','java','Java',array['backend','jvm']),
  ('technik-digital','csharp','C#',array['.net','unity']),
  ('technik-digital','cpp','C++',array['leistung','spiele']),
  ('technik-digital','c-sprache','C (Programmiersprache)',array['systeme','pointer']),
  ('technik-digital','golang','Go (Programmiersprache)',array['cloud','einfach']),
  ('technik-digital','php','PHP',array['web','wordpress']),
  ('technik-digital','swift','Swift (iOS)',array['apple','apps']),
  ('technik-digital','kotlin','Kotlin (Android)',array['android','jvm']),
  ('technik-digital','dart-flutter','Dart & Flutter',array['apps','cross-plattform']),
  ('technik-digital','ruby','Ruby',array['rails','skripte']),
  ('technik-digital','lua','Lua',array['spiele','scripts']),
  ('technik-digital','r-statistik','R (Statistik)',array['auswertung','plots']),
  ('technik-digital','sql-datenbanken','SQL & Datenbanken',array['abfragen','joins']),
  ('technik-digital','bash-shell','Bash & Shell-Skripte',array['automatisierung','terminal']),
  ('technik-digital','haskell','Haskell',array['funktional','typen']),
  ('technik-digital','lisp-clojure','Lisp & Clojure',array['klammern','funktional']),
  ('technik-digital','julia','Julia (Programmiersprache)',array['zahlen','wissenschaft']),
  ('technik-digital','assembler','Assembler',array['register','bits']),
  ('technik-digital','vba-excel','VBA & Excel-Makros',array['excel','makros']),
  ('technik-digital','scratch-kinder','Scratch (mit Kindern)',array['blöcke','familie']),

  -- Bereiche & Anwendungen
  ('technik-digital','app-entwicklung','Mobile App-Entwicklung',array['apps','smartphone']),
  ('technik-digital','backend-apis','Backend & API-Entwicklung',array['server','schnittstellen']),
  ('technik-digital','data-science','Data Science & Machine Learning',array['modelle','daten']),
  ('technik-digital','discord-bots','Discord- & Telegram-Bots',array['api','chatbots']),
  ('technik-digital','wordpress-webseiten','WordPress & eigene Webseiten',array['cms','blog']),
  ('technik-digital','datenvisualisierung','Datenvisualisierung',array['charts','grafiken'])
) as v(cat, slug, name_de, keywords)
join public.interest_categories c on c.slug = v.cat
on conflict (slug) do nothing;
