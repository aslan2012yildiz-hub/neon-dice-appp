-- NEON DICE starter schema. Run only in your own Supabase project after review.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  telegram_id bigint not null unique,
  username text,
  display_name text not null default 'Игрок NEON',
  balance bigint not null default 1000 check (balance >= 0),
  referred_by bigint references public.profiles(telegram_id),
  referral_earned bigint not null default 0 check (referral_earned >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint no_self_referral check (referred_by is null or referred_by <> telegram_id)
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  telegram_id bigint not null references public.profiles(telegram_id) on delete cascade,
  item_code text not null,
  item_name text not null,
  rarity text not null default 'Обычный',
  created_at timestamptz not null default now()
);

create table if not exists public.ledger (
  id uuid primary key default gen_random_uuid(),
  telegram_id bigint not null references public.profiles(telegram_id) on delete cascade,
  operation text not null check (operation in ('daily_bonus','game_result','case_open','referral_bonus','admin_adjustment')),
  delta bigint not null,
  balance_after bigint not null check (balance_after >= 0),
  idempotency_key text unique,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists inventory_items_user_idx on public.inventory_items(telegram_id, created_at desc);
create index if not exists ledger_user_idx on public.ledger(telegram_id, created_at desc);

-- No client-side writes: mutations should be performed only by a trusted server/Edge Function.
alter table public.profiles enable row level security;
alter table public.inventory_items enable row level security;
alter table public.ledger enable row level security;

-- No public policies are intentionally created. Add narrowly scoped policies only if you
-- implement a verified auth flow that maps the authenticated identity to telegram_id.
-- Never expose service_role keys in GitHub Pages or browser JavaScript.
