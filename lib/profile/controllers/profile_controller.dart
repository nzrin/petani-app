import 'package:flutter/material.dart';
import 'package:petani/profile/models/profile_item.dart';

class ProfileController {
  final items = const <ProfileItem>[
    ProfileItem(
      title: 'Maklumat Kebun',
      subtitle: 'Nama, lokasi dan keluasan kebun',
      icon: Icons.map_outlined,
    ),
    ProfileItem(
      title: 'Peringatan',
      subtitle: 'Tetapkan masa pemberitahuan tugasan',
      icon: Icons.notifications_none_rounded,
    ),
    ProfileItem(
      title: 'Bahasa',
      subtitle: 'Bahasa Melayu',
      icon: Icons.language_rounded,
    ),
    ProfileItem(
      title: 'Bantuan',
      subtitle: 'Panduan dan hubungi sokongan',
      icon: Icons.help_outline_rounded,
    ),
  ];
}
