-- interestsect: Execute-Rechte der Such-RPCs ergänzen
--
-- search_interests & interest_category_counts sind für authenticated
-- freigegeben (20261112151000). Serverseitige Aufrufe (Edge Functions /
-- Service-Rollen) brauchen service_role-Zugriff; interest_norm bleibt
-- interne Hilfsfunktion ohne eigene Grants.

grant execute on function public.search_interests(text, uuid, int, int) to service_role;
grant execute on function public.interest_category_counts() to service_role;
