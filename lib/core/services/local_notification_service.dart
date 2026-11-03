import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/repositories/notification_history_repository.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/profile/models/notification_reminder_settings.dart';
import 'package:petani/profile/models/notification_sound_option.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const _taskNotificationOffset = 1000000;
  static const _taskNotificationUpperBound = 2000000;
  static const _richTestNotificationId = 2000001;
  static const _channelIdPrefix = 'task_reminders_v2';
  static const _channelName = 'Peringatan Tugasan';
  static const _channelDescription =
      'Peringatan untuk tugasan kebun yang akan datang.';
  static const _richImageScale = 0.5;
  // The timezone package omits the Kuala Lumpur alias; Kuching is its
  // canonical Malaysian UTC+8 location for local scheduling.
  static const _malaysiaTimeZone = 'Asia/Kuching';
  static const _maximumScheduledTasks = 60;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationHistoryRepository _historyRepository =
      SqliteNotificationHistoryRepository(AppDatabase.instance);
  final Map<FarmTaskType, Future<Uint8List>> _richImageBytes = {};

  bool _isInitialized = false;
  int _attachmentSequence = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_malaysiaTimeZone));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (android == null) return true;

        final permissionGranted =
            await android.requestNotificationsPermission() ?? true;
        if (!permissionGranted) return false;

        return await android.areNotificationsEnabled() ?? permissionGranted;
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      case TargetPlatform.macOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  Future<void> scheduleTask(
    PlotTaskRecord task,
    NotificationReminderSettings settings,
  ) async {
    await initialize();
    final notificationId = _notificationIdForTask(task.id);
    await _plugin.cancel(id: notificationId);
    await _historyRepository.cancelPendingForTask(task.id);

    final reminderAt = _reminderDate(task.scheduledAt, settings);
    if (!settings.isEnabled ||
        task.isCompleted ||
        !reminderAt.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final title = task.type.labelForCrop(task.cropCode);
    final message = settings.notificationMessageFor(task.scheduledAt);
    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: message,
      scheduledDate: reminderAt,
      notificationDetails: await _richNotificationDetails(
        type: task.type,
        title: title,
        message: message,
        settings: settings,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'task:${task.id}:plot:${task.plotId}',
    );
    await _historyRepository.saveScheduledNotification(
      notificationId: notificationId,
      task: task,
      title: title,
      message: message,
      reminderAt: reminderAt,
    );
  }

  Future<void> cancelTask(int taskId) async {
    await initialize();
    await _plugin.cancel(id: _notificationIdForTask(taskId));
    await _historyRepository.cancelPendingForTask(taskId);
  }

  Future<void> synchronizeTasks(
    List<PlotTaskRecord> tasks,
    NotificationReminderSettings settings,
  ) async {
    await initialize();

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _taskNotificationOffset &&
          request.id < _taskNotificationUpperBound) {
        await _plugin.cancel(id: request.id);
      }
    }
    await _historyRepository.cancelAllPending();

    if (!settings.isEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final upcoming =
        tasks
            .where(
              (task) =>
                  !task.isCompleted &&
                  _reminderDate(task.scheduledAt, settings).isAfter(now),
            )
            .toList(growable: false)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    for (final task in upcoming.take(_maximumScheduledTasks)) {
      await scheduleTask(task, settings);
    }
  }

  Future<bool> openNotificationSettings() async {
    await initialize();
    return await _plugin.openAppNotificationSettings() ?? false;
  }

  Future<void> showRichTestNotification({
    required FarmTaskType type,
    required NotificationReminderSettings settings,
    required DateTime scheduledDate,
  }) async {
    await initialize();
    await _plugin.cancel(id: _richTestNotificationId);
    final message = settings.notificationMessageFor(scheduledDate);
    final title = type.label;
    await _plugin.show(
      id: _richTestNotificationId,
      title: title,
      body: message,
      notificationDetails: await _richNotificationDetails(
        type: type,
        title: title,
        message: message,
        settings: settings,
      ),
      payload: 'test:rich:${type.code}',
    );
  }

  int _notificationIdForTask(int taskId) {
    return _taskNotificationOffset + (taskId % _taskNotificationOffset);
  }

  tz.TZDateTime _reminderDate(
    DateTime taskDate,
    NotificationReminderSettings settings,
  ) {
    final localDate = taskDate.toLocal();
    final taskTime = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
    );
    return taskTime.subtract(settings.leadTime);
  }

  Future<NotificationDetails> _richNotificationDetails({
    required FarmTaskType type,
    required String title,
    required String message,
    required NotificationReminderSettings settings,
  }) async {
    String? imagePath;
    try {
      imagePath = await _taskImagePathForNotification(type);
    } on Exception catch (error, stackTrace) {
      debugPrint('Preparing rich notification image failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    final androidStyle = imagePath == null
        ? null
        : BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            contentTitle: title,
            summaryText: message,
            hideExpandedLargeIcon: true,
          );
    final attachments = imagePath == null
        ? null
        : <DarwinNotificationAttachment>[
            DarwinNotificationAttachment(imagePath),
          ];
    final sound = NotificationSoundOption.fromId(settings.soundId);
    final androidChannelId = settings.isSoundEnabled
        ? '${_channelIdPrefix}_${sound.id}'
        : '${_channelIdPrefix}_silent';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: const ui.Color(0xFF016B3D),
        icon: 'ic_notification',
        styleInformation: androidStyle,
        playSound: settings.isSoundEnabled,
        sound: settings.isSoundEnabled
            ? RawResourceAndroidNotificationSound(sound.androidResourceName)
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: settings.isSoundEnabled,
        sound: settings.isSoundEnabled ? sound.nativeFileName : null,
        attachments: attachments,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: settings.isSoundEnabled,
        sound: settings.isSoundEnabled ? sound.nativeFileName : null,
        attachments: attachments,
      ),
    );
  }

  Future<String> _taskImagePathForNotification(FarmTaskType type) async {
    final bytes = await _richImageBytes.putIfAbsent(
      type,
      () => _scaledTaskImageBytes(type),
    );
    final isDarwin =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final baseDirectory = isDarwin
        ? await getTemporaryDirectory()
        : await getApplicationSupportDirectory();
    final notificationDirectory = Directory(
      path.join(baseDirectory.path, 'notification_images'),
    );
    await notificationDirectory.create(recursive: true);

    final suffix = isDarwin
        ? '${DateTime.now().microsecondsSinceEpoch}_${_attachmentSequence++}'
        : 'persistent';
    final imageFile = File(
      path.join(
        notificationDirectory.path,
        '${type.code}_rich_50_v1_$suffix.png',
      ),
    );
    if (!isDarwin && await imageFile.exists()) return imageFile.path;
    await imageFile.writeAsBytes(bytes, flush: true);
    return imageFile.path;
  }

  Future<Uint8List> _scaledTaskImageBytes(FarmTaskType type) async {
    final byteData = await rootBundle.load(type.imagePath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;
    final canvasWidth = sourceImage.width;
    final canvasHeight = sourceImage.height;
    final targetWidth = canvasWidth * _richImageScale;
    final targetHeight = canvasHeight * _richImageScale;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final sourceRect = ui.Rect.fromLTWH(
      0,
      0,
      canvasWidth.toDouble(),
      canvasHeight.toDouble(),
    );
    final destinationRect = ui.Rect.fromLTWH(
      (canvasWidth - targetWidth) / 2,
      (canvasHeight - targetHeight) / 2,
      targetWidth,
      targetHeight,
    );
    canvas.drawImageRect(
      sourceImage,
      sourceRect,
      destinationRect,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(canvasWidth, canvasHeight);
    final pngData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    sourceImage.dispose();
    renderedImage.dispose();
    picture.dispose();
    codec.dispose();
    if (pngData == null) {
      throw StateError('Rich notification image could not be encoded.');
    }
    return pngData.buffer.asUint8List(
      pngData.offsetInBytes,
      pngData.lengthInBytes,
    );
  }
}
