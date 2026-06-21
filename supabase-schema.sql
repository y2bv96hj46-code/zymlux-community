-- ============================================================
--  ZYMLUX COMMUNITY — Schéma de base de données (Supabase)
--  À coller dans : Supabase > SQL Editor > New query > Run
--  Tu peux le relancer sans risque (il est idempotent).
-- ============================================================

-- ---------- PROFILS ----------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  pseudo       text not null default 'Membre',
  is_anonymous boolean not null default true,
  avatar_emoji text not null default '🌙',
  created_at   timestamptz not null default now()
);

-- ---------- SALONS DE CHAT ----------
create table if not exists public.rooms (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  name        text not null,
  description text,
  emoji       text default '💬',
  sort        int default 0,
  created_at  timestamptz not null default now()
);

-- ---------- MESSAGES ----------
create table if not exists public.messages (
  id         uuid primary key default gen_random_uuid(),
  room_id    uuid not null references public.rooms(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  content    text not null check (char_length(content) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists messages_room_created_idx on public.messages (room_id, created_at);

-- ---------- DÉFIS DE LA SEMAINE ----------
create table if not exists public.challenges (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  is_active   boolean not null default false,
  created_at  timestamptz not null default now()
);

create table if not exists public.challenge_completions (
  id           uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  completed_at timestamptz not null default now(),
  unique (challenge_id, user_id)
);

-- ---------- FICHE DE ROUTE (objectifs perso) ----------
create table if not exists public.roadmap_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null check (char_length(title) between 1 and 200),
  done       boolean not null default false,
  position   int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists roadmap_user_idx on public.roadmap_items (user_id, position);

-- ---------- ÉVOLUTION (humeur quotidienne) ----------
create table if not exists public.mood_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  score      int not null check (score between 1 and 5),
  note       text,
  created_at timestamptz not null default now()
);
create index if not exists mood_user_idx on public.mood_logs (user_id, created_at);

-- ============================================================
--  CRÉATION AUTOMATIQUE DU PROFIL À L'INSCRIPTION
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, pseudo, is_anonymous)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'pseudo',''), 'Membre'),
    coalesce((new.raw_user_meta_data->>'is_anonymous')::boolean, true)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
--  SÉCURITÉ : Row Level Security (RLS)
-- ============================================================
alter table public.profiles              enable row level security;
alter table public.rooms                 enable row level security;
alter table public.messages              enable row level security;
alter table public.challenges            enable row level security;
alter table public.challenge_completions enable row level security;
alter table public.roadmap_items         enable row level security;
alter table public.mood_logs             enable row level security;

-- Profils : visibles par les membres connectés ; on ne modifie que le sien
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select to authenticated using (true);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (auth.uid() = id);

-- Salons : lecture pour les membres connectés
drop policy if exists "rooms_select" on public.rooms;
create policy "rooms_select" on public.rooms for select to authenticated using (true);

-- Messages : lecture pour tous les membres ; écriture/suppression de ses propres messages
drop policy if exists "messages_select" on public.messages;
create policy "messages_select" on public.messages for select to authenticated using (true);
drop policy if exists "messages_insert_own" on public.messages;
create policy "messages_insert_own" on public.messages for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "messages_delete_own" on public.messages;
create policy "messages_delete_own" on public.messages for delete to authenticated using (auth.uid() = user_id);

-- Défis : lecture pour tous
drop policy if exists "challenges_select" on public.challenges;
create policy "challenges_select" on public.challenges for select to authenticated using (true);

-- Complétions de défi : chacun gère les siennes
drop policy if exists "completions_select_own" on public.challenge_completions;
create policy "completions_select_own" on public.challenge_completions for select to authenticated using (auth.uid() = user_id);
drop policy if exists "completions_insert_own" on public.challenge_completions;
create policy "completions_insert_own" on public.challenge_completions for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "completions_delete_own" on public.challenge_completions;
create policy "completions_delete_own" on public.challenge_completions for delete to authenticated using (auth.uid() = user_id);

-- Fiche de route : 100 % privée à chacun
drop policy if exists "roadmap_all_own" on public.roadmap_items;
create policy "roadmap_all_own" on public.roadmap_items for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Humeur : 100 % privée à chacun
drop policy if exists "mood_all_own" on public.mood_logs;
create policy "mood_all_own" on public.mood_logs for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
--  TEMPS RÉEL (active la diffusion live)
-- ============================================================
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.messages'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.mood_logs'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.roadmap_items'; exception when others then null; end;
end $$;

-- ============================================================
--  DONNÉES DE DÉPART (salons + 1 défi actif)
-- ============================================================
insert into public.rooms (slug, name, description, emoji, sort) values
  ('accueil',     'Accueil',            'Présente-toi, dis bonjour, prends tes marques.', '👋', 1),
  ('nuit',        'Insomnie & nuit',    'Pour les heures sans sommeil.',                  '🌙', 2),
  ('anxiete',     'Anxiété',            'Parler de ce qui serre, sans jugement.',         '🫧', 3),
  ('victoires',   'Petites victoires',  'Célébrer chaque pas, même minuscule.',           '✨', 4),
  ('entraide',    'Entraide',           'Demander, offrir, se soutenir.',                 '🤝', 5)
on conflict (slug) do nothing;

insert into public.challenges (title, description, is_active)
select 'Trois respirations conscientes',
       'Cette semaine : pose-toi une fois par jour pour faire trois respirations lentes et profondes. Rien de plus. Juste trois.',
       true
where not exists (select 1 from public.challenges where is_active = true);
