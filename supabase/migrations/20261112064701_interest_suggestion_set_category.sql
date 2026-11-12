-- Admin darf die Kategorie eines offenen Vorschlags korrigieren
-- (z. B. wenn der Vorschlagende falsch einsortiert hat), bevor er
-- genehmigt wird. Genehmigte/abgelehnte Vorschläge sind nicht mehr
-- änderbar — die Interest übernimmt dann die korrigierte Kategorie.

create or replace function public.set_interest_suggestion_category(
  p_suggestion_id uuid,
  p_category_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.app_admins where user_id = auth.uid()) then
    raise exception 'Nur Admins dürfen Vorschläge bearbeiten';
  end if;

  if not exists (select 1 from public.interest_categories where id = p_category_id) then
    raise exception 'Kategorie nicht gefunden';
  end if;

  update public.interest_suggestions
  set category_id = p_category_id
  where id = p_suggestion_id and status = 'pending';

  if not found then
    raise exception 'Vorschlag nicht gefunden oder bereits entschieden';
  end if;
end;
$$;

revoke all on function public.set_interest_suggestion_category(uuid, uuid) from public;
grant execute on function public.set_interest_suggestion_category(uuid, uuid) to authenticated;
