-- ============================================================
--  ZYMLUX — Fil de publications + réactions (à lancer UNE FOIS)
--  SQL Editor > New query > coller > Run.  Idempotent.
-- ============================================================

-- ---------- PUBLICATIONS ----------
create table if not exists public.posts (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  content    text not null check (char_length(content) between 1 and 2000),
  image_url  text,
  created_at timestamptz not null default now()
);
create index if not exists posts_created_idx on public.posts (created_at desc);

-- ---------- J'AIME ----------
create table if not exists public.post_likes (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

-- ---------- COMMENTAIRES ----------
create table if not exists public.post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  content    text not null check (char_length(content) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists comments_post_idx on public.post_comments (post_id, created_at);

-- ---------- RÉACTIONS SUR MESSAGES DU CHAT ----------
create table if not exists public.message_reactions (
  id         uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  emoji      text not null,
  created_at timestamptz not null default now(),
  unique (message_id, user_id, emoji)
);
create index if not exists reactions_msg_idx on public.message_reactions (message_id);

-- ============================================================
--  SÉCURITÉ (RLS)
-- ============================================================
alter table public.posts             enable row level security;
alter table public.post_likes        enable row level security;
alter table public.post_comments     enable row level security;
alter table public.message_reactions enable row level security;

drop policy if exists posts_select on public.posts;
create policy posts_select on public.posts for select to authenticated using (true);
drop policy if exists posts_insert_own on public.posts;
create policy posts_insert_own on public.posts for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists posts_delete_own on public.posts;
create policy posts_delete_own on public.posts for delete to authenticated using (auth.uid() = user_id);

drop policy if exists likes_select on public.post_likes;
create policy likes_select on public.post_likes for select to authenticated using (true);
drop policy if exists likes_insert_own on public.post_likes;
create policy likes_insert_own on public.post_likes for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists likes_delete_own on public.post_likes;
create policy likes_delete_own on public.post_likes for delete to authenticated using (auth.uid() = user_id);

drop policy if exists comments_select on public.post_comments;
create policy comments_select on public.post_comments for select to authenticated using (true);
drop policy if exists comments_insert_own on public.post_comments;
create policy comments_insert_own on public.post_comments for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists comments_delete_own on public.post_comments;
create policy comments_delete_own on public.post_comments for delete to authenticated using (auth.uid() = user_id);

drop policy if exists reactions_select on public.message_reactions;
create policy reactions_select on public.message_reactions for select to authenticated using (true);
drop policy if exists reactions_insert_own on public.message_reactions;
create policy reactions_insert_own on public.message_reactions for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists reactions_delete_own on public.message_reactions;
create policy reactions_delete_own on public.message_reactions for delete to authenticated using (auth.uid() = user_id);

-- ============================================================
--  TEMPS RÉEL
-- ============================================================
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.posts'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.post_likes'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.post_comments'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.message_reactions'; exception when others then null; end;
end $$;
