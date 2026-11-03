import 'package:flutter/foundation.dart';
import 'package:petani/main/models/main_destination.dart';

class MainController extends ChangeNotifier {
  int currentIndex = 0;

  final destinations = const <MainDestination>[
    MainDestination(
      label: 'Utama',
      iconAssetPath: 'assets/images/tabbar/home.png',
      selectedIconAssetPath: 'assets/images/tabbar/home_sel.png',
    ),
    MainDestination(
      label: 'Projek',
      iconAssetPath: 'assets/images/tabbar/project.png',
      selectedIconAssetPath: 'assets/images/tabbar/project_sel.png',
    ),
    MainDestination(
      label: 'Laporan',
      iconAssetPath: 'assets/images/tabbar/report.png',
      selectedIconAssetPath: 'assets/images/tabbar/report_sel.png',
    ),
    MainDestination(label: 'Profil', usesProfileAvatar: true),
  ];

  void selectDestination(int index) {
    if (currentIndex == index) return;
    currentIndex = index;
    notifyListeners();
  }
}
