class MainDestination {
  const MainDestination({
    required this.label,
    this.iconAssetPath,
    this.selectedIconAssetPath,
    this.usesProfileAvatar = false,
  }) : assert(
         usesProfileAvatar ||
             (iconAssetPath != null && selectedIconAssetPath != null),
       );

  final String label;
  final String? iconAssetPath;
  final String? selectedIconAssetPath;
  final bool usesProfileAvatar;
}
