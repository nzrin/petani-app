import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/main/controllers/main_controller.dart';
import 'package:petani/main/widgets/liquid_glass_navigation_bar.dart';

void main() {
  testWidgets('tab bar uses image assets and updates the profile avatar', (
    tester,
  ) async {
    final controller = MainController();
    addTearDown(controller.dispose);
    final destinations = controller.destinations;

    Future<void> pumpBar(String profileAvatarAssetPath) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: LiquidGlassNavigationBar(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              profileAvatarAssetPath: profileAvatarAssetPath,
            ),
          ),
        ),
      );
    }

    await pumpBar('assets/images/icons/malay_man.jpg');
    expect(
      find.byKey(const ValueKey<String>('navigation-image-Utama-selected')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('navigation-image-Projek-normal')),
      findsOneWidget,
    );

    Image profileImage() => tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('profile-navigation-avatar')),
        matching: find.byType(Image),
      ),
    );

    expect(
      (profileImage().image as AssetImage).assetName,
      'assets/images/icons/malay_man.jpg',
    );

    await pumpBar('assets/images/icons/girl.jpg');
    await tester.pumpAndSettle();
    expect(
      (profileImage().image as AssetImage).assetName,
      'assets/images/icons/girl.jpg',
    );
  });
}
