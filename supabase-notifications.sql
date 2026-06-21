-- ============================================================
--  ZYMLUX — Notifications (à lancer UNE FOIS dans le SQL Editor)
--  SQL Editor > New query > coller > Run.  Idempotent.
--  Crée la table des notifications, les déclencheurs (j'aime,
--  commentaire, message privé), les fonctions, la sécurité (RLS)
--  et le temps réel.
-- ============================================================

-- ---------- TABLE ----------
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,  -- destinataire
  actor_id   uuid references public.profiles(id) on delete set null,          -- qui a déclenché (peut être nul)
  type       text not null,            -- 'like' | 'comment' | 'dm' | 'level' | 'daily' | 'system'
  body       text not null,
  link       text,                     -- vue cible : 'feed' | 'dm' | 'dash'
  post_id    uuid,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications (user_id) where read = false;

-- ---------- SÉCURITÉ (RLS) ----------
-- Chaque membre voit / met à jour / supprime SES notifications.
-- L'insertion n'est PAS ouverte aux membres : elle passe uniquement par
-- les fonctions SECURITY DEFINER ci-dessous (déclencheurs + notify_self).
alter table public.notifications enable row level security;

drop policy if exists notif_select_own on public.notifications;
create policy notif_select_own on public.notifications
  for select to authenticated using (user_id = auth.uid());

drop policy if exists notif_update_own on public.notifications;
create policy notif_update_own on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists notif_delete_own on public.notifications;
create policy notif_delete_own on public.notifications
  for delete to authenticated using (user_id = auth.uid());

-- ---------- FONCTION D'AJOUT (centralisée, sûre) ----------
create or replace function public.add_notification(
  p_user uuid, p_actor uuid, p_type text, p_body text, p_link text, p_post uuid
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_user is null then return; end if;
  -- jamais de notification à soi-même
  if p_actor is not null and p_actor = p_user then return; end if;
  insert into public.notifications (user_id, actor_id, type, body, link, post_id)
  values (p_user, p_actor, p_type, p_body, p_link, p_post);
end $$;

-- IMPORTANT (sécurité) : Postgres accorde EXECUTE à PUBLIC par défaut. Sans ce
-- retrait, n'importe quel membre pourrait appeler add_notification() en direct
-- et envoyer/forger des notifications à n'importe qui. On le réserve donc aux
-- déclencheurs (qui s'exécutent en tant que propriétaire, indépendamment de ce droit).
revoke execute on function public.add_notification(uuid, uuid, text, text, text, uuid) from public;
revoke all    on function public.add_notification(uuid, uuid, text, text, text, uuid) from authenticated, anon;

-- Notification déclenchée par le membre lui-même (montée de niveau, rappel du jour)
create or replace function public.notify_self(p_type text, p_body text, p_link text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return; end if;
  insert into public.notifications (user_id, actor_id, type, body, link)
  values (auth.uid(), auth.uid(), p_type, p_body, p_link);
end $$;

grant execute on function public.notify_self(text, text, text) to authenticated;

-- ---------- DÉCLENCHEURS ----------
-- J'aime sur une publication -> notifie l'auteur
create or replace function public.notify_on_like() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_name text;
begin
  select user_id into v_owner from public.posts where id = new.post_id;
  select pseudo  into v_name  from public.profiles where id = new.user_id;
  perform public.add_notification(
    v_owner, new.user_id, 'like',
    coalesce(v_name, 'Quelqu''un') || ' a aimé ta publication', 'feed', new.post_id);
  return new;
end $$;
drop trigger if exists trg_notify_like on public.post_likes;
create trigger trg_notify_like after insert on public.post_likes
  for each row execute function public.notify_on_like();
revoke all on function public.notify_on_like() from public, authenticated, anon;

-- Commentaire sur une publication -> notifie l'auteur
create or replace function public.notify_on_comment() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_name text;
begin
  select user_id into v_owner from public.posts where id = new.post_id;
  select pseudo  into v_name  from public.profiles where id = new.user_id;
  perform public.add_notification(
    v_owner, new.user_id, 'comment',
    coalesce(v_name, 'Quelqu''un') || ' a commenté ta publication', 'feed', new.post_id);
  return new;
end $$;
drop trigger if exists trg_notify_comment on public.post_comments;
create trigger trg_notify_comment after insert on public.post_comments
  for each row execute function public.notify_on_comment();
revoke all on function public.notify_on_comment() from public, authenticated, anon;

-- Message privé reçu -> notifie le destinataire (si la table dms existe)
do $$
begin
  if to_regclass('public.dms') is not null then
    create or replace function public.notify_on_dm() returns trigger
    language plpgsql security definer set search_path = public as $f$
    declare v_name text;
    begin
      select pseudo into v_name from public.profiles where id = new.sender_id;
      perform public.add_notification(
        new.recipient_id, new.sender_id, 'dm',
        coalesce(v_name, 'Quelqu''un') || ' t''a envoyé un message privé', 'dm', null);
      return new;
    end $f$;
    drop trigger if exists trg_notify_dm on public.dms;
    create trigger trg_notify_dm after insert on public.dms
      for each row execute function public.notify_on_dm();
    revoke all on function public.notify_on_dm() from public, authenticated, anon;
  end if;
end $$;

-- ---------- TEMPS RÉEL ----------
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.notifications'; exception when others then null; end;
end $$;
