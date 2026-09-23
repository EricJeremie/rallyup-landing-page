begin;

-- Keep player discovery on the server so client filters cannot bypass
-- discoverability, availability, or block rules.
create or replace function public.discover_profiles(
  p_search_query text default null,
  p_skill_level public.skill_level default null,
  p_area text default null,
  p_availability_terms text[] default '{}'
)
returns table (
  user_id uuid,
  display_name text,
  skill_level public.skill_level,
  home_area text,
  availability_summary text,
  avatar_path text,
  player_strengths text[]
)
language sql
security definer
set search_path = ''
as $$
  select
    p.user_id,
    p.display_name,
    p.skill_level,
    p.home_area,
    p.availability_summary,
    p.avatar_path,
    p.player_strengths
  from public.profiles p
  where (select auth.uid()) is not null
    and p.user_id <> (select auth.uid())
    and p.is_discoverable
    and (
      nullif(btrim(p_search_query), '') is null
      or p.display_name ilike '%' || btrim(p_search_query) || '%'
    )
    and (p_skill_level is null or p.skill_level = p_skill_level)
    and (
      nullif(btrim(p_area), '') is null
      or p.home_area ilike '%' || btrim(p_area) || '%'
    )
    and (
      coalesce(cardinality(p_availability_terms), 0) = 0
      or exists (
        select 1
        from unnest(p_availability_terms) as term
        where p.availability_summary ilike '%' || btrim(term) || '%'
      )
    )
    and not exists (
      select 1
      from public.user_blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_player_id = p.user_id)
         or (b.blocker_id = p.user_id and b.blocked_player_id = (select auth.uid()))
    )
  order by p.updated_at desc, p.display_name asc;
$$;

revoke all on function public.discover_profiles(text, public.skill_level, text, text[]) from public, anon;
grant execute on function public.discover_profiles(text, public.skill_level, text, text[]) to authenticated;

create or replace function public.block_player(p_player_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;
  if p_player_id = (select auth.uid()) then
    raise exception using errcode = '22023', message = 'You cannot block yourself';
  end if;

  insert into public.user_blocks (blocker_id, blocked_player_id)
  values ((select auth.uid()), p_player_id)
  on conflict (blocker_id, blocked_player_id) do nothing;
end;
$$;

revoke all on function public.block_player(uuid) from public, anon;
grant execute on function public.block_player(uuid) to authenticated;

create or replace function public.unblock_player(p_player_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  delete from public.user_blocks
  where blocker_id = (select auth.uid())
    and blocked_player_id = p_player_id;
$$;

revoke all on function public.unblock_player(uuid) from public, anon;
grant execute on function public.unblock_player(uuid) to authenticated;

create or replace function public.report_player(
  p_player_id uuid,
  p_reason text,
  p_details text default '',
  p_match_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_report_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;
  if p_player_id = (select auth.uid()) then
    raise exception using errcode = '22023', message = 'You cannot report yourself';
  end if;
  if p_match_id is not null and not exists (
    select 1
    from public.match_participants mp
    where mp.match_id = p_match_id
      and mp.player_id = (select auth.uid())
  ) then
    raise exception using errcode = '42501', message = 'You are not part of this match';
  end if;

  insert into public.user_reports (reporter_id, reported_player_id, match_id, reason, details)
  values (
    (select auth.uid()),
    p_player_id,
    p_match_id,
    p_reason,
    left(coalesce(p_details, ''), 2000)
  )
  returning id into v_report_id;

  return v_report_id;
end;
$$;

revoke all on function public.report_player(uuid, text, text, uuid) from public, anon;
grant execute on function public.report_player(uuid, text, text, uuid) to authenticated;

commit;
