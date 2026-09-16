-- Dice Mobile Online: постоянный общий рейтинг игроков
-- Выполните этот файл в Supabase -> SQL Editor. Повторный запуск безопасен.

create table if not exists public.dice_player_leaderboard (
  player_id text primary key,
  nickname text not null default '',
  wins_total bigint not null default 0 check (wins_total >= 0),
  wins_bot bigint not null default 0 check (wins_bot >= 0),
  wins_online bigint not null default 0 check (wins_online >= 0),
  updated_at timestamptz not null default now()
);


-- Никнеймы должны быть уникальными без учёта регистра.
-- Пустой никнейм не резервируется и может быть у нескольких игроков.
create unique index if not exists dice_player_leaderboard_nickname_unique_idx
  on public.dice_player_leaderboard (lower(btrim(nickname)))
  where btrim(nickname) <> '';

create index if not exists dice_player_leaderboard_total_idx
  on public.dice_player_leaderboard (wins_total desc, updated_at asc);

create index if not exists dice_player_leaderboard_bot_idx
  on public.dice_player_leaderboard (wins_bot desc, updated_at asc);

create index if not exists dice_player_leaderboard_online_idx
  on public.dice_player_leaderboard (wins_online desc, updated_at asc);

alter table public.dice_player_leaderboard enable row level security;

drop policy if exists "dice_leaderboard_read" on public.dice_player_leaderboard;
create policy "dice_leaderboard_read"
on public.dice_player_leaderboard
for select
to anon, authenticated
using (true);

drop policy if exists "dice_leaderboard_insert" on public.dice_player_leaderboard;
create policy "dice_leaderboard_insert"
on public.dice_player_leaderboard
for insert
to anon, authenticated
with check (true);

drop policy if exists "dice_leaderboard_update" on public.dice_player_leaderboard;
create policy "dice_leaderboard_update"
on public.dice_player_leaderboard
for update
to anon, authenticated
using (true)
with check (true);

grant select, insert, update on table public.dice_player_leaderboard to anon, authenticated;

-- Для мгновенного обновления открытого топа пытаемся добавить таблицу
-- в публикацию Supabase Realtime. Если она уже добавлена, ничего не делаем.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'dice_player_leaderboard'
  ) then
    alter publication supabase_realtime add table public.dice_player_leaderboard;
  end if;
exception
  when insufficient_privilege then
    null;
end $$;
