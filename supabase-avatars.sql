-- ============================================================
--  ZYMLUX — Photos de profil (à lancer UNE FOIS dans Supabase)
--  SQL Editor > New query > coller > Run
--  Idempotent : tu peux le relancer sans risque.
-- ============================================================

-- 1) Colonne pour l'URL de la photo de profil
alter table public.profiles add column if not exists avatar_url text;

-- 2) Bucket de stockage public "avatars"
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Limite de taille (2 Mo) + types d'images autorisés
update storage.buckets
set file_size_limit = 2097152,
    allowed_mime_types = array['image/png','image/jpeg','image/jpg','image/gif','image/webp']
where id = 'avatars';

-- 3) Règles d'accès au stockage
--    Lecture publique des avatars
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read" on storage.objects
  for select to public
  using (bucket_id = 'avatars');

--    Chacun gère uniquement SON dossier (préfixe = son identifiant)
drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
