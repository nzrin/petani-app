# Supabase setup for Petani

Petani remains local-first. Project, plot, plant and task writes go only to
SQLite. A full user snapshot is compared with Supabase when an authenticated
user opens/resumes the app and periodically every three days while the app is
running.

## 1. Configure the Flutter build

Production URLs and keys are not embedded in the committed Flutter config.
Copy `config/supabase.example.json` to `config/supabase.local.json` (ignored
by Git), then replace both placeholders with the URL and publishable key
from your Supabase project's **Connect** panel.

Run or build the application with:

```sh
flutter run --dart-define-from-file=config/supabase.local.json
flutter build appbundle --release --dart-define-from-file=config/supabase.local.json
flutter build ipa --release --dart-define-from-file=config/supabase.local.json
```

Never place a secret key or service-role key in the Flutter application.
The publishable key is included in the compiled app by design; it is not a
server secret. Access control still depends on authentication and RLS.
Without the build configuration, cloud authentication is unavailable.
For CI, create the same ignored JSON from the CI environment or supply the
two values with `--dart-define`. Do not commit the generated file.

## 2. Apply the cloud schema

Link the Supabase CLI to your project, then run:

```sh
supabase db push
supabase functions deploy delete-account
```

The migrations create `public.user_data_snapshots`, enable RLS and limit every
user to their own row. They also install the `ensure_rls` event trigger so new
tables in the `public` schema have RLS enabled automatically. Policies must
still be created explicitly before clients can access a new table. The
authenticated Edge Function performs account deletion without exposing the
service-role key to the app.

## 3. Configure Auth

In the Supabase dashboard:

1. Add `com.nazrinapp.petani://login-callback/` to **Auth > URL
   Configuration > Redirect URLs**.
2. Keep Email enabled and configure the confirmation-email template.
3. Enable Google and enter its web OAuth client ID and secret. Add the Supabase
   callback URL displayed by the provider page to Google Cloud.
4. Enable Apple and enter the Apple Services ID, Team ID, key ID and signing
   key. Apple OAuth signing secrets must be rotated before expiry.

Both iOS and Android manifests already register the Petani callback scheme.

On iOS, Google and Apple sign-in use `ASWebAuthenticationSession`, registered
in `ios/Runner/AppDelegate.swift`. Apple's authentication sheet handles
presentation, cancellation, and the return URL. Dart validates the callback
and exchanges its code through Supabase using PKCE. A cancelled session
returns to the sign-in screen without an error. Launch errors show a short
message rather than a raw platform exception or authentication URL.

Flutter's default deep-link routing is disabled in `ios/Runner/Info.plist`.
Supabase's `app_links` handler remains available for other auth links, such
as password reset. Email sign-in and registration use the Flutter forms.
Rebuild/relaunch the iOS app after native changes; hot reload is insufficient.

Before submitting an iOS build, test both providers on a device: complete
sign-in with new and returning accounts, cancel and retry,
and confirm the sheet closes after successful authentication. The initial
sign-in action must not switch to the standalone browser. Also check email
registration, confirmation, and sign-in.

### Automatic social usernames

Apple and Google users enter the app immediately after authentication. They
are never asked to re-enter a name, email or username. Missing usernames are
generated locally from the supplied account name (or email prefix), plus a
lossless base-36 encoding of the **full Supabase user UUID**. Using the full ID
keeps generated handles distinct even when people share the same name; this
is not a short random suffix. Existing usernames are preserved. The background
save first fetches the current server profile so a stale restored session does
not overwrite a username already saved on another device.

The generated handle is saved in `auth.users.raw_user_meta_data.username`
through the authenticated `updateUser` API, with `username_source: social_auto`.
No SQL migration or new backend function is required. Saving happens in the
background and a failure does not block access; the same local handle remains
usable and saving retries on a later sign-in, session restoration or token
refresh. Returning social accounts without a username are handled too.

Apple's name may be absent, especially with the web OAuth flow or on subsequent
sign-ins. A private-relay email is never used as a display name. With no usable
name or email prefix, the handle uses `petani` and the greeting uses
`Petani Moden`. The home screen shows the friendly supplied name, not the long
generated handle. Email/password registration keeps its existing username form.

These handles are labels, not security identifiers or a globally reserved
username directory. Metadata is user-editable; authorization and sync always
use `auth.uid()`. If public username lookup is added later, enforce reservation
and uniqueness in a server-owned table before using handles for lookups.

Release checks: test Apple **Hide My Email**, an Apple account with no returned
name, Google, an existing custom username, and sign-in while metadata saving
fails. None should show the old username screen or require another form.

## Sync conflict rule

If local and cloud data both changed since the previous sync, the snapshot
with the newest `client_updated_at` wins. A new device with no local farm data
downloads the cloud snapshot. Network failures never block SQLite operations;
the next launch, resume or three-day interval retries the comparison.
