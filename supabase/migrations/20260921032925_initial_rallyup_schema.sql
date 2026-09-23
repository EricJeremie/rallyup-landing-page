begin;

create type public.skill_level as enum ('beginner', 'intermediate', 'advanced');
create type public.match_type as enum ('singles', 'doubles');
create type public.match_format as enum ('best_of_three', 'one_set', 'pro_set');
create type public.match_side as enum ('side_one', 'side_two');
create type public.match_status as enum (
  'invite_pending',
  'scheduled',
  'in_progress',
  'awaiting_confirmation',
  'completed',
  'cancelled',
  'disputed'
);
create type public.invite_response as enum ('pending', 'accepted', 'declined');
create type public.match_result_status as enum ('pending_confirmation', 'confirmed', 'disputed');

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 60),
  skill_level public.skill_level not null default 'intermediate',
  about text not null default '' check (char_length(about) <= 280),
  home_area text check (home_area is null or char_length(home_area) <= 100),
  availability_summary text not null default 'Availability not set' check (char_length(availability_summary) <= 120),
  is_discoverable boolean not null default true,
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.profiles.home_area is
  'Coarse user-selected area only; do not store exact device coordinates in public profiles.';

create index profiles_discovery_idx
  on public.profiles (skill_level, created_at desc)
  where is_discoverable;

create table public.courts (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  address text not null default '',
  area text not null default '',
  surface text not null default 'Hard',
  setting text not null default 'Outdoor',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  is_active boolean not null default true,
  source text not null default 'curated' check (source in ('curated', 'user_submitted')),
  created_at timestamptz not null default now()
);

create index courts_active_area_idx on public.courts (area, name) where is_active;

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(user_id) on delete cascade,
  court_id uuid not null references public.courts(id) on delete restrict,
  scheduled_at timestamptz not null,
  match_type public.match_type not null default 'singles',
  match_format public.match_format not null default 'best_of_three',
  status public.match_status not null default 'invite_pending',
  note text check (note is null or char_length(note) <= 500),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint matches_id_creator_unique unique (id, created_by)
);

create index matches_creator_status_schedule_idx
  on public.matches (created_by, status, scheduled_at desc);
create index matches_court_schedule_idx
  on public.matches (court_id, scheduled_at);
create index matches_status_schedule_idx
  on public.matches (status, scheduled_at);

create table public.match_participants (
  match_id uuid not null,
  created_by uuid not null,
  player_id uuid not null references public.profiles(user_id) on delete cascade,
  side public.match_side not null,
  team_slot smallint not null default 1 check (team_slot in (1, 2)),
  invite_response public.invite_response not null default 'pending',
  responded_at timestamptz,
  result_confirmed_at timestamptz,
  result_disputed_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (match_id, player_id),
  unique (match_id, side, team_slot),
  foreign key (match_id, created_by)
    references public.matches(id, created_by) on delete cascade,
  check (result_confirmed_at is null or result_disputed_at is null)
);

create index match_participants_player_idx on public.match_participants (player_id, invite_response, match_id);
create index match_participants_creator_idx on public.match_participants (created_by, match_id);

create table public.availability_slots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  timezone_name text not null default 'UTC',
  created_at timestamptz not null default now(),
  constraint availability_positive_duration check (ends_at > starts_at)
);

create index availability_slots_user_start_idx on public.availability_slots (user_id, starts_at);
create index availability_slots_start_end_idx on public.availability_slots (starts_at, ends_at);

create table public.match_live_scores (
  match_id uuid primary key references public.matches(id) on delete cascade,
  score_state jsonb not null default '{"completedSets":[],"games":[0,0],"points":[0,0],"isTiebreak":false,"winner":null}'::jsonb,
  revision bigint not null default 0 check (revision >= 0),
  updated_by uuid references public.profiles(user_id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint match_live_score_object check (jsonb_typeof(score_state) = 'object')
);

create index match_live_scores_updated_by_idx on public.match_live_scores (updated_by) where updated_by is not null;

create table public.match_results (
  match_id uuid primary key references public.matches(id) on delete cascade,
  submitted_by uuid not null references public.profiles(user_id) on delete cascade,
  winner_side public.match_side not null,
  status public.match_result_status not null default 'pending_confirmation',
  submitted_at timestamptz not null default now(),
  confirmed_at timestamptz
);

create index match_results_submitted_by_idx on public.match_results (submitted_by);

create table public.match_set_scores (
  match_id uuid not null references public.match_results(match_id) on delete cascade,
  set_number smallint not null check (set_number > 0),
  side_one_games smallint not null check (side_one_games between 0 and 10),
  side_two_games smallint not null check (side_two_games between 0 and 10),
  side_one_tiebreak_points smallint check (side_one_tiebreak_points is null or side_one_tiebreak_points >= 0),
  side_two_tiebreak_points smallint check (side_two_tiebreak_points is null or side_two_tiebreak_points >= 0),
  primary key (match_id, set_number),
  check (side_one_games <> side_two_games),
  check (
    (side_one_tiebreak_points is null and side_two_tiebreak_points is null)
    or (side_one_tiebreak_points is not null and side_two_tiebreak_points is not null)
  )
);

create table public.user_blocks (
  blocker_id uuid not null references public.profiles(user_id) on delete cascade,
  blocked_player_id uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_player_id),
  check (blocker_id <> blocked_player_id)
);

create index user_blocks_blocked_player_idx on public.user_blocks (blocked_player_id);

create table public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(user_id) on delete cascade,
  reported_player_id uuid not null references public.profiles(user_id) on delete cascade,
  match_id uuid references public.matches(id) on delete set null,
  reason text not null check (reason in ('harassment', 'unsafe_behavior', 'spam', 'fake_profile', 'other')),
  details text not null default '' check (char_length(details) <= 2000),
  created_at timestamptz not null default now(),
  check (reporter_id <> reported_player_id)
);

create index user_reports_reported_created_idx on public.user_reports (reported_player_id, created_at desc);
create index user_reports_reporter_created_idx on public.user_reports (reporter_id, created_at desc);
create index user_reports_match_idx on public.user_reports (match_id) where match_id is not null;

create table public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  device_token text not null unique,
  platform text not null default 'ios' check (platform = 'ios'),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index device_push_tokens_user_idx on public.device_push_tokens (user_id);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.touch_updated_at() from public, anon, authenticated;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger matches_touch_updated_at
  before update on public.matches
  for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.courts enable row level security;
alter table public.matches enable row level security;
alter table public.match_participants enable row level security;
alter table public.availability_slots enable row level security;
alter table public.match_live_scores enable row level security;
alter table public.match_results enable row level security;
alter table public.match_set_scores enable row level security;
alter table public.user_blocks enable row level security;
alter table public.user_reports enable row level security;
alter table public.device_push_tokens enable row level security;

create policy profiles_read_discoverable_or_self
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id or is_discoverable);
create policy profiles_insert_self
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy profiles_update_self
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy courts_read_active
  on public.courts for select to anon, authenticated
  using (is_active);

create policy matches_read_creator_or_participant
  on public.matches for select to authenticated
  using (
    created_by = (select auth.uid())
    or exists (
      select 1 from public.match_participants mp
      where mp.match_id = matches.id and mp.player_id = (select auth.uid())
    )
  );

create policy match_participants_read_self_or_inviter
  on public.match_participants for select to authenticated
  using (player_id = (select auth.uid()) or created_by = (select auth.uid()));

create policy availability_slots_owner_read
  on public.availability_slots for select to authenticated
  using (user_id = (select auth.uid()));
create policy availability_slots_owner_insert
  on public.availability_slots for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy availability_slots_owner_update
  on public.availability_slots for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy availability_slots_owner_delete
  on public.availability_slots for delete to authenticated
  using (user_id = (select auth.uid()));

create policy match_live_scores_read_participant
  on public.match_live_scores for select to authenticated
  using (
    exists (
      select 1 from public.match_participants mp
      where mp.match_id = match_live_scores.match_id and mp.player_id = (select auth.uid())
    )
  );
create policy match_results_read_participant
  on public.match_results for select to authenticated
  using (
    exists (
      select 1 from public.match_participants mp
      where mp.match_id = match_results.match_id and mp.player_id = (select auth.uid())
    )
  );
create policy match_set_scores_read_participant
  on public.match_set_scores for select to authenticated
  using (
    exists (
      select 1 from public.match_participants mp
      where mp.match_id = match_set_scores.match_id and mp.player_id = (select auth.uid())
    )
  );

create policy user_blocks_owner_read
  on public.user_blocks for select to authenticated
  using (blocker_id = (select auth.uid()));
create policy user_blocks_owner_insert
  on public.user_blocks for insert to authenticated
  with check (blocker_id = (select auth.uid()) and blocker_id <> blocked_player_id);
create policy user_blocks_owner_delete
  on public.user_blocks for delete to authenticated
  using (blocker_id = (select auth.uid()));

create policy user_reports_reporter_read
  on public.user_reports for select to authenticated
  using (reporter_id = (select auth.uid()));
create policy user_reports_reporter_insert
  on public.user_reports for insert to authenticated
  with check (reporter_id = (select auth.uid()) and reporter_id <> reported_player_id);

create policy device_push_tokens_owner_read
  on public.device_push_tokens for select to authenticated
  using (user_id = (select auth.uid()));
create policy device_push_tokens_owner_insert
  on public.device_push_tokens for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy device_push_tokens_owner_update
  on public.device_push_tokens for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy device_push_tokens_owner_delete
  on public.device_push_tokens for delete to authenticated
  using (user_id = (select auth.uid()));

alter publication supabase_realtime add table public.match_live_scores;

revoke all on table
  public.profiles,
  public.courts,
  public.matches,
  public.match_participants,
  public.availability_slots,
  public.match_live_scores,
  public.match_results,
  public.match_set_scores,
  public.user_blocks,
  public.user_reports,
  public.device_push_tokens
from public, anon, authenticated;

grant usage on schema public to anon, authenticated;
grant select on public.courts to anon, authenticated;
grant select, insert on public.profiles to authenticated;
grant update (display_name, skill_level, about, home_area, availability_summary, is_discoverable, avatar_path)
  on public.profiles to authenticated;
grant select on public.matches to authenticated;
grant select on public.match_participants to authenticated;
grant select on public.match_live_scores, public.match_results, public.match_set_scores to authenticated;
grant select, insert, update, delete on public.availability_slots to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;
grant select, insert on public.user_reports to authenticated;
grant select, insert, update, delete on public.device_push_tokens to authenticated;

create or replace function public.create_match_invite(
  p_court_id uuid,
  p_scheduled_at timestamptz,
  p_match_type public.match_type,
  p_match_format public.match_format,
  p_opponent_ids uuid[],
  p_teammate_id uuid default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_invitees uuid[];
  v_expected_opponents integer;
  v_visible_invitees integer;
  v_distinct_invitees integer;
  v_match_id uuid;
  v_index integer;
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  if p_scheduled_at <= now() then
    raise exception using errcode = '22023', message = 'Match time must be in the future';
  end if;
  if p_note is not null and char_length(p_note) > 500 then
    raise exception using errcode = '22023', message = 'Match note is too long';
  end if;
  if not exists (select 1 from public.courts c where c.id = p_court_id and c.is_active) then
    raise exception using errcode = '23503', message = 'Court is unavailable';
  end if;

  v_expected_opponents := case when p_match_type = 'singles' then 1 else 2 end;
  if p_opponent_ids is null or cardinality(p_opponent_ids) <> v_expected_opponents then
    raise exception using errcode = '22023', message = 'The number of opponents does not match the match type';
  end if;
  if (p_match_type = 'singles' and p_teammate_id is not null)
     or (p_match_type = 'doubles' and p_teammate_id is null) then
    raise exception using errcode = '22023', message = 'A teammate is required for doubles only';
  end if;

  v_invitees := p_opponent_ids;
  if p_teammate_id is not null then
    v_invitees := array_append(v_invitees, p_teammate_id);
  end if;
  if array_position(v_invitees, v_actor) is not null then
    raise exception using errcode = '22023', message = 'You cannot invite yourself';
  end if;
  select count(distinct invitee_id) into v_distinct_invitees
    from unnest(v_invitees) as invitees(invitee_id);
  if v_distinct_invitees <> cardinality(v_invitees) then
    raise exception using errcode = '22023', message = 'A player can only appear once in a match';
  end if;
  select count(*) into v_visible_invitees
    from public.profiles p
    where p.user_id = any(v_invitees) and p.is_discoverable;
  if v_visible_invitees <> cardinality(v_invitees) then
    raise exception using errcode = '23503', message = 'One or more invited profiles are unavailable';
  end if;
  if exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = v_actor and b.blocked_player_id = any(v_invitees))
       or (b.blocked_player_id = v_actor and b.blocker_id = any(v_invitees))
  ) then
    raise exception using errcode = '42501', message = 'This invitation cannot be sent';
  end if;

  insert into public.matches (created_by, court_id, scheduled_at, match_type, match_format, status, note)
  values (v_actor, p_court_id, p_scheduled_at, p_match_type, p_match_format, 'invite_pending', p_note)
  returning id into v_match_id;

  insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
  values (v_match_id, v_actor, v_actor, 'side_one', 1, 'accepted');

  if p_teammate_id is not null then
    insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
    values (v_match_id, v_actor, p_teammate_id, 'side_one', 2, 'pending');
  end if;

  for v_index in 1..cardinality(p_opponent_ids) loop
    insert into public.match_participants (match_id, created_by, player_id, side, team_slot, invite_response)
    values (v_match_id, v_actor, p_opponent_ids[v_index], 'side_two', v_index, 'pending');
  end loop;

  return v_match_id;
end;
$$;

create or replace function public.respond_to_match_invite(p_match_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_match_status public.match_status;
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;

  select m.status into v_match_status
    from public.matches m
    where m.id = p_match_id
    for update;
  if not found or v_match_status <> 'invite_pending' then
    raise exception using errcode = '42501', message = 'This invitation is no longer available';
  end if;

  update public.match_participants
    set invite_response = case when p_accept then 'accepted'::public.invite_response else 'declined'::public.invite_response end,
        responded_at = now()
    where match_id = p_match_id
      and player_id = v_actor
      and created_by <> v_actor
      and invite_response = 'pending';

  if not found then
    raise exception using errcode = '42501', message = 'No pending invite is available to respond to';
  end if;

  if not p_accept then
    update public.matches set status = 'cancelled', updated_at = now()
      where id = p_match_id and status = 'invite_pending';
  elsif not exists (
    select 1 from public.match_participants mp
    where mp.match_id = p_match_id and mp.invite_response = 'pending'
  ) then
    update public.matches set status = 'scheduled', updated_at = now()
      where id = p_match_id and status = 'invite_pending';
  end if;
end;
$$;

create or replace function public.cancel_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  update public.matches m
    set status = 'cancelled', updated_at = now()
    where m.id = p_match_id
      and m.status in ('invite_pending', 'scheduled')
      and exists (
        select 1 from public.match_participants mp
        where mp.match_id = m.id and mp.player_id = v_actor and mp.invite_response = 'accepted'
      );
  if not found then
    raise exception using errcode = '42501', message = 'Match cannot be cancelled by this user';
  end if;
end;
$$;

create or replace function public.start_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  update public.matches m
    set status = 'in_progress', started_at = now(), updated_at = now()
    where m.id = p_match_id
      and m.status = 'scheduled'
      and exists (
        select 1 from public.match_participants mp
        where mp.match_id = m.id and mp.player_id = v_actor and mp.invite_response = 'accepted'
      )
      and not exists (
        select 1 from public.match_participants mp
        where mp.match_id = m.id and mp.invite_response <> 'accepted'
      );
  if not found then
    raise exception using errcode = '42501', message = 'Match is not ready to start';
  end if;
  insert into public.match_live_scores (match_id, updated_by)
  values (p_match_id, v_actor)
  on conflict (match_id) do nothing;
end;
$$;

create or replace function public.save_live_score(
  p_match_id uuid,
  p_expected_revision bigint,
  p_score_state jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_revision bigint;
  v_index integer;
  v_set jsonb;
  v_value text;
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  if p_score_state is null or jsonb_typeof(p_score_state) <> 'object' then
    raise exception using errcode = '22023', message = 'Score state must be a JSON object';
  end if;
  if jsonb_typeof(p_score_state -> 'completedSets') is distinct from 'array'
     or jsonb_typeof(p_score_state -> 'games') is distinct from 'array'
     or jsonb_typeof(p_score_state -> 'points') is distinct from 'array'
     or jsonb_typeof(p_score_state -> 'isTiebreak') is distinct from 'boolean'
     or (jsonb_typeof(p_score_state -> 'winner') is distinct from 'number'
         and jsonb_typeof(p_score_state -> 'winner') is distinct from 'null') then
    raise exception using errcode = '22023', message = 'Score state has an invalid structure';
  end if;
  v_value := p_score_state ->> 'winner';
  if v_value is not null and v_value !~ '^[01]$' then
    raise exception using errcode = '22023', message = 'Score state contains an invalid winner';
  end if;
  if jsonb_array_length(p_score_state -> 'games') <> 2
     or jsonb_array_length(p_score_state -> 'points') <> 2
     or jsonb_array_length(p_score_state -> 'completedSets') > 5 then
    raise exception using errcode = '22023', message = 'Score state has an invalid array length';
  end if;
  for v_index in 0..1 loop
    v_value := p_score_state -> 'games' ->> v_index;
    if coalesce(v_value, '') !~ '^[0-9]{1,2}$' or v_value::integer > 10 then
      raise exception using errcode = '22023', message = 'Score state contains invalid game counts';
    end if;
    v_value := p_score_state -> 'points' ->> v_index;
    if coalesce(v_value, '') !~ '^[0-9]{1,3}$' then
      raise exception using errcode = '22023', message = 'Score state contains invalid point counts';
    end if;
  end loop;
  for v_set in select value from jsonb_array_elements(p_score_state -> 'completedSets') as set_rows(value) loop
    if jsonb_typeof(v_set) <> 'object'
       or coalesce(v_set ->> 'you', '') !~ '^[0-9]{1,2}$'
       or coalesce(v_set ->> 'opponent', '') !~ '^[0-9]{1,2}$'
       or jsonb_typeof(v_set -> 'tiebreak') is distinct from 'boolean'
       or (v_set ->> 'you')::integer > 10
       or (v_set ->> 'opponent')::integer > 10
       or (v_set ->> 'you')::integer = (v_set ->> 'opponent')::integer then
      raise exception using errcode = '22023', message = 'Score state contains an invalid completed set';
    end if;
  end loop;
  update public.match_live_scores s
    set score_state = p_score_state,
        revision = s.revision + 1,
        updated_by = v_actor,
        updated_at = now()
    from public.matches m
    where s.match_id = p_match_id
      and m.id = s.match_id
      and m.status = 'in_progress'
      and s.revision = p_expected_revision
      and exists (
        select 1 from public.match_participants mp
        where mp.match_id = m.id and mp.player_id = v_actor and mp.invite_response = 'accepted'
      )
    returning s.revision into v_revision;

  if v_revision is null then
    raise exception using errcode = '40001', message = 'Score changed or match is not active; refresh before retrying';
  end if;
  return v_revision;
end;
$$;

create or replace function public.submit_match_result(
  p_match_id uuid,
  p_winner_side public.match_side,
  p_sets jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_match public.matches%rowtype;
  v_set jsonb;
  v_index integer := 0;
  v_side_one integer;
  v_side_two integer;
  v_tb_one integer;
  v_tb_two integer;
  v_high_games integer;
  v_low_games integer;
  v_target integer;
  v_side_one_sets integer := 0;
  v_side_two_sets integer := 0;
  v_sets_to_win integer;
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  select m.* into v_match
    from public.matches m
    where m.id = p_match_id
      and m.status = 'in_progress'
      and exists (
        select 1 from public.match_participants mp
        where mp.match_id = m.id and mp.player_id = v_actor and mp.invite_response = 'accepted'
      )
    for update;
  if not found then
    raise exception using errcode = '42501', message = 'Match is not active for this user';
  end if;
  if p_sets is null or jsonb_typeof(p_sets) <> 'array' then
    raise exception using errcode = '22023', message = 'Set scores must be a JSON array';
  end if;

  v_sets_to_win := case when v_match.match_format = 'best_of_three' then 2 else 1 end;
  v_target := case when v_match.match_format = 'pro_set' then 8 else 6 end;
  if (v_match.match_format = 'best_of_three' and jsonb_array_length(p_sets) not between 2 and 3)
     or (v_match.match_format <> 'best_of_three' and jsonb_array_length(p_sets) <> 1) then
    raise exception using errcode = '22023', message = 'Set count does not match the selected format';
  end if;

  insert into public.match_results (match_id, submitted_by, winner_side, status)
  values (p_match_id, v_actor, p_winner_side, 'pending_confirmation');

  for v_set in select value from jsonb_array_elements(p_sets) as set_rows(value) loop
    v_index := v_index + 1;
    if coalesce(v_set ->> 'side_one_games', '') !~ '^[0-9]{1,2}$'
       or coalesce(v_set ->> 'side_two_games', '') !~ '^[0-9]{1,2}$' then
      raise exception using errcode = '22023', message = 'Set score contains invalid game counts';
    end if;
    v_side_one := (v_set ->> 'side_one_games')::integer;
    v_side_two := (v_set ->> 'side_two_games')::integer;
    if v_side_one > 10 or v_side_two > 10 or v_side_one = v_side_two then
      raise exception using errcode = '22023', message = 'Set score is not valid';
    end if;
    v_high_games := greatest(v_side_one, v_side_two);
    v_low_games := least(v_side_one, v_side_two);
    v_tb_one := nullif(v_set ->> 'side_one_tiebreak_points', '')::integer;
    v_tb_two := nullif(v_set ->> 'side_two_tiebreak_points', '')::integer;

    if v_high_games > v_target + 1 then
      raise exception using errcode = '22023', message = 'Set score exceeds the selected format';
    elsif v_high_games = v_target + 1 and v_low_games = v_target then
      if v_tb_one is null or v_tb_two is null or greatest(v_tb_one, v_tb_two) < 7 or abs(v_tb_one - v_tb_two) < 2 then
        raise exception using errcode = '22023', message = 'A tiebreak set needs a valid tiebreak score';
      end if;
    elsif v_high_games < v_target or v_high_games - v_low_games < 2 then
      raise exception using errcode = '22023', message = 'Set score is incomplete';
    elsif v_tb_one is not null or v_tb_two is not null then
      raise exception using errcode = '22023', message = 'Unexpected tiebreak score';
    end if;

    if v_side_one > v_side_two then v_side_one_sets := v_side_one_sets + 1;
    else v_side_two_sets := v_side_two_sets + 1;
    end if;

    insert into public.match_set_scores (
      match_id, set_number, side_one_games, side_two_games,
      side_one_tiebreak_points, side_two_tiebreak_points
    ) values (
      p_match_id, v_index, v_side_one, v_side_two,
      v_tb_one, v_tb_two
    );
  end loop;

  if (p_winner_side = 'side_one' and (v_side_one_sets < v_sets_to_win or v_side_two_sets >= v_sets_to_win))
     or (p_winner_side = 'side_two' and (v_side_two_sets < v_sets_to_win or v_side_one_sets >= v_sets_to_win)) then
    raise exception using errcode = '22023', message = 'Winner does not match the submitted set scores';
  end if;
  if not exists (
    select 1 from public.match_participants mp
    where mp.match_id = p_match_id and mp.side = p_winner_side and mp.invite_response = 'accepted'
  ) then
    raise exception using errcode = '22023', message = 'Winner side is not part of this match';
  end if;

  update public.match_participants
    set result_confirmed_at = now()
    where match_id = p_match_id and player_id = v_actor;
  update public.matches set status = 'awaiting_confirmation', updated_at = now() where id = p_match_id;
end;
$$;

create or replace function public.confirm_match_result(p_match_id uuid, p_accept boolean)
returns public.match_result_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_result public.match_results%rowtype;
  v_status public.match_result_status;
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  select r.* into v_result
    from public.match_results r
    join public.match_participants mp on mp.match_id = r.match_id
    where r.match_id = p_match_id
      and r.status = 'pending_confirmation'
      and mp.player_id = v_actor
      and mp.player_id <> r.submitted_by
      and mp.invite_response = 'accepted'
      and mp.result_confirmed_at is null
    for update of r;
  if not found then
    raise exception using errcode = '42501', message = 'No result is awaiting confirmation from this user';
  end if;

  if not p_accept then
    update public.match_participants set result_disputed_at = now()
      where match_id = p_match_id and player_id = v_actor;
    update public.match_results set status = 'disputed' where match_id = p_match_id;
    update public.matches set status = 'disputed', updated_at = now() where id = p_match_id;
    return 'disputed';
  end if;

  update public.match_participants set result_confirmed_at = now()
    where match_id = p_match_id and player_id = v_actor;
  if not exists (
    select 1 from public.match_participants mp
    where mp.match_id = p_match_id
      and mp.invite_response = 'accepted'
      and mp.player_id <> v_result.submitted_by
      and mp.result_confirmed_at is null
  ) then
    update public.match_results set status = 'confirmed', confirmed_at = now() where match_id = p_match_id;
    update public.matches set status = 'completed', completed_at = now(), updated_at = now() where id = p_match_id;
    v_status := 'confirmed';
  else
    v_status := 'pending_confirmation';
  end if;
  return v_status;
end;
$$;

revoke execute on function public.create_match_invite(uuid, timestamptz, public.match_type, public.match_format, uuid[], uuid, text) from public, anon;
revoke execute on function public.respond_to_match_invite(uuid, boolean) from public, anon;
revoke execute on function public.cancel_match(uuid) from public, anon;
revoke execute on function public.start_match(uuid) from public, anon;
revoke execute on function public.save_live_score(uuid, bigint, jsonb) from public, anon;
revoke execute on function public.submit_match_result(uuid, public.match_side, jsonb) from public, anon;
revoke execute on function public.confirm_match_result(uuid, boolean) from public, anon;
grant execute on function public.create_match_invite(uuid, timestamptz, public.match_type, public.match_format, uuid[], uuid, text) to authenticated;
grant execute on function public.respond_to_match_invite(uuid, boolean) to authenticated;
grant execute on function public.cancel_match(uuid) to authenticated;
grant execute on function public.start_match(uuid) to authenticated;
grant execute on function public.save_live_score(uuid, bigint, jsonb) to authenticated;
grant execute on function public.submit_match_result(uuid, public.match_side, jsonb) to authenticated;
grant execute on function public.confirm_match_result(uuid, boolean) to authenticated;

commit;
