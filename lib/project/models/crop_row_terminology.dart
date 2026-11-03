class CropRowTerminology {
  const CropRowTerminology._({
    required this.title,
    required this.lowercase,
    required this.abbreviation,
  });

  static const pineapple = CropRowTerminology._(
    title: 'Batas',
    lowercase: 'batas',
    abbreviation: 'B',
  );

  static const coconut = CropRowTerminology._(
    title: 'Baris',
    lowercase: 'baris',
    abbreviation: 'B',
  );

  static const rice = CropRowTerminology._(
    title: 'Petak',
    lowercase: 'petak',
    abbreviation: 'P',
  );

  factory CropRowTerminology.forCropCode(String cropCode) {
    return switch (cropCode) {
      'rice' => rice,
      'coconut' ||
      'banana' ||
      'oil_palm' ||
      'rubber_tree' ||
      'torch_ginger' ||
      'durian' ||
      'corn' => coconut,
      _ => pineapple,
    };
  }

  final String title;
  final String lowercase;
  final String abbreviation;

  String count(int value) => '$value $lowercase';
}
