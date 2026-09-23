create function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    user_id,
    display_name,
    skill_level,
    home_area,
    availability_summary
  )
  values (
    new.id,
    left(
      coalesce(
        nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
        nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
        'Player'
      ),
      60
    ),
    case new.raw_user_meta_data ->> 'skill_level'
      when 'beginner' then 'beginner'::public.skill_level
      when 'advanced' then 'advanced'::public.skill_level
      else 'intermediate'::public.skill_level
    end,
    left(nullif(btrim(new.raw_user_meta_data ->> 'home_area'), ''), 100),
    left(
      coalesce(
        nullif(btrim(new.raw_user_meta_data ->> 'availability_summary'), ''),
        'Availability not set'
      ),
      120
    )
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_auth_user_profile() from public, anon, authenticated;

create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_auth_user_profile();
