import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const nativeChannel = MethodChannel('com.nazrinapp.petani/web_auth');
  const browserChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SupabaseClient client;
  late SupabaseAuthService service;
  late _MemoryPkceStorage storage;
  late List<MethodCall> nativeCalls;
  late List<MethodCall> browserCalls;
  late List<http.Request> requests;
  String? nativeCallback;
  PlatformException? nativeError;
  Completer<String?>? pendingAuthentication;
  var providerName = 'apple';
  var rejectToken = false;
  var newSocialAccount = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    nativeCalls = [];
    browserCalls = [];
    requests = [];
    nativeCallback = '${SupabaseConfig.authRedirectUrl}?code=test-code';
    nativeError = null;
    pendingAuthentication = null;
    rejectToken = false;
    newSocialAccount = false;
    storage = _MemoryPkceStorage();
    messenger.setMockMethodCallHandler(nativeChannel, (call) async {
      nativeCalls.add(call);
      providerName = Uri.parse(
        call.arguments['url'] as String,
      ).queryParameters['provider']!;
      if (nativeError != null) throw nativeError!;
      if (pendingAuthentication != null) return pendingAuthentication!.future;
      return nativeCallback;
    });
    messenger.setMockMethodCallHandler(browserChannel, (call) async {
      browserCalls.add(call);
      return true;
    });
    client = SupabaseClient(
      'https://auth-test.example.com',
      'test-publishable-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' && request.url.path == '/auth/v1/user') {
          return http.Response(
            jsonEncode(
              _session(providerName, withUsername: false).user.toJson(),
            ),
            200,
          );
        }
        if (request.method == 'PUT' && request.url.path == '/auth/v1/user') {
          final metadata =
              (jsonDecode(request.body) as Map<String, dynamic>)['data'];
          final user = _session(providerName, withUsername: false).user;
          return http.Response(
            jsonEncode({
              ...user.toJson(),
              'user_metadata': {
                ...?user.userMetadata,
                ...metadata as Map<String, dynamic>,
              },
            }),
            200,
          );
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/v1/token');
        expect(request.url.queryParameters['grant_type'], 'pkce');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['auth_code'], 'test-code');
        expect(
          body['code_verifier'],
          storage.values.values.single.split('/').first,
        );
        if (rejectToken) {
          return http.Response(
            jsonEncode({'msg': 'Invalid login credentials'}),
            400,
          );
        }
        return http.Response(
          jsonEncode(
            _session(providerName, withUsername: !newSocialAccount).toJson(),
          ),
          200,
        );
      }),
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: storage,
      ),
    );
    service = SupabaseAuthService.withClient(client);
  });

  tearDown(() async {
    service.dispose();
    await client.dispose();
    messenger.setMockMethodCallHandler(nativeChannel, null);
    messenger.setMockMethodCallHandler(browserChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final provider in SocialAuthProvider.values) {
    test(
      '$provider new iOS account receives an automatic username after PKCE',
      () async {
        newSocialAccount = true;
        await service.signInWithProvider(provider);
        await pumpEventQueue();
        expect(service.isAuthenticated, isTrue);
        expect(service.currentUser?.username, startsWith('providertest_'));
        expect(service.currentUser?.usernameIsGenerated, isTrue);
        expect(service.currentUser?.displayName, 'Provider Test');
        expect(
          requests.where((request) => request.url.path == '/auth/v1/token'),
          hasLength(1),
        );
        expect(
          requests.where(
            (request) =>
                request.url.path == '/auth/v1/user' && request.method == 'PUT',
          ),
          hasLength(1),
        );
        expect(browserCalls, isEmpty);
      },
    );
    test(
      '$provider uses the iOS auth session and exchanges its PKCE callback',
      () async {
        await service.signInWithProvider(provider);
        await Future<void>.delayed(Duration.zero);

        final call = nativeCalls.single;
        expect(call.method, 'authenticate');
        expect(call.arguments['callbackUrl'], SupabaseConfig.authRedirectUrl);
        final uri = Uri.parse(call.arguments['url'] as String);
        expect(uri.scheme, 'https');
        expect(uri.queryParameters['provider'], provider.name);
        expect(
          uri.queryParameters['redirect_to'],
          SupabaseConfig.authRedirectUrl,
        );
        expect(uri.queryParameters['code_challenge_method'], 's256');
        expect(uri.queryParameters['code_challenge'], isNotEmpty);
        expect(requests, hasLength(1));
        expect(storage.values, isEmpty);
        expect(browserCalls, isEmpty);
        expect(service.isAuthenticated, isTrue);
        expect(service.currentUser?.provider.name, provider.name);
      },
    );
  }

  test(
    'cancel returns without a session or error and permits another attempt',
    () async {
      nativeCallback = null;
      await service.signInWithProvider(SocialAuthProvider.apple);
      expect(service.isAuthenticated, isFalse);
      expect(requests, isEmpty);

      nativeCallback = '${SupabaseConfig.authRedirectUrl}?code=test-code';
      await service.signInWithProvider(SocialAuthProvider.apple);
      await Future<void>.delayed(Duration.zero);
      expect(nativeCalls, hasLength(2));
      expect(service.isAuthenticated, isTrue);
    },
  );

  test('provider access denied is treated as cancellation', () async {
    nativeCallback = '${SupabaseConfig.authRedirectUrl}?error=access_denied';
    await service.signInWithProvider(SocialAuthProvider.apple);
    expect(requests, isEmpty);
    expect(service.isAuthenticated, isFalse);
  });

  for (final callback in [
    'other.app://login-callback/?code=test-code',
    'com.nazrinapp.petani://untrusted/?code=test-code',
    'com.nazrinapp.petani://login-callback/untrusted?code=test-code',
  ]) {
    test(
      'rejects unexpected callback $callback before exchanging credentials',
      () async {
        nativeCallback = callback;
        await expectLater(
          service.signInWithProvider(SocialAuthProvider.apple),
          throwsA(isA<AuthServiceException>()),
        );
        expect(requests, isEmpty);
      },
    );
  }

  test(
    'launch failures show a friendly error and never open an external browser',
    () async {
      nativeError = PlatformException(
        code: 'AUTH_FAILED',
        message: 'Internal launch error https://auth-test.example.com/private',
      );
      await expectLater(
        service.signInWithProvider(SocialAuthProvider.apple),
        throwsA(
          isA<AuthServiceException>().having(
            (error) => error.message,
            'user-facing message',
            allOf(contains('cuba lagi'), isNot(contains('https://'))),
          ),
        ),
      );
      expect(browserCalls, isEmpty);
      expect(requests, isEmpty);

      nativeError = null;
      await service.signInWithProvider(SocialAuthProvider.apple);
      await Future<void>.delayed(Duration.zero);
      expect(service.isAuthenticated, isTrue);
    },
  );

  test('rapid provider taps cannot replace the active PKCE verifier', () async {
    pendingAuthentication = Completer<String?>();
    final firstSignIn = service.signInWithProvider(SocialAuthProvider.apple);
    await Future<void>.delayed(Duration.zero);
    final verifier = storage.values.values.single;

    await service.signInWithProvider(SocialAuthProvider.google);
    expect(nativeCalls, hasLength(1));
    expect(storage.values.values.single, verifier);
    pendingAuthentication!.complete(nativeCallback);
    await firstSignIn;
    expect(requests, hasLength(1));
  });

  test(
    'rejected token exchange leaves the user signed out and allows retry',
    () async {
      rejectToken = true;
      await expectLater(
        service.signInWithProvider(SocialAuthProvider.apple),
        throwsA(isA<AuthServiceException>()),
      );
      expect(service.isAuthenticated, isFalse);

      rejectToken = false;
      await service.signInWithProvider(SocialAuthProvider.apple);
      await Future<void>.delayed(Duration.zero);
      expect(service.isAuthenticated, isTrue);
    },
  );

  test('Android retains the existing OAuth browser flow', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await service.signInWithProvider(SocialAuthProvider.google);
    expect(nativeCalls, isEmpty);
    expect(browserCalls.single.arguments['useSafariVC'], isFalse);
    expect(requests, isEmpty);
  });
}

Session _session(String provider, {bool withUsername = true}) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({
    'sub': 'a1234567-89ab-4cde-8f01-234567890abc',
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  });
  return Session(
    accessToken: '$header.$payload.test-signature',
    tokenType: 'bearer',
    user: User(
      id: 'a1234567-89ab-4cde-8f01-234567890abc',
      appMetadata: {'provider': provider},
      userMetadata: {
        if (withUsername) 'username': 'PetaniTest',
        'full_name': 'Provider Test',
      },
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
}

class _MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}
