begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-photos', 'profile-photos', false, 6291456, array['image/jpeg'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Profile photos can be viewed by their owner or discoverable players"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'profile-photos'
    and (
      name = (select auth.uid())::text || '/profile.jpg'
      or exists (
        select 1
        from public.profiles as profile
        where profile.user_id::text = (storage.foldername(name))[1]
          and profile.is_discoverable
          and profile.avatar_path = storage.objects.name
      )
    )
  );

create policy "Profile photos can be uploaded by their owner"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-photos'
    and name = (select auth.uid())::text || '/profile.jpg'
  );

create policy "Profile photos can be updated by their owner"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'profile-photos'
    and name = (select auth.uid())::text || '/profile.jpg'
  )
  with check (
    bucket_id = 'profile-photos'
    and name = (select auth.uid())::text || '/profile.jpg'
  );

create policy "Profile photos can be deleted by their owner"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'profile-photos'
    and name = (select auth.uid())::text || '/profile.jpg'
  );

commit;
