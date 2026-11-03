abstract final class FeatureFlags {
  // Temporarily hide the whole support section; its code/assets stay intact.
  // Re-enable with --dart-define=SHOW_PETANI_SUPPORT_SECTION=true.
  static const showPetaniSupportSection = bool.fromEnvironment(
    'SHOW_PETANI_SUPPORT_SECTION',
    defaultValue: true,
  );
}
