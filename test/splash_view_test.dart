import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/splash/views/splash_view.dart';

void main() {
  testWidgets('splash pulses before replacing itself with the next page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          nextPageBuilder: (_) => const Scaffold(body: Text('Seterusnya')),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Logo Petani'), findsOneWidget);
    expect(find.text('Seterusnya'), findsNothing);

    await tester.pump(const Duration(milliseconds: 3400));
    expect(find.bySemanticsLabel('Logo Petani'), findsOneWidget);
    expect(find.text('Seterusnya'), findsNothing);

    await tester.pump(const Duration(milliseconds: 651));
    await tester.pump();
    expect(find.text('Seterusnya'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 281));
    await tester.pump();

    expect(find.text('Seterusnya'), findsOneWidget);
    expect(find.bySemanticsLabel('Logo Petani'), findsNothing);
  });
}
