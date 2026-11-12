-- interest_suggestions: FKs von auth.users auf public.profiles umstellen.
--
-- Grund: auth.users liegt außerhalb der über die Data API exponierten
-- Schemas, PostgREST kann daher keinen Embed `profiles!...` auflösen.
-- profiles.id ist identisch mit auth.users.id (Trigger legt die Zeile an
-- und kaskadiert), die Werte ändern sich also nicht.

alter table public.interest_suggestions
  drop constraint if exists interest_suggestions_suggested_by_fkey;
alter table public.interest_suggestions
  add constraint interest_suggestions_suggested_by_fkey
  foreign key (suggested_by) references public.profiles(id) on delete cascade;

alter table public.interest_suggestions
  drop constraint if exists interest_suggestions_decided_by_fkey;
alter table public.interest_suggestions
  add constraint interest_suggestions_decided_by_fkey
  foreign key (decided_by) references public.profiles(id) on delete set null;
