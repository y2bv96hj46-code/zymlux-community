-- ============================================================
--  ZYMLUX — Stockage des médias de publications (photos + vidéos)
--  À lancer UNE FOIS dans le SQL Editor. Idempotent.
--  Corrige le blocage des vidéos > 5 Mo et borne les types/poids
--  côté serveur (sécurité, anti-abus).
-- ============================================================

-- Bucket dédié aux médias du fil : 30 Mo, images + vidéos uniquement
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-media', 'post-media', true, 31457280,
  array['image/jpeg','image/png','image/jpg','image/gif','image/webp','image/heic','image/heif',
        'video/mp4','video/webm','video/quicktime','video/ogg']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Resserrer le bucket avatars : images uniquement (anti-upload de fichiers arbitraires)
update storage.buckets
set file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/jpg','image/gif','image/webp','image/heic','image/heif']
where id = 'avatars';

-- Règles d'accès au bucket post-media (lecture publique ; écriture/suppression dans son propre dossier)
drop policy if exists "postmedia_public_read" on storage.objects;
create policy "postmedia_public_read" on storage.objects
  for select to public
  using (bucket_id = 'post-media');

drop policy if exists "postmedia_insert_own" on storage.objects;
create policy "postmedia_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'post-media' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "postmedia_update_own" on storage.objects;
create policy "postmedia_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'post-media' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "postmedia_delete_own" on storage.objects;
create policy "postmedia_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'post-media' and (storage.foldername(name))[1] = auth.uid()::text);
