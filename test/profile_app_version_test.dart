import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/views/profile_view.dart';

void main() {
  for (final values in [
    (version: '1.0.0', build: '3', label: '1.0.0 (Binaan 3)'),
    (version: '2.4.1', build: '42', label: '2.4.1 (Binaan 42)'),
    (version: '2.4.1', build: '', label: '2.4.1'),
    (version: '', build: '', label: 'Tidak tersedia'),
  ]) {
    testWidgets('profile displays installed metadata: ${values.label}', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'Petani',
        packageName: 'com.nazrinapp.petani',
        version: values.version,
        buildNumber: values.build,
        buildSignature: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileView()),
        ),
      );
      await tester.pump();

      final label = tester.widget<Text>(
        find.byKey(const Key('profile-app-version')),
      );
      expect(label.data, values.label);
      expect(find.text('1.0.0 (Binaan 1)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
