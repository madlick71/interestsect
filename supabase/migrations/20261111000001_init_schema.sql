-- interestsect: initiales Datenmodell
-- Tabellen, RLS-Policies, Trigger und Match-RPC

-- =====================================================================
-- 1) PROFILE — öffentliches Profil (keine Bildergalerien, keine Likes)
-- =====================================================================
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  bio          text,
  region       text,
  search_region text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index profiles_region_idx on public.profiles (region);

-- =====================================================================
-- 2) INTERESSEN-TAXONOMIE (kuratiert, sehr spezifisch)
-- =====================================================================
create table public.interest_categories (
  id         uuid primary key default gen_random_uuid(),
  slug       text unique not null,
  name_de    text not null,
  name_en    text,
  sort_order int not null default 0
);

create table public.interests (
  id          uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.interest_categories(id) on delete cascade,
  slug        text unique not null,
  name_de     text not null,
  keywords    text[] not null default '{}',
  created_at  timestamptz not null default now()
);

create index interests_category_idx on public.interests (category_id);
create index interests_keywords_idx on public.interests using gin (keywords);

create table public.user_interests (
  user_id    uuid not null references auth.users(id) on delete cascade,
  interest_id uuid not null references public.interests(id) on delete cascade,
  level      smallint not null default 3 check (level between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (user_id, interest_id)
);

create index user_interests_interest_idx on public.user_interests (interest_id);

-- =====================================================================
-- 3) KONTAKTANFRAGEN (statt Likes/Newsfeed)
-- =====================================================================
create table public.contact_requests (
  id         uuid primary key default gen_random_uuid(),
  sender_id   uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  message    text,
  status     text not null default 'pending'
             check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (sender_id, receiver_id),
  check (sender_id <> receiver_id)
);

-- =====================================================================
-- 4) EVENTS — reale Treffen
-- =====================================================================
create table public.events (
  id             uuid primary key default gen_random_uuid(),
  creator_id     uuid not null references auth.users(id) on delete cascade,
  title          text not null,
  description    text,
  location_name  text,
  lat            double precision,
  lng            double precision,
  starts_at      timestamptz not null,
  max_participants int not null default 2 check (max_participants between 2 and 50),
  created_at     timestamptz not null default now()
);

create index events_starts_at_idx on public.events (starts_at);

create table public.event_participants (
  event_id  uuid not null references public.events(id) on delete cascade,
  user_id   uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- =====================================================================
-- 5) SUBSCRIPTIONS — 30 Tage Trial, danach 1 €/Monat
--    Geschrieben ausschließlich vom Stripe-Webhook (Service Role)
-- =====================================================================
create table public.subscriptions (
  user_id                uuid primary key references auth.users(id) on delete cascade,
  stripe_customer_id     text unique,
  stripe_subscription_id text unique,
  status                 text not null default 'none'
                         check (status in ('none', 'trialing', 'active', 'past_due', 'canceled')),
  trial_end              timestamptz,
  current_period_end     timestamptz,
  updated_at             timestamptz not null default now()
);

-- =====================================================================
-- 6) TRIGGER: neuer Auth-User -> Profil + 30-Tage-Trial
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      split_part(new.email, '@', 1)
    )
  );
  insert into public.subscriptions (user_id, status, trial_end)
  values (new.id, 'trialing', now() + interval '30 days');
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- =====================================================================
-- 7) ENTITLEMENT-HELPER: Trial aktiv ODER aktives Abo
-- =====================================================================
create or replace function public.has_active_entitlement()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.subscriptions
    where user_id = auth.uid()
      and (
        (status = 'trialing' and trial_end > now())
        or (status = 'active' and current_period_end > now())
      )
  );
$$;

revoke all on function public.has_active_entitlement() from public;
grant execute on function public.has_active_entitlement() to authenticated;

-- =====================================================================
-- 8) MATCH-RPC: gemeinsame Interessen als Basis der Kontaktaufnahme
-- =====================================================================
create or replace function public.find_matches(
  min_common int default 2,
  match_region text default null,
  max_results int default 20
)
returns table (
  user_id uuid,
  display_name text,
  region text,
  bio text,
  common_interests bigint,
  shared_interests text[]
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id,
         p.display_name,
         p.region,
         p.bio,
         count(*) as common_interests,
         array_agg(i.name_de order by i.name_de) as shared_interests
  from public.user_interests mine
  join public.user_interests theirs
    on theirs.interest_id = mine.interest_id
  join public.profiles p
    on p.id = theirs.user_id
  join public.interests i
    on i.id = theirs.interest_id
  where mine.user_id = auth.uid()
    and theirs.user_id <> auth.uid()
    and (match_region is null or p.region = match_region)
  group by p.id, p.display_name, p.region, p.bio
  having count(*) >= min_common
  order by common_interests desc, p.display_name
  limit max_results;
$$;

revoke all on function public.find_matches(int, text, int) from public;
grant execute on function public.find_matches(int, text, int) to authenticated;

-- =====================================================================
-- 9) ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.interest_categories enable row level security;
alter table public.interests enable row level security;
alter table public.user_interests enable row level security;
alter table public.contact_requests enable row level security;
alter table public.events enable row level security;
alter table public.event_participants enable row level security;
alter table public.subscriptions enable row level security;

-- Profile: öffentlich lesbar (soziales Netzwerk), nur eigenes schreibbar
create policy "profiles: select für angemeldete"
  on public.profiles for select to authenticated using (true);
create policy "profiles: eigenes anlegen"
  on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles: eigenes ändern"
  on public.profiles for update to authenticated using (auth.uid() = id);

-- Taxonomie: nur lesbar, Pflege über Seeds/Service Role
create policy "categories: select für angemeldete"
  on public.interest_categories for select to authenticated using (true);
create policy "interests: select für angemeldete"
  on public.interests for select to authenticated using (true);

-- Eigene Interessen sehen/bearbeiten; fremde nur über die Match-RPC
create policy "user_interests: eigene lesen"
  on public.user_interests for select to authenticated
  using (auth.uid() = user_id);
create policy "user_interests: eigene anlegen"
  on public.user_interests for insert to authenticated
  with check (auth.uid() = user_id);
create policy "user_interests: eigene ändern"
  on public.user_interests for update to authenticated
  using (auth.uid() = user_id);
create policy "user_interests: eigene löschen"
  on public.user_interests for delete to authenticated
  using (auth.uid() = user_id);

-- Kontaktanfragen: nur sender und receiver sehen; receiver entscheidet
create policy "contact_requests: beteiligte lesen"
  on public.contact_requests for select to authenticated
  using (auth.uid() in (sender_id, receiver_id));
create policy "contact_requests: selbst senden"
  on public.contact_requests for insert to authenticated
  with check (auth.uid() = sender_id);
create policy "contact_requests: empfangene bearbeiten"
  on public.contact_requests for update to authenticated
  using (auth.uid() = receiver_id);

-- Events: lesbar für alle, angelegt vom Ersteller
create policy "events: select für angemeldete"
  on public.events for select to authenticated using (true);
create policy "events: eigene anlegen"
  on public.events for insert to authenticated
  with check (auth.uid() = creator_id);
create policy "events: eigene ändern"
  on public.events for update to authenticated using (auth.uid() = creator_id);

create policy "event_participants: select für angemeldete"
  on public.event_participants for select to authenticated using (true);
create policy "event_participants: selbst beitreten"
  on public.event_participants for insert to authenticated
  with check (auth.uid() = user_id);

-- Subscriptions: nur eigene lesen, NIEMALS clientseitig schreiben
create policy "subscriptions: eigene lesen"
  on public.subscriptions for select to authenticated
  using (auth.uid() = user_id);
