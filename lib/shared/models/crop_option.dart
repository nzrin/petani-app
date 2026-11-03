import 'package:flutter/material.dart';

class CropOption {
  const CropOption({
    required this.code,
    required this.name,
    required this.description,
    required this.isAvailable,
    this.imagePath,
    this.icon,
  }) : assert(imagePath != null || icon != null);

  final String code;
  final String name;
  final String? imagePath;
  final IconData? icon;
  final String description;
  final bool isAvailable;
}
