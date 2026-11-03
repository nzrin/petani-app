import 'package:flutter/material.dart';
import 'package:petani/welcome/models/walkthrough_item.dart';

class WelcomeController extends ChangeNotifier {
  WelcomeController()
    : walkthroughController = PageController(initialPage: _initialPage),
      _currentPage = _initialPage;

  static const _initialPage = 5000;

  final PageController walkthroughController;

  int currentWalkthrough = 0;
  int _currentPage;

  final walkthroughItems = const <WalkthroughItem>[
    WalkthroughItem(
      imagePath: 'assets/images/walkthrough/plots_and_rows.png',
      title: 'Tanaman Lebih Tersusun',
      description:
          'Tambah plot, susun kawasan tanaman dan rekod jumlah pokok dengan mudah.',
      semanticLabel: 'Petani mengurus plot dan kawasan tanaman',
    ),
    WalkthroughItem(
      imagePath: 'assets/images/walkthrough/care_schedule.png',
      title: 'Jadual Penjagaan Lengkap',
      description:
          'Tetapkan tarikh baja, racun dan aktiviti penting supaya tiada tugasan terlepas.',
      semanticLabel: 'Petani menyusun jadual penjagaan tanaman',
    ),
    WalkthroughItem(
      imagePath: 'assets/images/walkthrough/disease_reporting.png',
      title: 'Kesan Penyakit Lebih Awal',
      description:
          'Laporkan tanda penyakit pada tanaman dan simpan rekod tindakan anda.',
      semanticLabel: 'Petani melaporkan penyakit pada daun tanaman',
    ),
    WalkthroughItem(
      imagePath: 'assets/images/walkthrough/harvest_estimate.png',
      title: 'Rancang Masa Menuai',
      description:
          'Pantau usia tanaman dan anggaran tuaian untuk mengutip hasil.',
      semanticLabel: 'Petani merancang masa tuaian',
    ),
    WalkthroughItem(
      imagePath: 'assets/images/walkthrough/farm_reports.png',
      title: 'Laporan Di Hujung Jari',
      description:
          'Lihat ringkasan tanaman, aktiviti dan kemajuan kebun dalam satu tempat.',
      semanticLabel: 'Petani melihat laporan prestasi kebun',
    ),
  ];

  void setWalkthroughPage(int index) {
    _currentPage = index;
    final walkthroughIndex = index % walkthroughItems.length;
    if (currentWalkthrough == walkthroughIndex) return;
    currentWalkthrough = walkthroughIndex;
    notifyListeners();
  }

  Future<void> showNextWalkthrough() async {
    if (!walkthroughController.hasClients ||
        walkthroughController.position.isScrollingNotifier.value) {
      return;
    }

    await walkthroughController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    walkthroughController.dispose();
    super.dispose();
  }
}
