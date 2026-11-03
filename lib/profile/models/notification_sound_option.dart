enum NotificationSoundGroup {
  device('Peranti'),
  animal('Haiwan');

  const NotificationSoundGroup(this.label);

  final String label;
}

class NotificationSoundOption {
  const NotificationSoundOption({
    required this.id,
    required this.title,
    required this.group,
    required this.assetFileName,
    required this.nativeFileName,
  });

  static const defaultId = 'peranti_peringatan';

  final String id;
  final String title;
  final NotificationSoundGroup group;
  final String assetFileName;
  final String nativeFileName;

  String get assetPath => 'assets/notifications/$assetFileName';

  String get assetSourcePath => 'notifications/$assetFileName';

  String get androidResourceName => nativeFileName.split('.').first;

  static const options = <NotificationSoundOption>[
    NotificationSoundOption(
      id: 'peranti_beep_beep',
      title: 'Bip Bip',
      group: NotificationSoundGroup.device,
      assetFileName: 'peranti_beep_beep.wav',
      nativeFileName: 'notification_peranti_beep_beep.wav',
    ),
    NotificationSoundOption(
      id: 'peranti_moden',
      title: 'Peranti Moden',
      group: NotificationSoundGroup.device,
      assetFileName: 'peranti_moden.wav',
      nativeFileName: 'notification_peranti_moden.wav',
    ),
    NotificationSoundOption(
      id: defaultId,
      title: 'Peringatan',
      group: NotificationSoundGroup.device,
      assetFileName: 'peranti_peringatan.wav',
      nativeFileName: 'notification_peranti_peringatan.wav',
    ),
    NotificationSoundOption(
      id: 'peranti_radio',
      title: 'Radio',
      group: NotificationSoundGroup.device,
      assetFileName: 'peranti_radio.wav',
      nativeFileName: 'notification_peranti_radio.wav',
    ),
    NotificationSoundOption(
      id: 'peranti_telefon',
      title: 'Telefon',
      group: NotificationSoundGroup.device,
      assetFileName: 'peranti_telefon.wav',
      nativeFileName: 'notification_peranti_telefon.wav',
    ),
    NotificationSoundOption(
      id: 'ayam_berkoko',
      title: 'Ayam Berkokok',
      group: NotificationSoundGroup.animal,
      assetFileName: 'ayam_berkoko.wav',
      nativeFileName: 'notification_ayam_berkoko.wav',
    ),
    NotificationSoundOption(
      id: 'ayam_dan_merpati',
      title: 'Ayam dan Merpati',
      group: NotificationSoundGroup.animal,
      assetFileName: 'ayam_dan_merpati.wav',
      nativeFileName: 'notification_ayam_dan_merpati.wav',
    ),
    NotificationSoundOption(
      id: 'burung_i',
      title: 'Burung I',
      group: NotificationSoundGroup.animal,
      assetFileName: 'burung_I.wav',
      nativeFileName: 'notification_burung_i.wav',
    ),
    NotificationSoundOption(
      id: 'burung_ii',
      title: 'Burung II',
      group: NotificationSoundGroup.animal,
      assetFileName: 'burung_II.wav',
      nativeFileName: 'notification_burung_ii.wav',
    ),
    NotificationSoundOption(
      id: 'lembu',
      title: 'Lembu',
      group: NotificationSoundGroup.animal,
      assetFileName: 'lembu.wav',
      nativeFileName: 'notification_lembu.wav',
    ),
    NotificationSoundOption(
      id: 'monyet',
      title: 'Monyet',
      group: NotificationSoundGroup.animal,
      assetFileName: 'monyet.wav',
      nativeFileName: 'notification_monyet.wav',
    ),
  ];

  static NotificationSoundOption fromId(String? id) {
    return options.firstWhere(
      (option) => option.id == id,
      orElse: () => options.firstWhere((option) => option.id == defaultId),
    );
  }
}
