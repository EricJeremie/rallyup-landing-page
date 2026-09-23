begin;

alter table public.profiles
  add column player_strengths text[] not null default '{}',
  add constraint profiles_player_strengths_max_six
    check (cardinality(player_strengths) <= 6),
  add constraint profiles_player_strengths_no_nulls
    check (array_position(player_strengths, null::text) is null),
  add constraint profiles_player_strengths_allowed
    check (
      player_strengths <@ array[
        'forehand',
        'backhand',
        'serve',
        'volley',
        'footwork',
        'consistency'
      ]::text[]
    );

comment on column public.profiles.player_strengths is
  'The player-selected tennis skills they consider strengths.';

grant update (player_strengths) on public.profiles to authenticated;

commit;
