-- Runes beta telemetry schema.
-- Run this once in the Supabase SQL editor (Dashboard > SQL Editor > New query).
-- The game inserts with the anon key. The local dashboard reads with the SAME anon
-- (or publishable) key: Supabase now blocks secret/service_role keys in browsers, so
-- read access is granted via the anon_select_* RLS policies below instead.
--
-- Tradeoff: the anon key ships inside the game build, so anyone who extracts it can
-- read this data. That is acceptable here — it is anonymous gameplay telemetry for a
-- private balancing beta, no personal data. If you ever need reads locked down, drop
-- the anon_select_* policies and pull snapshots with a server-side script (curl + the
-- secret key) instead of the browser.

-- ============ runs: one row per run ============
create table public.runs (
  run_id         uuid primary key,              -- client-generated
  player_id      uuid not null,                 -- anonymous installation id
  client_version text not null default 'dev',
  seed           bigint,
  outcome        text not null check (outcome in ('loss','win','abandoned')),
  final_level    int not null,
  rounds_played  int not null default 0,
  best_round_score bigint not null default 0,
  total_score    bigint not null default 0,
  duration_msec  bigint,
  started_at     timestamptz,
  ended_at       timestamptz,
  -- Curated summary: { rounds: [{level, score, target, victory, duration_msec}],
  --                    economy: {earned, spent, final_money, spend_by_source},
  --                    upgrades: [{from, to}], final_loadout: ["type:item_id"] }
  summary        jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);
create index runs_version_idx on public.runs (client_version);
create index runs_player_idx  on public.runs (player_id);

-- ============ run_items: one row per item per run ============
create table public.run_items (
  id             bigint generated always as identity primary key,
  run_id         uuid not null,   -- no FK: tolerate partial uploads from flaky clients
  player_id      uuid not null,
  client_version text,
  item_type      text not null check (item_type in ('rune','relic','slot_piece','slot_modifier')),
  item_id        text not null,
  times_offered  int not null default 0,
  times_bought   int not null default 0,
  times_acquired int not null default 0,  -- includes free picks / rewards / starting items
  times_sold     int not null default 0,
  times_upgraded_into int not null default 0,
  activations    int not null default 0,
  score_contribution bigint not null default 0,
  in_final_loadout boolean not null default false,
  -- denormalized so per-item analytics never need a join (anon cannot UPDATE,
  -- and items upload once at run end when the outcome is already known)
  run_outcome    text,
  run_final_level int
);
create index run_items_item_idx on public.run_items (item_type, item_id);
create index run_items_run_idx  on public.run_items (run_id);

-- ============ RLS: anon key can INSERT (game) and SELECT (dashboard) ============
alter table public.runs      enable row level security;
alter table public.run_items enable row level security;

create policy anon_insert_runs      on public.runs      for insert to anon with check (true);
create policy anon_insert_run_items on public.run_items for insert to anon with check (true);

-- Dashboard reads with the anon key (secret keys are blocked in browsers).
create policy anon_select_runs      on public.runs      for select to anon using (true);
create policy anon_select_run_items on public.run_items for select to anon using (true);
-- Still no UPDATE/DELETE for anon => rows are append-only from the client's side.
