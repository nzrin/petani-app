import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/main/views/main_view.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/crop_selection_sheet.dart';
import 'package:petani/welcome/controllers/welcome_controller.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({
    super.key,
    this.cropSelectionRepository,
    this.projectRepository,
    this.homeRepository,
    this.onCompleted,
  });

  final CropSelectionRepository? cropSelectionRepository;
  final ProjectRepository? projectRepository;
  final HomeRepository? homeRepository;
  final ValueChanged<CropOption>? onCompleted;

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  late final WelcomeController _controller;
  late final CropSelectionController _cropSelectionController;
  late final CropSelectionRepository _cropSelectionRepository;
  Timer? _walkthroughTimer;

  @override
  void initState() {
    super.initState();
    _controller = WelcomeController();
    _cropSelectionController = CropSelectionController();
    _cropSelectionRepository =
        widget.cropSelectionRepository ??
        SqliteCropSelectionRepository(AppDatabase.instance);
    _startWalkthroughTimer();
  }

  void _startWalkthroughTimer() {
    _walkthroughTimer?.cancel();
    _walkthroughTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) _controller.showNextWalkthrough();
    });
  }

  @override
  void dispose() {
    _walkthroughTimer?.cancel();
    _cropSelectionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCropPicker() async {
    _walkthroughTimer?.cancel();
    final selectedCrop = await showModalBottomSheet<CropOption>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CropSelectionSheet(controller: _cropSelectionController),
    );

    if (!mounted) return;
    if (selectedCrop == null) {
      _startWalkthroughTimer();
      return;
    }

    try {
      await _cropSelectionRepository.saveSelectedCrop(selectedCrop);
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Pilihan tanaman tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
      _startWalkthroughTimer();
      return;
    }

    if (!mounted) return;

    final onCompleted = widget.onCompleted;
    if (onCompleted != null) {
      onCompleted(selectedCrop);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MainView(
          initialCrop: selectedCrop.name,
          cropSelectionRepository: _cropSelectionRepository,
          projectRepository: widget.projectRepository,
          homeRepository: widget.homeRepository,
          showProjectFormOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: ColoredBox(
          color: AppColors.green,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(0, 12, 0, 18),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller.walkthroughController,
                        onPageChanged: _controller.setWalkthroughPage,
                        itemBuilder: (context, index) {
                          final item =
                              _controller.walkthroughItems[index %
                                  _controller.walkthroughItems.length];
                          return Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                  ),
                                  child: Semantics(
                                    label: item.semanticLabel,
                                    image: true,
                                    child: Image.asset(
                                      item.imagePath,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 390,
                                ),
                                child: Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFDCEBE4),
                                    fontSize: 17,
                                    height: 1.42,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PageIndicator(
                      length: _controller.walkthroughItems.length,
                      currentIndex: _controller.currentWalkthrough,
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppButton(
                        key: const Key('mula-sekarang-button'),
                        label: 'Mula Sekarang',
                        onPressed: _openCropPicker,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.forest,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.length, required this.currentIndex});

  final int length;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isSelected ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0x66FFFFFF),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
