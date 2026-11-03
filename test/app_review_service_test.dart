import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/services/app_review_service.dart';

void main() {
  test('opens the native store listing with the Petani App Store ID', () async {
    final gateway = _FakeReviewGateway();
    final service = AppReviewService(
      gateway: gateway,
      platform: TargetPlatform.iOS,
    );

    expect(await service.openReviewPage(), isTrue);
    expect(gateway.appStoreId, AppReviewService.appStoreId);
    expect(gateway.calls, 1);
  });

  test('falls back to the Android Play Store URL', () async {
    final gateway = _FakeReviewGateway(shouldThrow: true);
    Uri? launchedUrl;
    final service = AppReviewService(
      gateway: gateway,
      platform: TargetPlatform.android,
      fallbackLauncher: (url) async {
        launchedUrl = url;
        return true;
      },
    );

    expect(await service.openReviewPage(), isTrue);
    expect(launchedUrl, AppReviewService.androidStoreUrl);
  });

  test('falls back to the iOS App Store URL', () async {
    final gateway = _FakeReviewGateway(shouldThrow: true);
    Uri? launchedUrl;
    final service = AppReviewService(
      gateway: gateway,
      platform: TargetPlatform.iOS,
      fallbackLauncher: (url) async {
        launchedUrl = url;
        return true;
      },
    );

    expect(await service.openReviewPage(), isTrue);
    expect(launchedUrl, AppReviewService.iosStoreUrl);
  });

  test('requests the native review once after the second task', () async {
    final directory = await Directory.systemTemp.createTemp(
      'petani-review-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final gateway = _FakeReviewGateway();
    final service = AppReviewService(
      gateway: gateway,
      directoryProvider: () async => directory,
      platform: TargetPlatform.android,
    );

    expect(await service.requestAfterTaskCreated(totalTaskCount: 1), isFalse);
    expect(gateway.reviewRequests, 0);

    expect(await service.requestAfterTaskCreated(totalTaskCount: 2), isTrue);
    expect(gateway.availabilityChecks, 1);
    expect(gateway.reviewRequests, 1);

    expect(await service.requestAfterTaskCreated(totalTaskCount: 3), isFalse);
    expect(gateway.reviewRequests, 1);
  });

  test('waits for a later task when native review is unavailable', () async {
    final directory = await Directory.systemTemp.createTemp(
      'petani-review-unavailable-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final gateway = _FakeReviewGateway(available: false);
    final service = AppReviewService(
      gateway: gateway,
      directoryProvider: () async => directory,
      platform: TargetPlatform.android,
    );

    expect(await service.requestAfterTaskCreated(totalTaskCount: 2), isFalse);
    expect(gateway.availabilityChecks, 1);
    expect(gateway.reviewRequests, 0);
  });
}

class _FakeReviewGateway implements AppReviewGateway {
  _FakeReviewGateway({this.shouldThrow = false, this.available = true});

  final bool shouldThrow;
  final bool available;
  int calls = 0;
  int availabilityChecks = 0;
  int reviewRequests = 0;
  String? appStoreId;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<void> openStoreListing({required String appStoreId}) async {
    calls++;
    this.appStoreId = appStoreId;
    if (shouldThrow) throw StateError('Store unavailable');
  }

  @override
  Future<void> requestReview() async {
    reviewRequests++;
  }
}
