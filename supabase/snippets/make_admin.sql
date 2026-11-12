-- Einen weiteren Admin eintragen (idempotent).
-- Ausführen mit: supabase db query --local -f supabase/snippets/make_admin.sql
-- (Cloud: supabase db query -f supabase/snippets/make_admin.sql)
-- Vorher E-Mail unten anpassen. Die User-ID findet man im Dashboard
-- unter Authentication → Users.

insert into public.app_admins (user_id)
select id from auth.users where email = 'email-hier-eintragen'
on conflict (user_id) do nothing;

-- Kontrolle:
-- select u.email, a.created_at
-- from public.app_admins a join auth.users u on u.id = a.user_id;
