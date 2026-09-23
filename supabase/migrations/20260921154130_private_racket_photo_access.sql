update storage.buckets
set public = false
where id = 'racket-photos';

drop policy if exists "Racket photos can be listed by their owner" on storage.objects;

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
          and name = any(profile.racket_photo_paths)
      )
    )
  );
