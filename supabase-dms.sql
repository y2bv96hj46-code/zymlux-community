-- ============================================================
--  ZYMLUX — Messages privés (DM) : table + sécurité (RLS) + temps réel
--  À lancer UNE FOIS dans le SQL Editor. Idempotent.
--
--  IMPORTANT : la messagerie privée est la donnée la plus sensible du
--  site. Ce script garantit que SEULS l'expéditeur et le destinataire
--  peuvent lire un message — la sécurité ne doit JAMAIS reposer sur le
--  code de l'appli (qui est public et contournable), mais sur ces règles.
--  Si la table existe déjà, "create table if not exists" ne la touche pas ;
--  on (re)pose simplement les bonnes règles de sécurité par-dessus.
-- ============================================================

create table if not exists public.dms (
  id           uuid primary key default gen_random_uuid(),
  sender_id    uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  content      text not null check (char_length(content) between 1 and 2000),
  created_at   timestamptz not null default now()
);
create index if not exists dms_recipient_idx on public.dms (recipient_id, created_at desc);
create index if not exists dms_pair_idx      on public.dms (sender_id, recipient_id, created_at);

-- ---------- SÉCURITÉ (RLS) ----------
alter table public.dms enable row level security;

-- Lecture : uniquement si tu es l'expéditeur OU le destinataire.
drop policy if exists dms_select_mine on public.dms;
create policy dms_select_mine on public.dms
  for select to authenticated
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

-- Écriture : uniquement en ton propre nom, et pas si tu es banni.
drop policy if exists dms_insert_own on public.dms;
create policy dms_insert_own on public.dms
  for insert to authenticated
  with check (auth.uid() = sender_id and not public.is_banned());

-- Suppression : seulement tes propres messages envoyés.
drop policy if exists dms_delete_own on public.dms;
create policy dms_delete_own on public.dms
  for delete to authenticated
  using (auth.uid() = sender_id);

-- Pas de policy UPDATE : un message privé n'est pas modifiable.

-- ---------- TEMPS RÉEL ----------
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.dms'; exception when others then null; end;
end $$;
