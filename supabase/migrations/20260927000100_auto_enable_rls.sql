-- Keep future public tables secure by default. Policies still need to be
-- created explicitly before authenticated clients can access a new table.
create or replace function public.rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  command record;
begin
  for command in
    select *
    from pg_event_trigger_ddl_commands()
    where command_tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      and object_type in ('table', 'partitioned table')
  loop
    if command.schema_name is not null
      and command.schema_name in ('public')
      and command.schema_name not in ('pg_catalog', 'information_schema')
      and command.schema_name not like 'pg_toast%'
      and command.schema_name not like 'pg_temp%'
    then
      begin
        execute format(
          'alter table if exists %s enable row level security',
          command.object_identity
        );
        raise log 'rls_auto_enable: enabled RLS on %', command.object_identity;
      exception
        when others then
          raise log
            'rls_auto_enable: failed to enable RLS on %',
            command.object_identity;
      end;
    else
      raise log
        'rls_auto_enable: skip % (system schema or not in enforced list: %)',
        command.object_identity,
        command.schema_name;
    end if;
  end loop;
end;
$$;

drop event trigger if exists ensure_rls;
create event trigger ensure_rls
on ddl_command_end
when tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
execute function public.rls_auto_enable();
