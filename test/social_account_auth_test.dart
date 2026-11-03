import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/auth/services/social_username.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SupabaseAuthService service;
  late List<Map<String, dynamic>> metadataWrites;
  late User serverUser;
  Completer<void>? pendingWrite;
  var rejectWrite = false;
  var passwordSignIns = 0;

  setUp(() {
    metadataWrites = [];
    pendingWrite = null;
    rejectWrite = false;
    passwordSignIns = 0;
    serverUser = _user('apple');
    client = SupabaseClient(
      'https://auth-test.example.com',
      'test-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/auth/v1/user') {
          return http.Response(jsonEncode(serverUser.toJson()), 200);
        }
        if (request.method == 'PUT' && request.url.path == '/auth/v1/user') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final metadata = body['data'] as Map<String, dynamic>;
          final writingUser = serverUser;
          metadataWrites.add(metadata);
          await pendingWrite?.future;
          if (rejectWrite) {
            return http.Response(
              jsonEncode({'msg': 'Temporary private server error'}),
              500,
            );
          }
          serverUser = User.fromJson({
            ...writingUser.toJson(),
            'user_metadata': {...?writingUser.userMetadata, ...metadata},
          })!;
          return http.Response(jsonEncode(serverUser.toJson()), 200);
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('{}', 200);
        }
        if (request.url.path == '/auth/v1/token') {
          if (request.url.queryParameters['grant_type'] == 'refresh_token') {
            return http.Response(
              jsonEncode(_session(serverUser).toJson()),
              200,
            );
          }
          passwordSignIns++;
          serverUser = _user(
            'email',
            id: 'b1234567-89ab-4cde-8f01-234567890abc',
            username: 'OtherAccount',
          );
          return http.Response(jsonEncode(_session(serverUser).toJson()), 200);
        }
        fail('Unexpected request: ${request.method} ${request.url.path}');
      }),
    );
    service = SupabaseAuthService.withClient(client);
  });

  tearDown(() async {
    service.dispose();
    await client.dispose();
  });

  Future<void> restore(User user, {User? remoteUser}) async {
    serverUser = remoteUser ?? user;
    await client.auth.setInitialSession(jsonEncode(_session(user).toJson()));
    await pumpEventQueue();
  }

  for (final provider in ['apple', 'google']) {
    test('$provider silently generates and saves a username once', () async {
      final user = _user(provider, name: 'Nazrin Farm');
      await restore(user);
      final username = SocialUsername.generate(user);
      expect(service.isAuthenticated, isTrue);
      expect(service.currentUser?.username, username);
      expect(service.currentUser?.usernameIsGenerated, isTrue);
      expect(service.currentUser?.displayName, 'Nazrin Farm');
      expect(metadataWrites, [
        {
          'username': username,
          SocialUsername.sourceKey: SocialUsername.sourceValue,
        },
      ]);
      expect(serverUser.userMetadata?['full_name'], 'Nazrin Farm');
      expect(serverUser.userMetadata?['username'], username);
      await client.auth.setInitialSession(
        jsonEncode(_session(serverUser).toJson()),
      );
      await client.auth.refreshSession();
      await pumpEventQueue();
      expect(metadataWrites, hasLength(1));
    });
  }

  test('restored sessions already present at startup are backfilled', () async {
    service.dispose();
    serverUser = _user('google', name: 'Siti');
    await client.auth.setInitialSession(
      jsonEncode(_session(serverUser).toJson()),
    );
    service = SupabaseAuthService.withClient(client);
    expect(service.currentUser?.username, startsWith('siti_'));
    await pumpEventQueue();
    expect(metadataWrites, hasLength(1));
  });

  test('existing manually selected usernames are never overwritten', () async {
    await restore(_user('apple', name: 'Provider Name', username: 'MyFarm'));
    expect(service.currentUser?.username, 'MyFarm');
    expect(service.currentUser?.displayName, 'MyFarm');
    expect(service.currentUser?.usernameIsGenerated, isFalse);
    expect(metadataWrites, isEmpty);
  });

  test(
    'stale cached session cannot overwrite a username saved on another device',
    () async {
      final cached = _user('google', name: 'Provider Name');
      await restore(
        cached,
        remoteUser: _user(
          'google',
          name: 'Provider Name',
          username: 'SavedOnOtherDevice',
        ),
      );
      expect(service.currentUser?.username, 'SavedOnOtherDevice');
      expect(service.currentUser?.displayName, 'SavedOnOtherDevice');
      expect(service.currentUser?.usernameIsGenerated, isFalse);
      expect(metadataWrites, isEmpty);
      // Replayed stale metadata must not replace the confirmed remote handle.
      await client.auth.setInitialSession(
        jsonEncode(_session(cached).toJson()),
      );
      await pumpEventQueue();
      expect(service.currentUser?.username, 'SavedOnOtherDevice');
      expect(metadataWrites, isEmpty);
    },
  );

  test(
    'persisted generated username stays stable when provider name changes',
    () async {
      final user = _user('google', name: 'Original Name');
      final username = SocialUsername.generate(user);
      await restore(
        User.fromJson({
          ...user.toJson(),
          'user_metadata': {
            'full_name': 'Updated Name',
            'username': username,
            SocialUsername.sourceKey: SocialUsername.sourceValue,
          },
        })!,
      );
      expect(service.currentUser?.username, username);
      expect(service.currentUser?.displayName, 'Updated Name');
      expect(metadataWrites, isEmpty);
    },
  );

  test(
    'Apple Hide My Email needs no supplied name or additional form',
    () async {
      await restore(
        _user('apple', email: 'random-relay@privaterelay.appleid.com'),
      );
      expect(service.currentUser?.username, startsWith('petani_'));
      expect(service.currentUser?.displayName, 'Petani Moden');
      expect(service.currentUser?.username, isNot(contains('random')));
      expect(metadataWrites, hasLength(1));
    },
  );

  test('email accounts are not automatically renamed', () async {
    await restore(_user('email'));
    expect(service.currentUser?.username, isNull);
    expect(service.currentUser?.usernameIsGenerated, isFalse);
    expect(metadataWrites, isEmpty);
  });

  test(
    'slow or failed persistence does not block access and retries later',
    () async {
      pendingWrite = Completer<void>();
      final user = _user('google', name: 'Test Farm');
      await restore(user);
      expect(service.isAuthenticated, isTrue);
      expect(service.currentUser?.hasUsername, isTrue);
      expect(metadataWrites, hasLength(1));
      await client.auth.setInitialSession(
        jsonEncode(_session(serverUser).toJson()),
      );
      await client.auth.refreshSession();
      await pumpEventQueue();
      expect(metadataWrites, hasLength(1));

      rejectWrite = true;
      pendingWrite!.complete();
      await pumpEventQueue();
      expect(service.isAuthenticated, isTrue);
      expect(service.currentUser?.username, SocialUsername.generate(user));
      expect(metadataWrites, hasLength(1)); // No recursive retry storm.

      pendingWrite = null;
      rejectWrite = false;
      await client.auth.refreshSession();
      await pumpEventQueue();
      expect(metadataWrites, hasLength(2));
      expect(metadataWrites.first, metadataWrites.last);
      expect(
        serverUser.userMetadata?['username'],
        service.currentUser?.username,
      );
    },
  );

  test('signing out during a write cannot restore the old account', () async {
    pendingWrite = Completer<void>();
    await restore(_user('apple'));
    await service.signOut();
    await pumpEventQueue();
    expect(service.isAuthenticated, isFalse);

    // A subsequent sign-in waits for the old SDK update to finish, preventing
    // its response from overwriting the newly active account's session.
    final login = service.signInWithEmail(
      const EmailLoginData(
        email: 'other@example.com',
        password: 'test-only-password',
      ),
    );
    await pumpEventQueue();
    expect(passwordSignIns, 0);
    pendingWrite!.complete();
    expect(await login, isTrue);
    await pumpEventQueue();
    expect(passwordSignIns, 1);
    expect(service.currentUser?.id, 'b1234567-89ab-4cde-8f01-234567890abc');
    expect(service.currentUser?.username, 'OtherAccount');
  });
}

User _user(
  String provider, {
  String id = 'a1234567-89ab-4cde-8f01-234567890abc',
  String? username,
  String? name,
  String? email,
}) => User(
  id: id,
  appMetadata: {'provider': provider},
  userMetadata: {'username': ?username, 'full_name': ?name},
  email: email,
  aud: 'authenticated',
  createdAt: '2026-10-03T00:00:00Z',
);

Session _session(User user) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({
    'sub': user.id,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  });
  return Session(
    accessToken: '$header.$payload.test-signature',
    refreshToken: 'test-refresh-token',
    tokenType: 'bearer',
    user: user,
  );
}
