import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:petani/auth/models/app_auth_user.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/auth/models/email_sign_up_data.dart';
import 'package:petani/auth/services/social_username.dart';
import 'package:petani/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SocialAuthProvider { apple, google }

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService implements Listenable {
  bool get isConfigured;

  AppAuthUser? get currentUser;

  bool get isAuthenticated;

  Future<bool> signUpWithEmail(EmailSignUpData data);

  Future<bool> signInWithEmail(EmailLoginData data);

  Future<void> signInWithProvider(SocialAuthProvider provider);

  Future<void> updateUsername(String username);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<void> deleteAccount();
}

class SupabaseAuthService extends ChangeNotifier implements AuthService {
  SupabaseAuthService._();

  @visibleForTesting
  SupabaseAuthService.withClient(SupabaseClient client) {
    _initialized = true;
    _attachClient(client);
  }

  static final SupabaseAuthService instance = SupabaseAuthService._();
  static const _iosAuthChannel = MethodChannel('com.nazrinapp.petani/web_auth');

  StreamSubscription<AuthState>? _authSubscription;
  SupabaseClient? _client;
  AppAuthUser? _currentUser;
  bool _initialized = false;
  bool _isStartingOAuth = false;
  bool _disposed = false;
  Future<void>? _usernameWrite;
  final _socialUsernames =
      <String, ({String username, bool generated, bool saved})>{};

  @override
  bool get isConfigured => SupabaseConfig.isConfigured;

  SupabaseClient? get client => _client;

  @override
  AppAuthUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!isConfigured) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        persistSession: true,
      ),
    );
    _attachClient(Supabase.instance.client);
  }

  void _attachClient(SupabaseClient client) {
    _client = client;
    _currentUser = _mapUser(client.auth.currentUser);
    _authSubscription = client.auth.onAuthStateChange.listen(
      (state) {
        final nextUser = _mapUser(state.session?.user);
        if (!_sameUser(_currentUser, nextUser)) {
          _currentUser = nextUser;
          notifyListeners();
        }
        if (state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed) {
          _scheduleSocialUsername();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        // Supabase also reports background refresh failures on this stream.
        debugPrint('Authentication callback failed; sign-in can be retried.');
      },
    );
    _scheduleSocialUsername();
  }

  void _scheduleSocialUsername() {
    final client = _client;
    final user = client?.auth.currentUser;
    if (_disposed ||
        _usernameWrite != null ||
        client == null ||
        user == null ||
        SocialUsername.stored(user) != null ||
        _socialUsernames[user.id]?.saved == true ||
        !_isSocialProvider(_provider(user))) {
      return;
    }
    final username =
        _socialUsernames[user.id]?.username ?? SocialUsername.generate(user);
    // Publish the usable local profile first. Metadata persistence must never
    // add an onboarding step or prevent a valid account from entering the app.
    final write = Future<void>(() async {
      if (_disposed || client.auth.currentUser?.id != user.id) return;
      if (SocialUsername.stored(client.auth.currentUser!) != null) return;
      try {
        // Restored tokens can contain stale metadata. Preserve a handle that
        // was already saved on another device instead of overwriting it.
        final freshUser = (await client.auth.getUser()).user;
        if (_disposed ||
            client.auth.currentUser?.id != user.id ||
            freshUser?.id != user.id) {
          return;
        }
        if (SocialUsername.stored(freshUser!) != null) {
          final nextUser = _mapUser(freshUser);
          if (!_sameUser(_currentUser, nextUser)) {
            _currentUser = nextUser;
            notifyListeners();
          }
          return;
        }
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'username': username,
              SocialUsername.sourceKey: SocialUsername.sourceValue,
            },
          ),
        );
      } on Object {
        // Keep the deterministic local handle and retry on the next sign-in,
        // restored session or token refresh. Do not expose account data/URLs.
        debugPrint('Automatic username could not be saved; will retry later.');
      }
    });
    _usernameWrite = write;
    unawaited(write.whenComplete(() => _usernameWrite = null));
  }

  @override
  Future<bool> signUpWithEmail(EmailSignUpData data) async {
    final client = _requireClient();
    await _usernameWrite;
    try {
      final response = await client.auth.signUp(
        email: data.email,
        password: data.password,
        data: {'username': data.username},
        emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
      );
      return response.user != null;
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    }
  }

  @override
  Future<bool> signInWithEmail(EmailLoginData data) async {
    final client = _requireClient();
    // GoTrue.updateUser updates its active session when the response arrives.
    // Finish an old metadata write before switching to another account.
    await _usernameWrite;
    try {
      final response = await client.auth.signInWithPassword(
        email: data.email,
        password: data.password,
      );
      return response.session != null;
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    }
  }

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {
    if (_isStartingOAuth) return;
    final client = _requireClient();
    final oauthProvider = switch (provider) {
      SocialAuthProvider.apple => OAuthProvider.apple,
      SocialAuthProvider.google => OAuthProvider.google,
    };
    _isStartingOAuth = true;
    try {
      await _usernameWrite;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _signInWithIOSSession(client, oauthProvider);
        return;
      }
      final launched = await client.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: kIsWeb ? null : SupabaseConfig.authRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthServiceException(
          'Halaman log masuk tidak dapat dibuka. Cuba lagi.',
        );
      }
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    } on PlatformException {
      throw const AuthServiceException(
        'Halaman log masuk tidak dapat dibuka. Semak sambungan internet '
        'dan cuba lagi.',
      );
    } on MissingPluginException {
      throw const AuthServiceException(
        'Log masuk belum tersedia. Tutup dan buka semula aplikasi, '
        'kemudian cuba lagi.',
      );
    } finally {
      _isStartingOAuth = false;
    }
  }

  Future<void> _signInWithIOSSession(
    SupabaseClient client,
    OAuthProvider provider,
  ) async {
    final response = await client.auth.getOAuthSignInUrl(
      provider: provider,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
    // ASWebAuthenticationSession owns presentation, cancellation and the
    // callback. Its Future completes only after the user finishes the flow.
    final callback = await _iosAuthChannel.invokeMethod<String>(
      'authenticate',
      {'url': response.url, 'callbackUrl': SupabaseConfig.authRedirectUrl},
    );
    if (callback == null) return; // The user tapped Cancel.

    final uri = Uri.tryParse(callback);
    final expected = Uri.parse(SupabaseConfig.authRedirectUrl);
    if (uri == null ||
        uri.scheme != expected.scheme ||
        uri.host != expected.host ||
        uri.path != expected.path) {
      throw const AuthServiceException(
        'Pautan log masuk tidak sah. Sila cuba lagi.',
      );
    }
    if (uri.queryParameters['error'] == 'access_denied') return;

    // Exchange the callback's code with the verifier generated by Supabase.
    // The native session consumes this callback, so app_links does not need
    // to exchange it a second time.
    await client.auth.getSessionFromUrl(uri);
  }

  @override
  Future<void> updateUsername(String username) async {
    final value = username.trim();
    if (value.length < 3 || value.length > 20) {
      throw const AuthServiceException(
        'Nama pengguna mesti mempunyai antara 3 hingga 20 aksara.',
      );
    }

    final client = _requireClient();
    await _usernameWrite;
    try {
      final response = await client.auth.updateUser(
        UserAttributes(
          data: {'username': value, SocialUsername.sourceKey: null},
        ),
      );
      final nextUser = _mapUser(response.user);
      if (_sameUser(_currentUser, nextUser)) return;
      _currentUser = nextUser;
      notifyListeners();
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final client = _requireClient();
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.authRedirectUrl,
      );
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    }
  }

  @override
  Future<void> signOut() async {
    final client = _requireClient();
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final client = _requireClient();
    if (client.auth.currentUser == null) {
      throw const AuthServiceException('Tiada akaun aktif untuk dipadam.');
    }
    try {
      await client.functions.invoke('delete-account');
      await client.auth.signOut(scope: SignOutScope.local);
    } on FunctionException catch (error) {
      throw AuthServiceException(
        error.status == 404
            ? 'Fungsi padam akaun belum dipasang pada Supabase.'
            : 'Akaun tidak dapat dipadam. Cuba lagi.',
      );
    } on AuthException catch (error) {
      throw AuthServiceException(_authMessage(error));
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client != null) return client;
    throw const AuthServiceException(
      'Supabase belum dikonfigurasi. Tambah SUPABASE_URL dan '
      'SUPABASE_PUBLISHABLE_KEY ketika '
      'membina aplikasi.',
    );
  }

  AppAuthProvider _provider(User user) {
    final providerName = user.appMetadata['provider'] as String?;
    return switch (providerName) {
      'apple' => AppAuthProvider.apple,
      'google' => AppAuthProvider.google,
      'email' => AppAuthProvider.email,
      _ => AppAuthProvider.unknown,
    };
  }

  bool _isSocialProvider(AppAuthProvider provider) =>
      provider == AppAuthProvider.apple || provider == AppAuthProvider.google;

  AppAuthUser? _mapUser(User? user) {
    if (user == null) return null;
    final provider = _provider(user);
    final storedUsername = SocialUsername.stored(user);
    final hasGeneratedSource =
        user.userMetadata?[SocialUsername.sourceKey] ==
        SocialUsername.sourceValue;
    if (_isSocialProvider(provider)) {
      if (storedUsername != null) {
        _socialUsernames[user.id] = (
          username: storedUsername,
          generated: hasGeneratedSource,
          saved: true,
        );
      } else {
        _socialUsernames.putIfAbsent(
          user.id,
          () => (
            username: SocialUsername.generate(user),
            generated: true,
            saved: false,
          ),
        );
      }
    }
    final remembered = _isSocialProvider(provider)
        ? _socialUsernames[user.id]
        : null;
    final username = storedUsername ?? remembered?.username;
    final isGenerated = storedUsername != null
        ? hasGeneratedSource
        : remembered?.generated ?? false;
    return AppAuthUser(
      id: user.id,
      email: user.email,
      displayName: isGenerated || username == null
          ? SocialUsername.displayName(user)
          : username,
      username: username,
      usernameIsGenerated: isGenerated,
      provider: provider,
    );
  }

  bool _sameUser(AppAuthUser? current, AppAuthUser? next) {
    return current?.id == next?.id &&
        current?.email == next?.email &&
        current?.displayName == next?.displayName &&
        current?.username == next?.username &&
        current?.usernameIsGenerated == next?.usernameIsGenerated &&
        current?.provider == next?.provider;
  }

  String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mel atau kata laluan tidak tepat.';
    }
    if (message.contains('email not confirmed')) {
      return 'Sahkan alamat e-mel anda sebelum log masuk.';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Alamat e-mel ini telah didaftarkan.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Sambungan internet tidak tersedia. Cuba lagi kemudian.';
    }
    return error.message;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
