create table if not exists public.user_data_snapshots (
  user_id uuid primary key references auth.users (id) on delete cascade,
  snapshot jsonb not null default '{"schema_version":1,"tables":{}}'::jsonb,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table public.user_data_snapshots enable row level security;

revoke all on table public.user_data_snapshots from anon;
grant select, insert, update, delete
  on table public.user_data_snapshots
  to authenticated;

drop policy if exists "Users can read their own snapshot"
  on public.user_data_snapshots;
create policy "Users can read their own snapshot"
  on public.user_data_snapshots
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own snapshot"
  on public.user_data_snapshots;
create policy "Users can insert their own snapshot"
  on public.user_data_snapshots
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own snapshot"
  on public.user_data_snapshots;
create policy "Users can update their own snapshot"
  on public.user_data_snapshots
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own snapshot"
  on public.user_data_snapshots;
create policy "Users can delete their own snapshot"
  on public.user_data_snapshots
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.set_snapshot_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_data_snapshots_updated_at
  on public.user_data_snapshots;
create trigger set_user_data_snapshots_updated_at
before update on public.user_data_snapshots
for each row execute function public.set_snapshot_updated_at();
