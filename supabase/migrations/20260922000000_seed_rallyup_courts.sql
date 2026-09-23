begin;

insert into public.courts (id, name, address, area, surface, setting, latitude, longitude, source)
values
  ('10000000-0000-0000-0000-000000000001', 'BGC Tennis Club', 'Bonifacio Global City', 'Taguig', 'Hard', 'Outdoor', 14.5514, 121.0465, 'curated'),
  ('10000000-0000-0000-0000-000000000002', 'Makati Sports Club', 'Makati City', 'Makati', 'Hard', 'Indoor / Outdoor', 14.5590, 121.0196, 'curated'),
  ('10000000-0000-0000-0000-000000000003', 'PhilSports Tennis Courts', 'Pasig City', 'Pasig', 'Hard', 'Outdoor', 14.5720, 121.0640, 'curated')
on conflict (id) do update set
  name = excluded.name,
  address = excluded.address,
  area = excluded.area,
  surface = excluded.surface,
  setting = excluded.setting,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  source = excluded.source,
  is_active = true;

commit;
