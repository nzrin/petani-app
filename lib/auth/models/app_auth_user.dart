enum AppAuthProvider { apple, google, email, unknown }

class AppAuthUser {
  const AppAuthUser({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
    this.username,
    this.usernameIsGenerated = false,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? username;
  final bool usernameIsGenerated;
  final AppAuthProvider provider;

  bool get hasUsername => username?.trim().isNotEmpty ?? false;
}
