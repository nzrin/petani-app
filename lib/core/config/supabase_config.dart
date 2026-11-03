abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const authRedirectUrl = 'com.nazrinapp.petani://login-callback/';

  static const emailConfirmationRedirectUrl =
      'https://petaniapp.nazrin.codes/confirmation';

  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;
}
