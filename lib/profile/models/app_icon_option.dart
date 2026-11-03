class AppIconOption {
  const AppIconOption({
    required this.nativeName,
    required this.label,
    required this.assetPath,
  });

  final String nativeName;
  final String label;
  final String assetPath;

  bool get isDefault => nativeName == 'Default';

  static const options = <AppIconOption>[
    AppIconOption(
      nativeName: 'Default',
      label: 'Asal',
      assetPath: 'assets/images/icon_1024.jpg',
    ),
    AppIconOption(
      nativeName: 'IndianMan',
      label: 'Lelaki I',
      assetPath: 'assets/images/icons/indian_man.jpg',
    ),
    AppIconOption(
      nativeName: 'IndianWoman',
      label: 'Perempuan I',
      assetPath: 'assets/images/icons/indian_woman.jpg',
    ),
    AppIconOption(
      nativeName: 'ChineseMan',
      label: 'Lelaki II',
      assetPath: 'assets/images/icons/chinese_man.jpg',
    ),
    AppIconOption(
      nativeName: 'ChineseWoman',
      label: 'Perempuan II',
      assetPath: 'assets/images/icons/chinese_woman.jpg',
    ),
    AppIconOption(
      nativeName: 'MalayWomanHijab',
      label: 'Perempuan III',
      assetPath: 'assets/images/icons/malay_woman_hijab.jpg',
    ),
    AppIconOption(
      nativeName: 'MalayMan',
      label: 'Lelaki III',
      assetPath: 'assets/images/icons/malay_man.jpg',
    ),
    AppIconOption(
      nativeName: 'SabahSarawakMan',
      label: 'Lelaki IV',
      assetPath: 'assets/images/icons/sabah_sarawak_man.jpg',
    ),
    AppIconOption(
      nativeName: 'SabahSarawakWoman',
      label: 'Perempuan IV',
      assetPath: 'assets/images/icons/sabah_sarawak_woman.jpg',
    ),
    AppIconOption(
      nativeName: 'Boy',
      label: 'Budak Lelaki',
      assetPath: 'assets/images/icons/boy.jpg',
    ),
    AppIconOption(
      nativeName: 'Girl',
      label: 'Budak Perempuan',
      assetPath: 'assets/images/icons/girl.jpg',
    ),
    AppIconOption(
      nativeName: 'ElderlyWoman',
      label: 'Wanita Warga Emas',
      assetPath: 'assets/images/icons/elderly_woman.jpg',
    ),
    AppIconOption(
      nativeName: 'ElderlyMan',
      label: 'Lelaki Warga Emas',
      assetPath: 'assets/images/icons/elderly_man.jpg',
    ),
  ];

  static AppIconOption fromNativeName(String? nativeName) {
    return options.firstWhere(
      (option) => option.nativeName == nativeName,
      orElse: () => options.first,
    );
  }
}
