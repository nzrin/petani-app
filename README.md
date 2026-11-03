# petani

A Flutter application for managing crops, plots and farm tasks.

## Repository setup

`web/` is maintained in a separate repository and is excluded from this app
repository. Local keys, signing files, environment files, IDE settings and
generated builds are also ignored.

Before running or building on a new machine:

1. Run `flutter pub get`.
2. Copy `config/supabase.example.json` to `config/supabase.local.json` and fill
   in your project's URL and publishable key.
3. For Android builds, copy `android/key.properties.example` to
   `android/key.properties` and set the real signing values locally. The
   existing Android build requires this file, including for debug builds.
4. Pass `--dart-define-from-file=config/supabase.local.json` to `flutter run`
   and every release build. Without it, cloud authentication is unavailable.

See [Supabase setup](docs/supabase_setup.md) for full run/build commands.
Keep `pubspec.lock`, platform lockfiles, migrations and example configs in
version control. Never use `git add -f` to include ignored credentials or
`web/`. Ignore rules do not remove files from existing Git history.

## App version

Update `APP_VERSION` and `APP_BUILD` in `app_version.xcconfig`, then rebuild the
app. iOS and Android use these values for their installed package metadata.
The profile's **Versi** row reads that metadata with `package_info_plus` and
displays `APP_VERSION (Binaan APP_BUILD)` automatically. Hot reload does not
update native package metadata; no manual edit to the profile text is needed.

## Temporarily hidden support section

“Dari Petani Kepada Petani” is hidden by default using
`FeatureFlags.showPetaniSupportSection` in
`lib/core/config/feature_flags.dart`. The profile conditionally renders the
whole section (heading, indicator, support card and its spacing). Its source,
assets and saved preferences are retained; nothing needs to be recreated.

To show it again for a run:

```sh
flutter run --dart-define=SHOW_PETANI_SUPPORT_SECTION=true
```

Use the same `--dart-define` on the Flutter build command to include it in a
future release, or change the flag's `defaultValue` to `true` to enable it by
default. Stop and relaunch/rebuild when changing the build flag; hot reload
does not change compile-time values.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
