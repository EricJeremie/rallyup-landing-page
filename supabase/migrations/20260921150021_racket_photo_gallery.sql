alter table public.profiles
  add column racket_photo_paths text[] not null default '{}',
  add constraint profiles_racket_photo_paths_max_three
    check (cardinality(racket_photo_paths) <= 3);

comment on column public.profiles.racket_photo_paths is
  'Storage object paths for up to three racket photos on a discoverable profile.';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('racket-photos', 'racket-photos', true, 6291456, array['image/jpeg'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Racket photos can be listed by their owner"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'racket-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Racket photos can be uploaded by their owner"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'racket-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Racket photos can be updated by their owner"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'racket-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'racket-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Racket photos can be deleted by their owner"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'racket-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
