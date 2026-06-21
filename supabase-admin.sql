-- ============================================================
--  ZYMLUX — Administration (rôle chef, bannissement, XP bonus)
--  SQL Editor > New query > coller > Run.  Idempotent.
-- ============================================================

-- 1) Colonnes
alter table public.profiles add column if not exists is_admin  boolean not null default false;
alter table public.profiles add column if not exists is_banned boolean not null default false;
alter table public.profiles add column if not exists bonus_xp  integer not null default 0;

-- 2) Fonctions de contrôle (security definer = pas de récursion RLS)
create or replace function public.is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;
create or replace function public.is_banned() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select is_banned from public.profiles where id = auth.uid()), false);
$$;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_banned() to authenticated;

-- 3) Verrou : un membre normal ne peut PAS changer is_admin / is_banned / bonus_xp
create or replace function public.protect_profile_flags() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    new.is_admin  := old.is_admin;
    new.is_banned := old.is_banned;
    new.bonus_xp  := old.bonus_xp;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_protect_profile_flags on public.profiles;
create trigger trg_protect_profile_flags before update on public.profiles
  for each row execute function public.protect_profile_flags();

-- 4) L'admin peut modifier n'importe quel profil (bannir, offrir de l'XP)
drop policy if exists profiles_update_admin on public.profiles;
create policy profiles_update_admin on public.profiles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 5) L'admin peut supprimer n'importe quel contenu ; les bannis ne peuvent plus rien poster
drop policy if exists messages_delete_own on public.messages;
drop policy if exists messages_delete on public.messages;
create policy messages_delete on public.messages for delete to authenticated
  using (auth.uid() = user_id or public.is_admin());
drop policy if exists messages_insert_own on public.messages;
create policy messages_insert_own on public.messages for insert to authenticated
  with check (auth.uid() = user_id and not public.is_banned());

drop policy if exists posts_delete_own on public.posts;
drop policy if exists posts_delete on public.posts;
create policy posts_delete on public.posts for delete to authenticated
  using (auth.uid() = user_id or public.is_admin());
drop policy if exists posts_insert_own on public.posts;
create policy posts_insert_own on public.posts for insert to authenticated
  with check (auth.uid() = user_id and not public.is_banned());

drop policy if exists comments_delete_own on public.post_comments;
drop policy if exists comments_delete on public.post_comments;
create policy comments_delete on public.post_comments for delete to authenticated
  using (auth.uid() = user_id or public.is_admin());
drop policy if exists comments_insert_own on public.post_comments;
create policy comments_insert_own on public.post_comments for insert to authenticated
  with check (auth.uid() = user_id and not public.is_banned());

-- 6) Classement mis à jour (inclut l'XP bonus offert)
create or replace function public.leaderboard(lim int default 10)
returns table(id uuid, pseudo text, avatar_url text, xp bigint)
language sql security definer set search_path = public as $$
  select p.id, p.pseudo, p.avatar_url,
    (coalesce(m.c,0)*5 + coalesce(po.c,0)*15 + coalesce(co.c,0)*8 + coalesce(mo.c,0)*10
     + coalesce(ch.c,0)*25 + coalesce(rmd.c,0)*20 + coalesce(li.c,0)*2 + coalesce(re.c,0)*2
     + coalesce(p.bonus_xp,0))::bigint as xp
  from public.profiles p
  left join (select user_id, count(*) c from public.messages group by user_id) m on m.user_id = p.id
  left join (select user_id, count(*) c from public.posts group by user_id) po on po.user_id = p.id
  left join (select user_id, count(*) c from public.post_comments group by user_id) co on co.user_id = p.id
  left join (select user_id, count(*) c from public.mood_logs group by user_id) mo on mo.user_id = p.id
  left join (select user_id, count(*) c from public.challenge_completions group by user_id) ch on ch.user_id = p.id
  left join (select user_id, count(*) c from public.roadmap_items where done group by user_id) rmd on rmd.user_id = p.id
  left join (select user_id, count(*) c from public.post_likes group by user_id) li on li.user_id = p.id
  left join (select user_id, count(*) c from public.message_reactions group by user_id) re on re.user_id = p.id
  order by xp desc
  limit lim;
$$;
grant execute on function public.leaderboard(int) to authenticated;

-- 7) ⚠️ DEVENIR ADMIN : remplace l'email par le tien, puis exécute cette ligne
update public.profiles set is_admin = true
where id = (select id from auth.users where email = 'TON_EMAIL@exemple.com');
