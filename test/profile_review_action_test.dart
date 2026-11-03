import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/views/profile_view.dart';

void main() {
  testWidgets('Nilai Petani opens the review page', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 1600));

    var reviewRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileView(
            onOpenReviewPage: () async {
              reviewRequests++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final reviewAction = find.text('Nilai Petani');
    await tester.ensureVisible(reviewAction);
    await tester.tap(reviewAction);
    await tester.pump();

    expect(reviewRequests, 1);
  });
}
