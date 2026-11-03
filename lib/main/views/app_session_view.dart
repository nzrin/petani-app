import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/main/views/main_view.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';
import 'package:petani/welcome/views/welcome_view.dart';

typedef AuthenticatedAppBuilder =
    Widget Function(
      BuildContext context,
      CropOption crop,
      VoidCallback onLogout,
    );
typedef WalkthroughBuilder =
    Widget Function(BuildContext context, ValueChanged<CropOption> onCompleted);

class AppSessionView extends StatefulWidget {
  const AppSessionView({
    required this.authService,
    super.key,
    this.cropSelectionRepository,
    this.projectRepository,
    this.homeRepository,
    this.authenticatedAppBuilder,
    this.walkthroughBuilder,
  });

  final AuthService authService;
  final CropSelectionRepository? cropSelectionRepository;
  final ProjectRepository? projectRepository;
  final HomeRepository? homeRepository;
  final AuthenticatedAppBuilder? authenticatedAppBuilder;
  final WalkthroughBuilder? walkthroughBuilder;

  @override
  State<AppSessionView> createState() => _AppSessionViewState();
}

class _AppSessionViewState extends State<AppSessionView> {
  late final CropSelectionRepository _cropSelectionRepository;
  CropOption? _activeCrop;
  bool _isRestoringSession = false;
  bool _showProjectFormOnStart = false;
  int _restoreGeneration = 0;

  @override
  void initState() {
    super.initState();
    _cropSelectionRepository =
        widget.cropSelectionRepository ??
        SqliteCropSelectionRepository(AppDatabase.instance);
    widget.authService.addListener(_handleAuthChanged);
    if (widget.authService.isAuthenticated) {
      unawaited(_restoreAuthenticatedSession());
    }
  }

  @override
  void dispose() {
    widget.authService.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (!widget.authService.isAuthenticated) {
      _showWalkthrough();
      return;
    }
    if (_activeCrop == null && !_isRestoringSession) {
      unawaited(_restoreAuthenticatedSession());
    }
  }

  Future<void> _restoreAuthenticatedSession() async {
    final generation = ++_restoreGeneration;
    if (mounted) setState(() => _isRestoringSession = true);

    String? selectedCropCode;
    try {
      selectedCropCode = await _cropSelectionRepository.getSelectedCropCode();
    } on Exception {
      // A valid account session should still open the app if the local
      // preference cannot be read. The default available crop is used below.
    }

    if (!mounted ||
        generation != _restoreGeneration ||
        !widget.authService.isAuthenticated) {
      return;
    }

    final availableCrops = CropSelectionController.cropOptions.where(
      (crop) => crop.isAvailable,
    );
    final selectedCrop = availableCrops.cast<CropOption?>().firstWhere(
      (crop) => crop?.code == selectedCropCode,
      orElse: () => null,
    );

    setState(() {
      _activeCrop = selectedCrop ?? availableCrops.first;
      _isRestoringSession = false;
      _showProjectFormOnStart = false;
    });
  }

  void _enterApp(CropOption crop) {
    ++_restoreGeneration;
    setState(() {
      _activeCrop = crop;
      _isRestoringSession = false;
      _showProjectFormOnStart = true;
    });
  }

  void _showWalkthrough() {
    ++_restoreGeneration;
    if (!mounted) return;
    setState(() {
      _activeCrop = null;
      _isRestoringSession = false;
      _showProjectFormOnStart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSession) {
      return const Scaffold(
        key: Key('session-restoring-view'),
        backgroundColor: AppColors.green,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final crop = _activeCrop;
    if (crop != null) {
      final builder = widget.authenticatedAppBuilder;
      if (builder != null) return builder(context, crop, _showWalkthrough);
      return MainView(
        initialCrop: crop.name,
        cropSelectionRepository: _cropSelectionRepository,
        projectRepository: widget.projectRepository,
        homeRepository: widget.homeRepository,
        authService: widget.authService,
        onLogout: _showWalkthrough,
        showProjectFormOnStart: _showProjectFormOnStart,
      );
    }

    final builder = widget.walkthroughBuilder;
    if (builder != null) return builder(context, _enterApp);
    return WelcomeView(
      cropSelectionRepository: _cropSelectionRepository,
      projectRepository: widget.projectRepository,
      homeRepository: widget.homeRepository,
      onCompleted: _enterApp,
    );
  }
}
