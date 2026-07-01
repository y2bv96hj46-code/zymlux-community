-- ============================================================
--  ZYMLUX TREND — Base de données de l'outil de veille e-commerce
--  À coller dans : Supabase > SQL Editor > New query > Run
--  Idempotent : tu peux le relancer sans risque.
-- ============================================================

-- ---------- BOUTIQUES ESPIONNÉES ----------
create table if not exists public.tt_stores (
  id              uuid primary key default gen_random_uuid(),
  domain          text unique not null,          -- ex: gymshark.com (sans https://)
  name            text,
  active          boolean not null default true,
  source          text default 'manuel',         -- 'seed' | 'manuel' | 'auto'
  note            text,
  product_count   int not null default 0,
  last_scanned_at timestamptz,
  last_error      text,
  created_at      timestamptz not null default now()
);

-- ---------- PRODUITS ----------
create table if not exists public.tt_products (
  id             uuid primary key default gen_random_uuid(),
  store_id       uuid not null references public.tt_stores(id) on delete cascade,
  shopify_id     bigint not null,
  handle         text,
  title          text not null,
  product_type   text,
  vendor         text,
  image          text,
  price          numeric,
  compare_at     numeric,          -- prix barré (permet de calculer la promo)
  variants_count int default 0,
  available      boolean default true,
  published_at   timestamptz,      -- date de mise en ligne côté boutique
  position       int,              -- rang dans le catalogue (signal best-seller)
  first_seen     timestamptz not null default now(),
  last_seen      timestamptz not null default now(),
  unique (store_id, shopify_id)
);
create index if not exists tt_products_store_idx    on public.tt_products (store_id);
create index if not exists tt_products_firstseen_idx on public.tt_products (first_seen desc);
create index if not exists tt_products_type_idx      on public.tt_products (product_type);

-- ---------- HISTORIQUE (pour les courbes de tendance) ----------
create table if not exists public.tt_snapshots (
  id                 bigserial primary key,
  product_id         uuid not null references public.tt_products(id) on delete cascade,
  ts                 timestamptz not null default now(),
  price              numeric,
  available_variants int,
  position           int
);
create index if not exists tt_snapshots_product_idx on public.tt_snapshots (product_id, ts);

-- ---------- MOTS-CLÉS À SURVEILLER (pubs) ----------
create table if not exists public.tt_keywords (
  id        uuid primary key default gen_random_uuid(),
  keyword   text not null,
  country   text not null default 'FR',
  active    boolean not null default true,
  created_at timestamptz not null default now(),
  unique (keyword, country)
);

-- ---------- PUBLICITÉS (Meta Ad Library) ----------
create table if not exists public.tt_ads (
  id           uuid primary key default gen_random_uuid(),
  archive_id   text unique,       -- ad_archive_id de Meta
  keyword      text,
  country      text,
  page_name    text,
  snapshot_url text,
  platforms    text,
  started      date,
  seen_at      timestamptz not null default now()
);
create index if not exists tt_ads_seen_idx on public.tt_ads (seen_at desc);

-- ============================================================
--  SÉCURITÉ (RLS)
--  Lecture publique (l'interface lit avec la clé anon).
--  Écriture des produits/pubs : faite par le robot (service_role,
--  qui contourne RLS). Le public peut seulement gérer la liste
--  des boutiques et mots-clés à surveiller.
-- ============================================================
alter table public.tt_stores    enable row level security;
alter table public.tt_products  enable row level security;
alter table public.tt_snapshots enable row level security;
alter table public.tt_keywords  enable row level security;
alter table public.tt_ads       enable row level security;

-- lecture pour tous
drop policy if exists tt_read_stores    on public.tt_stores;
drop policy if exists tt_read_products  on public.tt_products;
drop policy if exists tt_read_snapshots on public.tt_snapshots;
drop policy if exists tt_read_keywords  on public.tt_keywords;
drop policy if exists tt_read_ads       on public.tt_ads;
create policy tt_read_stores    on public.tt_stores    for select using (true);
create policy tt_read_products  on public.tt_products  for select using (true);
create policy tt_read_snapshots on public.tt_snapshots for select using (true);
create policy tt_read_keywords  on public.tt_keywords  for select using (true);
create policy tt_read_ads       on public.tt_ads       for select using (true);

-- ajout/gestion des boutiques et mots-clés depuis l'interface
drop policy if exists tt_write_stores   on public.tt_stores;
drop policy if exists tt_update_stores  on public.tt_stores;
drop policy if exists tt_write_keywords on public.tt_keywords;
create policy tt_write_stores   on public.tt_stores   for insert with check (true);
create policy tt_update_stores  on public.tt_stores   for update using (true) with check (true);
create policy tt_write_keywords on public.tt_keywords for insert with check (true);

-- ============================================================
--  LISTE DE DÉPART (boutiques Shopify connues, à titre d'amorce)
--  Tu ajouteras TES concurrents ensuite depuis l'interface.
-- ============================================================
insert into public.tt_stores (domain, name, source) values
  ('gymshark.com',            'Gymshark',            'seed'),
  ('fashionnova.com',         'Fashion Nova',        'seed'),
  ('colourpop.com',           'ColourPop',           'seed'),
  ('kyliecosmetics.com',      'Kylie Cosmetics',     'seed'),
  ('ruggable.com',            'Ruggable',            'seed'),
  ('mvmt.com',                'MVMT',                'seed'),
  ('puravidabracelets.com',   'Pura Vida',           'seed'),
  ('deathwishcoffee.com',     'Death Wish Coffee',   'seed'),
  ('chubbiesshorts.com',      'Chubbies',            'seed'),
  ('brooklinen.com',          'Brooklinen',          'seed'),
  ('allbirds.com',            'Allbirds',            'seed'),
  ('studs.com',               'Studs',               'seed')
on conflict (domain) do nothing;

insert into public.tt_keywords (keyword, country) values
  ('coussin',   'FR'),
  ('lampe',     'FR'),
  ('massage',   'FR'),
  ('chat',      'FR')
on conflict (keyword, country) do nothing;

-- ============================================================
--  (OPTIONNEL) PLANIFICATION AUTOMATIQUE avec pg_cron + pg_net
--  Décommente après avoir déployé les Edge Functions.
--  Remplace <PROJECT_REF> et <SERVICE_ROLE_KEY>.
-- ============================================================
-- create extension if not exists pg_cron;
-- create extension if not exists pg_net;
--
-- select cron.schedule('tt-scan-stores', '0 */6 * * *', $$
--   select net.http_post(
--     url    := 'https://<PROJECT_REF>.functions.supabase.co/tt-scan',
--     headers:= '{"Authorization":"Bearer <SERVICE_ROLE_KEY>","Content-Type":"application/json"}'::jsonb,
--     body   := '{}'::jsonb
--   );
-- $$);
--
-- select cron.schedule('tt-scan-ads', '30 */12 * * *', $$
--   select net.http_post(
--     url    := 'https://<PROJECT_REF>.functions.supabase.co/tt-ads',
--     headers:= '{"Authorization":"Bearer <SERVICE_ROLE_KEY>","Content-Type":"application/json"}'::jsonb,
--     body   := '{}'::jsonb
--   );
-- $$);
