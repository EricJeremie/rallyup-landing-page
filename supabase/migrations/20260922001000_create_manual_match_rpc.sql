begin;

create or replace function public.create_manual_match(
  p_court_id uuid,
  p_scheduled_at timestamptz,
  p_match_type public.match_type,
  p_match_format public.match_format,
  p_opponent_ids uuid[],
  p_teammate_id uuid default null,
  p_note text default null,
  p_start_immediately boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_match_id uuid;
  v_index integer;
  v_expected_opponents integer;
  v_participant_count integer;
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  if not exists (select 1 from public.courts c where c.id = p_court_id and c.is_active) then
    raise exception using errcode = '23503', message = 'Court is unavailable';
  end if;
  if not p_start_immediately and p_scheduled_at <= now() then
    raise exception using errcode = '22023', message = 'Match time must be in the future';
  end if;
  if p_note is not null and char_length(p_note) > 500 then
    raise exception using errcode = '22023', message = 'Match note is too long';
  end if;

  v_expected_opponents := case when p_match_type = 'singles' then 1 else 2 end;
  if p_opponent_ids is null or cardinality(p_opponent_ids) <> v_expected_opponents then
    raise exception using errcode = '22023', message = 'The number of opponents does not match the match type';
  end if;
  if (p_match_type = 'singles' and p_teammate_id is not null)
     or (p_match_type = 'doubles' and p_teammate_id is null) then
    raise exception using errcode = '22023', message = 'A teammate is required for doubles only';
  end if;
  if p_teammate_id = v_actor or v_actor = any(p_opponent_ids) then
    raise exception using errcode = '22023', message = 'You cannot add yourself twice';
  end if;
  select count(*) into v_participant_count
    from public.profiles p
    where p.user_id = any(array_append(p_opponent_ids, p_teammate_id));
  if v_participant_count <> cardinality(p_opponent_ids) + case when p_teammate_id is null then 0 else 1 end then
    raise exception using errcode = '23503', message = 'One or more players are unavailable';
  end if;

  insert into public.matches (created_by, court_id, scheduled_at, match_type, match_format, status, note, started_at)
  values (
    v_actor,
    p_court_id,
    case when p_start_immediately then now() else p_scheduled_at end,
    p_match_type,
    p_match_format,
    case when p_start_immediately then 'in_progress'::public.match_status else 'scheduled'::public.match_status end,
    p_note,
    case when p_start_immediately then now() else null end
  )
  returning id into v_match_id;

  insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
  values (v_match_id, v_actor, v_actor, 'side_one', 1, 'accepted');
  if p_teammate_id is not null then
    insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
    values (v_match_id, v_actor, p_teammate_id, 'side_one', 2, 'accepted');
  end if;
  for v_index in 1..cardinality(p_opponent_ids) loop
    insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
    values (v_match_id, v_actor, p_opponent_ids[v_index], 'side_two', v_index, 'accepted');
  end loop;
  if p_start_immediately then
    insert into public.match_live_scores (match_id, updated_by) values (v_match_id, v_actor);
  end if;
  return v_match_id;
end;
$$;

revoke all on function public.create_manual_match(uuid, timestamptz, public.match_type, public.match_format, uuid[], uuid, text, boolean) from public, anon;
grant execute on function public.create_manual_match(uuid, timestamptz, public.match_type, public.match_format, uuid[], uuid, text, boolean) to authenticated;

commit;
