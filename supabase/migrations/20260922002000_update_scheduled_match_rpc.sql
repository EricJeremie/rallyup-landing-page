begin;

create or replace function public.update_scheduled_match(
  p_match_id uuid,
  p_court_id uuid,
  p_scheduled_at timestamptz,
  p_match_type public.match_type,
  p_match_format public.match_format,
  p_opponent_ids uuid[],
  p_teammate_id uuid default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_match public.matches%rowtype;
  v_ids uuid[];
  v_index integer;
begin
  if v_actor is null then raise exception using errcode = '28000', message = 'Authentication required'; end if;
  select m.* into v_match from public.matches m where m.id = p_match_id for update;
  if not found or v_match.status <> 'scheduled' or v_match.created_by <> v_actor then
    raise exception using errcode = '42501', message = 'Match cannot be edited by this user';
  end if;
  if p_scheduled_at <= now() then raise exception using errcode = '22023', message = 'Match time must be in the future'; end if;
  if not exists (select 1 from public.courts c where c.id = p_court_id and c.is_active) then raise exception using errcode = '23503', message = 'Court is unavailable'; end if;
  if p_match_type = 'singles' and (p_teammate_id is not null or cardinality(p_opponent_ids) <> 1) then raise exception using errcode = '22023', message = 'Invalid singles lineup'; end if;
  if p_match_type = 'doubles' and (p_teammate_id is null or cardinality(p_opponent_ids) <> 2) then raise exception using errcode = '22023', message = 'Invalid doubles lineup'; end if;
  v_ids := p_opponent_ids;
  if p_teammate_id is not null then v_ids := array_append(v_ids, p_teammate_id); end if;
  if v_actor = any(v_ids) or (select count(distinct value) from unnest(v_ids) as ids(value)) <> cardinality(v_ids) then
    raise exception using errcode = '22023', message = 'Players must be distinct';
  end if;
  if exists (select 1 from public.profiles p where p.user_id = any(v_ids) and not p.is_discoverable) then
    raise exception using errcode = '23503', message = 'One or more players are unavailable';
  end if;
  update public.matches set court_id = p_court_id, scheduled_at = p_scheduled_at, match_type = p_match_type, match_format = p_match_format, note = p_note, updated_at = now() where id = p_match_id;
  delete from public.match_participants where match_id = p_match_id and player_id <> v_actor;
  if p_teammate_id is not null then
    insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
    values (p_match_id, v_actor, p_teammate_id, 'side_one', 2, 'accepted');
  end if;
  for v_index in 1..cardinality(p_opponent_ids) loop
    insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
    values (p_match_id, v_actor, p_opponent_ids[v_index], 'side_two', v_index, 'accepted');
  end loop;
end;
$$;

revoke all on function public.update_scheduled_match(uuid, uuid, timestamptz, public.match_type, public.match_format, uuid[], uuid, text) from public, anon;
grant execute on function public.update_scheduled_match(uuid, uuid, timestamptz, public.match_type, public.match_format, uuid[], uuid, text) to authenticated;

commit;
