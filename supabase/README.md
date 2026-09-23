# RallyUp Supabase backend

Hosted project: `RallyUp` (`gkxtyvdffyccjgblgpnd`) in `ap-southeast-1` under PocketDevs Org. It was created on the free tier. The iOS client uses its publishable key only; never add a service-role key to the app.

## Schema scope

- `profiles` stores discoverable profile fields, a coarse `home_area` (never a precise device coordinate), an optional `avatar_path`, and up to six selected `player_strengths`.
- `profile_rackets` stores up to three named rackets per player, with an optional photo path for each. A constrained position (`1...3`) and per-profile uniqueness enforce the cap in Postgres. Photos live in the private `racket-photos` bucket; owners can upload/manage their own files, and authenticated players can read signed URLs only for photos attached to discoverable profiles.
- Profile avatars live in the private `profile-photos` bucket and are readable only by their owner or authenticated players viewing a discoverable profile.
- `courts` stores the curated public court catalog for map pins.
- `availability_slots` is private to each account.
- `matches` and `match_participants` represent singles and doubles invites, acceptance, scheduling, and participants.
- `match_live_scores`, `match_results`, and `match_set_scores` store live state and submitted results. Participants can read these records; score changes go through revision-checked functions.
- `user_blocks`, `user_reports`, and `device_push_tokens` have owner-scoped RLS.

RLS is enabled on every public table. `profiles` only exposes rows marked discoverable (plus the caller's own row); the profile schema intentionally omits email and exact location. Courts are read-only for clients. Match creation, invite response, cancellation, score updates, result submission, and confirmation are handled by narrow authenticated Postgres functions. They use a fixed search path, check `auth.uid()`, and are not executable by `anon` or `PUBLIC`. The iOS app must use only a publishable key; never put a service-role key in the app.

`match_live_scores` is added to the `supabase_realtime` publication so authorized match participants can receive live score changes.

New iOS accounts use Supabase Auth. Email confirmation, password reset, recovery deep links, and account deletion are supported. If email verification is required, the device keeps a local onboarding draft (including profile photo, selected strengths, racket names, and racket photos) until the user verifies and signs in; profile data and photos are then uploaded. Player discovery, block/report actions, and availability filters are server-side in the launch-readiness migration. The iOS client registers APNs device tokens, and the `send-match-push` Edge Function sends invite/response pushes once the APNs secrets below are configured.

Configure these Supabase Function secrets before enabling production push delivery: `APNS_KEY_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, and `APNS_ENVIRONMENT` (`sandbox` or `production`).

## Local workflow and verification

`supabase/config.toml` and migrations were generated with Supabase CLI 2.117.0. The hosted project has the initial schema, private racket/profile photo storage policies, Auth profile-bootstrap trigger, named-racket table/policies, and allowed-value profile-strength constraints applied. Existing photo-only profile paths are migrated to placeholder names (`Racket 1`–`Racket 3`).

The migrations have not been reset/linted against a local PostgreSQL instance because Docker is not available. The hosted schema was verified through the Supabase project tools and security/performance advisors; existing advisor notices concern the original match RPCs, unused indexes, and an unindexed match foreign key, not the new profile-strength constraints or private photo policies. Racket and profile photos use private buckets and short-lived signed URLs; reads are limited to the owner or authenticated players viewing a discoverable profile.
