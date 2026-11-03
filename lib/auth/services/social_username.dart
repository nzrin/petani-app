import 'package:supabase_flutter/supabase_flutter.dart';

/// Automatic handles are internal labels, never login credentials or RLS keys.
abstract final class SocialUsername {
  static const sourceKey = 'username_source';
  static const sourceValue = 'social_auto';

  static String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String? stored(User user) => _text(user.userMetadata?['username']);

  static String? _accountName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = _text(metadata['full_name']) ?? _text(metadata['name']);
    if (name != null) return name;
    final parts = [
      _text(metadata['given_name']),
      _text(metadata['family_name']),
    ].whereType<String>().join(' ');
    return parts.isEmpty ? null : parts;
  }

  static String? _emailName(User user) {
    final email = _text(user.email);
    if (email == null) return null;
    final parts = email.split('@');
    if (parts.length != 2) return null;
    final domain = parts.last.toLowerCase();
    // Apple's relay alias is not a person's name. Never ask for their real one.
    if (domain == 'privaterelay.appleid.com' ||
        domain.endsWith('.privaterelay.appleid.com')) {
      return null;
    }
    return _text(parts.first.split('+').first);
  }

  static String displayName(User user) =>
      _accountName(user) ?? _emailName(user) ?? 'Petani Moden';

  static String generate(User user) {
    final name = _accountName(user) ?? _emailName(user) ?? 'petani';
    var stem = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    if (stem.isEmpty) stem = 'petani';
    if (stem.length > 12) stem = stem.substring(0, 12);

    // Preserve the ENTIRE UUID (128 bits), rather than a truncated random/hash
    // suffix. Accounts with the same name still get distinct handles. Base 36
    // keeps the suffix compact, deterministic and identical across devices.
    final uuid = user.id.replaceAll('-', '').toLowerCase();
    final String suffix;
    if (RegExp(r'^[0-9a-f]{32}$').hasMatch(uuid)) {
      suffix = BigInt.parse(uuid, radix: 16).toRadixString(36).padLeft(25, '0');
    } else {
      // Lossless fallback for non-UUID test/custom IDs; never truncate an ID.
      suffix =
          'id_${user.id.codeUnits.map((unit) => unit.toRadixString(16).padLeft(4, '0')).join()}';
    }
    return '${stem}_$suffix';
  }
}
