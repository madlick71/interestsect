-- "Musik machen": Wort "spielen" aus Instrumenten-Namen entfernen
-- (Kontext macht es überflüssig — es geht ums Instrument spielen).
-- Idempotent: Bedingung prüft den alten Namen.

update public.interests set name_de = 'Klavier'
where slug = 'klavier' and name_de = 'Klavierspielen';

update public.interests set name_de = 'Kirchenorgel'
where slug = 'orgel' and name_de = 'Kirchenorgel spielen';
