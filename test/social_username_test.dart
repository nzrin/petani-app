import 'package:flutter_test/flutter_test.dart';
import 'package:petani/auth/services/social_username.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('uses a supplied name and a lossless stable account suffix', () {
    final user = _user(name: 'Nur Aisyah');
    final username = SocialUsername.generate(user);
    expect(username, startsWith('nuraisyah_'));
    expect(username, matches(RegExp(r'^[a-z0-9]+_[a-z0-9]{25}$')));
    expect(SocialUsername.generate(user), username);
    expect(SocialUsername.displayName(user), 'Nur Aisyah');
    final suffix = username.split('_').last;
    expect(
      BigInt.parse(suffix, radix: 36),
      BigInt.parse(user.id.replaceAll('-', ''), radix: 16),
    );
  });

  test(
    'same names and IDs differing only in the last bit have distinct usernames',
    () {
      final first = _user(
        name: 'Ali',
        id: 'a1234567-89ab-4cde-8f01-234567890abc',
      );
      final second = _user(
        name: 'Ali',
        id: 'a1234567-89ab-4cde-8f01-234567890abd',
      );
      expect(
        SocialUsername.generate(first),
        isNot(SocialUsername.generate(second)),
      );
    },
  );

  test(
    'falls back to email prefix but never includes its domain or plus alias',
    () {
      final user = _user(email: 'nazrin+farm@example.com');
      expect(SocialUsername.generate(user), startsWith('nazrin_'));
      expect(SocialUsername.displayName(user), 'nazrin');
    },
  );

  test('Apple private relay and absent name need no extra information', () {
    for (final email in [null, 'private-token@privaterelay.appleid.com']) {
      final user = _user(email: email);
      expect(SocialUsername.generate(user), startsWith('petani_'));
      expect(SocialUsername.displayName(user), 'Petani Moden');
    }
  });

  test('Unicode names remain readable and handles stay ASCII', () {
    final user = _user(name: '张伟 🌱');
    expect(SocialUsername.displayName(user), '张伟 🌱');
    expect(SocialUsername.generate(user), startsWith('petani_'));
  });

  test('long names only truncate the stem, never the identity suffix', () {
    final username = SocialUsername.generate(_user(name: 'A' * 100));
    expect(username.split('_').first.length, 12);
    expect(username.split('_').last.length, 25);
  });

  test('blank and malformed provider name metadata are safe', () {
    final user = _user(
      metadata: {
        'full_name': 123,
        'name': ' ',
        'given_name': 'Siti',
        'family_name': 'Aminah',
      },
    );
    expect(SocialUsername.displayName(user), 'Siti Aminah');
    expect(SocialUsername.generate(user), startsWith('sitiaminah_'));
  });
}

User _user({
  String id = 'a1234567-89ab-4cde-8f01-234567890abc',
  String? name,
  String? email,
  Map<String, dynamic>? metadata,
}) => User(
  id: id,
  appMetadata: const {'provider': 'apple'},
  userMetadata: metadata ?? {'full_name': ?name},
  email: email,
  aud: 'authenticated',
  createdAt: '2026-10-03T00:00:00Z',
);
