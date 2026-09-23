begin;

create table public.profile_rackets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  position smallint not null check (position between 1 and 3),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  photo_path text check (
    photo_path is null
    or (
      char_length(photo_path) <= 200
      and split_part(photo_path, '/', 1) = user_id::text
    )
  ),
  created_at timestamptz not null default now(),
  unique (user_id, position)
);

comment on table public.profile_rackets is
  'Up to three named rackets per player profile; photos are optional and stored privately.';

create index profile_rackets_photo_path_idx
  on public.profile_rackets (user_id, photo_path)
  where photo_path is not null;

alter table public.profile_rackets enable row level security;

grant select, insert, update, delete on public.profile_rackets to authenticated;

create policy profile_rackets_read_owner_or_discoverable
  on public.profile_rackets for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1
      from public.profiles as profile
      where profile.user_id = profile_rackets.user_id
        and profile.is_discoverable
    )
  );

create policy profile_rackets_insert_owner
  on public.profile_rackets for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy profile_rackets_update_owner
  on public.profile_rackets for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy profile_rackets_delete_owner
  on public.profile_rackets for delete to authenticated
  using (user_id = (select auth.uid()));

insert into public.profile_rackets (user_id, position, name, photo_path)
select
  profile.user_id,
  legacy.position::smallint,
  'Racket ' || legacy.position::text,
  legacy.photo_path
from public.profiles as profile
cross join lateral unnest(profile.racket_photo_paths) with ordinality as legacy(photo_path, position)
on conflict (user_id, position) do nothing;

drop policy if exists "Racket photos are visible to owners and discoverable players" on storage.objects;

create policy "Racket photos are visible to owners and discoverable players"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'racket-photos'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or exists (
        select 1
        from public.profiles as profile
        where profile.user_id::text = (storage.foldername(name))[1]
          and profile.is_discoverable
          and (
            name = any(profile.racket_photo_paths)
            or exists (
              select 1
              from public.profile_rackets as racket
              where racket.user_id = profile.user_id
                and racket.photo_path = storage.objects.name
            )
          )
      )
    )
  );

commit;
