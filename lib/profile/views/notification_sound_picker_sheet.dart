import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/models/notification_sound_option.dart';

Future<NotificationSoundOption?> showNotificationSoundPickerSheet({
  required BuildContext context,
  required String selectedSoundId,
}) {
  return showModalBottomSheet<NotificationSoundOption>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _NotificationSoundPickerSheet(selectedSoundId: selectedSoundId),
  );
}

class _NotificationSoundPickerSheet extends StatefulWidget {
  const _NotificationSoundPickerSheet({required this.selectedSoundId});

  final String selectedSoundId;

  @override
  State<_NotificationSoundPickerSheet> createState() =>
      _NotificationSoundPickerSheetState();
}

class _NotificationSoundPickerSheetState
    extends State<_NotificationSoundPickerSheet> {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completeSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _activeSoundId;
  bool _isPlaying = false;

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0, 1);
  }

  AudioPlayer _ensurePlayer() {
    final existingPlayer = _player;
    if (existingPlayer != null) return existingPlayer;

    final player = AudioPlayer();
    _player = player;
    _durationSubscription = player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _positionSubscription = player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _completeSubscription = player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _activeSoundId = null;
        _isPlaying = false;
        _duration = Duration.zero;
        _position = Duration.zero;
      });
    });
    return player;
  }

  @override
  void dispose() {
    unawaited(_durationSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_completeSubscription?.cancel());
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  Future<void> _togglePreview(NotificationSoundOption sound) async {
    try {
      final player = _ensurePlayer();
      if (_activeSoundId == sound.id) {
        if (_isPlaying) {
          await player.pause();
        } else {
          await player.resume();
        }
        if (mounted) setState(() => _isPlaying = !_isPlaying);
        return;
      }

      await player.stop();
      if (!mounted) return;
      setState(() {
        _activeSoundId = sound.id;
        _isPlaying = true;
        _duration = Duration.zero;
        _position = Duration.zero;
      });
      await player.play(AssetSource(sound.assetSourcePath));
    } on Exception catch (error, stackTrace) {
      debugPrint('Notification sound preview failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _activeSoundId = null;
        _isPlaying = false;
      });
      AppToast.show(context, 'Bunyi tidak dapat dimainkan.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: Material(
        key: const Key('notification-sound-picker-sheet'),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D9D7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Pilih Bunyi Notifikasi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  children: [
                    for (final group in NotificationSoundGroup.values) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                        child: Text(
                          group.label,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      for (final sound in NotificationSoundOption.options.where(
                        (sound) => sound.group == group,
                      ))
                        _NotificationSoundTile(
                          sound: sound,
                          isSelected: sound.id == widget.selectedSoundId,
                          isActive: sound.id == _activeSoundId,
                          isPlaying: sound.id == _activeSoundId && _isPlaying,
                          progress: sound.id == _activeSoundId ? _progress : 0,
                          onPreview: () => _togglePreview(sound),
                          onSelected: () => Navigator.pop(context, sound),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSoundTile extends StatelessWidget {
  const _NotificationSoundTile({
    required this.sound,
    required this.isSelected,
    required this.isActive,
    required this.isPlaying,
    required this.progress,
    required this.onPreview,
    required this.onSelected,
  });

  final NotificationSoundOption sound;
  final bool isSelected;
  final bool isActive;
  final bool isPlaying;
  final double progress;
  final VoidCallback onPreview;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          key: ValueKey<String>('notification-sound-${sound.id}'),
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          leading: SizedBox.square(
            dimension: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: AppColors.primaryAction,
                      backgroundColor: AppColors.mint,
                    ),
                  ),
                IconButton(
                  key: ValueKey<String>(
                    'notification-sound-preview-${sound.id}',
                  ),
                  onPressed: onPreview,
                  tooltip: isPlaying ? 'Jeda pratonton' : 'Main pratonton',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.primaryAction,
                  ),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            sound.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            sound.group.label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          trailing: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryAction
                  : const Color(0xFFF1F3F2),
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 19)
                : null,
          ),
          onTap: onSelected,
        ),
        const Divider(height: 1, color: AppColors.cellBorder),
      ],
    );
  }
}
