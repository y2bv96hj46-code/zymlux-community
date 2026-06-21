-- ============================================================
--  ZYMLUX — Consentement & RGPD : conserver l'acceptation des CGU
--  et le choix « recevoir les nouvelles par e-mail ».
--  À lancer UNE FOIS dans le SQL Editor. Idempotent.
--
--  Sans ce script, le consentement coché à l'inscription n'est stocké
--  nulle part de récupérable — ce qui pose un problème légal (RGPD).
--  Ici on ajoute deux colonnes au profil et on met à jour le déclencheur
--  d'inscription pour les enregistrer.
-- ============================================================

alter table public.profiles add column if not exists marketing_consent boolean not null default false;
alter table public.profiles add column if not exists terms_accepted_at  timestamptz;

-- Recrée le déclencheur d'inscription pour capter aussi le consentement.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, pseudo, is_anonymous, marketing_consent, terms_accepted_at)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'pseudo',''), 'Membre'),
    coalesce((new.raw_user_meta_data->>'is_anonymous')::boolean, true),
    coalesce((new.raw_user_meta_data->>'marketing_consent')::boolean, false),
    nullif(new.raw_user_meta_data->>'terms_accepted_at','')::timestamptz
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
