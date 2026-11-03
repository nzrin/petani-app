import 'package:flutter_test/flutter_test.dart';
import 'package:petani/profile/models/notification_sound_option.dart';

void main() {
  test('notification sound catalogue has valid unique native resources', () {
    final options = NotificationSoundOption.options;

    expect(options, hasLength(11));
    expect(
      options.map((option) => option.id).toSet(),
      hasLength(options.length),
    );
    expect(
      options.map((option) => option.nativeFileName).toSet(),
      hasLength(options.length),
    );
    expect(
      options.where((option) => option.group == NotificationSoundGroup.device),
      hasLength(5),
    );
    expect(
      options.where((option) => option.group == NotificationSoundGroup.animal),
      hasLength(6),
    );
    expect(
      options.every(
        (option) =>
            option.nativeFileName.startsWith('notification_') &&
            option.nativeFileName.endsWith('.wav'),
      ),
      isTrue,
    );
  });

  test('unknown sound id safely falls back to the default sound', () {
    final sound = NotificationSoundOption.fromId('unknown');

    expect(sound.id, NotificationSoundOption.defaultId);
    expect(sound.title, 'Peringatan');
  });
}
