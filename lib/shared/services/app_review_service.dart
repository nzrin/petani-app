import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class AppReviewGateway {
  Future<bool> isAvailable();

  Future<void> requestReview();

  Future<void> openStoreListing({required String appStoreId});
}

class PlatformAppReviewGateway implements AppReviewGateway {
  PlatformAppReviewGateway({InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing({required String appStoreId}) =>
      _review.openStoreListing(appStoreId: appStoreId);
}

typedef StoreUrlLauncher = Future<bool> Function(Uri url);
typedef AppReviewDirectoryProvider = Future<Directory> Function();

/// Opens Petani's public store page from the explicit "Nilai Petani" action.
///
/// A permanent profile action uses the store listing instead of the
/// quota-controlled native review prompt. Until the listings are published,
/// the store application may report that the page is unavailable.
class AppReviewService {
  AppReviewService({
    AppReviewGateway? gateway,
    StoreUrlLauncher? fallbackLauncher,
    AppReviewDirectoryProvider? directoryProvider,
    TargetPlatform? platform,
  }) : _gateway = gateway ?? PlatformAppReviewGateway(),
       _fallbackLauncher = fallbackLauncher ?? _launchExternalUrl,
       _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory,
       _platform = platform ?? defaultTargetPlatform;

  static final AppReviewService instance = AppReviewService();

  static const minimumCreatedTasks = 2;
  static const appStoreId = '6815257867';
  static final iosStoreUrl = Uri.parse(
    'https://apps.apple.com/us/app/petani-pengurusan-tanaman/id6815257867',
  );
  static final androidStoreUrl = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.nazrinapp.petani',
  );

  final AppReviewGateway _gateway;
  final StoreUrlLauncher _fallbackLauncher;
  final AppReviewDirectoryProvider _directoryProvider;
  final TargetPlatform _platform;
  bool _requestInFlight = false;

  Future<bool> openReviewPage() => _guardRequest(() async {
    try {
      await _gateway.openStoreListing(appStoreId: appStoreId);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to open the native store listing: $error');
      debugPrintStack(stackTrace: stackTrace);

      final fallbackUrl = switch (_platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => iosStoreUrl,
        TargetPlatform.android => androidStoreUrl,
        _ => null,
      };
      if (fallbackUrl == null) return false;
      return _fallbackLauncher(fallbackUrl);
    }
  });

  /// Requests the native Apple/Google review sheet after the second task.
  ///
  /// The marker makes this a one-time request per installation. The platform
  /// can still suppress the sheet according to its own review quota.
  Future<bool> requestAfterTaskCreated({required int totalTaskCount}) async {
    if (totalTaskCount < minimumCreatedTasks) return false;

    return _guardRequest(() async {
      final marker = await _reviewMarker();
      if (await marker.exists() || !await _gateway.isAvailable()) return false;

      await _gateway.requestReview();
      await _writeMarker(marker);
      return true;
    });
  }

  Future<bool> _guardRequest(Future<bool> Function() request) async {
    if (_requestInFlight) return false;
    _requestInFlight = true;

    try {
      return await request();
    } catch (error, stackTrace) {
      debugPrint('Unable to request an app review: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _requestInFlight = false;
    }
  }

  Future<File> _reviewMarker() async {
    final directory = await _directoryProvider();
    return File(
      '${directory.path}${Platform.pathSeparator}'
      'petani_native_review_requested.txt',
    );
  }

  Future<void> _writeMarker(File marker) async {
    await marker.parent.create(recursive: true);
    final temporary = File('${marker.path}.tmp');
    await temporary.writeAsString(
      DateTime.now().toUtc().toIso8601String(),
      flush: true,
    );
    try {
      await temporary.rename(marker.path);
    } on FileSystemException {
      if (await marker.exists()) await marker.delete();
      await temporary.rename(marker.path);
    }
  }

  static Future<bool> _launchExternalUrl(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
