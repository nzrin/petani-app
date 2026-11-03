import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PetaniSupportCard extends StatefulWidget {
  const PetaniSupportCard({
    required this.initiallyHidden,
    required this.onHiddenChanged,
    super.key,
  });

  final bool initiallyHidden;
  final Future<void> Function(bool hidden) onHiddenChanged;

  @override
  State<PetaniSupportCard> createState() => _PetaniSupportCardState();
}

class _PetaniSupportCardState extends State<PetaniSupportCard>
    with SingleTickerProviderStateMixin {
  static const _wiseAccountNumber = '947300170229623';
  static const _paypalEmail = 'nazrindev@gmail.com';
  static const _touchNGoNumber = '121757107047';
  static const _ocbcAccountNumber = '1552037859';
  static const _bankIslamAccountNumber = '03054020223626';
  static const _maybankAccountNumber = '006089548758';
  static final _buyMeACoffeeUrl = Uri.parse(
    'https://buymeacoffee.com/nazrindev',
  );

  late bool _expanded;

  late final AnimationController _landingController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  late final Animation<double> _landingOffset = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 48),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: 8,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 8,
        end: -5,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: -5,
        end: 3,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 3,
        end: -1.5,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 9,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: -1.5,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 9,
    ),
  ]).animate(_landingController);

  late final Animation<double> _landingScale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 50),
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: .975), weight: 10),
    TweenSequenceItem(
      tween: Tween<double>(begin: .975, end: 1.016),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.016, end: .991),
      weight: 10,
    ),
    TweenSequenceItem(tween: Tween<double>(begin: .991, end: 1.006), weight: 9),
    TweenSequenceItem(tween: Tween<double>(begin: 1.006, end: 1), weight: 9),
  ]).animate(_landingController);

  @override
  void initState() {
    super.initState();
    _expanded = !widget.initiallyHidden;
  }

  @override
  void didUpdateWidget(covariant PetaniSupportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyHidden != widget.initiallyHidden &&
        _expanded == widget.initiallyHidden) {
      _expanded = !widget.initiallyHidden;
      _landingController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _landingController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    final hidden = _expanded;
    setState(() => _expanded = !_expanded);
    _landingController.forward(from: 0);
    unawaited(widget.onHiddenChanged(hidden));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const foreground = Colors.white;

    return AnimatedBuilder(
      animation: _landingController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _landingOffset.value),
        child: Transform.scale(
          scaleX: 1,
          scaleY: _landingScale.value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: AnimatedSize(
        key: const ValueKey<String>('petani-support-card'),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubicEmphasized,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, 16, 18, _expanded ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(colors.primary, Colors.black, .34)!,
                colors.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.profileCard),
            border: Border.all(
              color: foreground.withValues(alpha: .16),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: .22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedCrossFade(
                firstChild: _buildExpandedContent(context),
                secondChild: _buildCompactContent(),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 360),
                firstCurve: Curves.easeOut,
                secondCurve: Curves.easeIn,
                sizeCurve: Curves.easeInOutCubicEmphasized,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 620),
                    curve: Curves.easeInOutBack,
                    alignment: _expanded
                        ? Alignment.topCenter
                        : Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 620),
                      curve: Curves.easeInOutBack,
                      width: _expanded ? 70 : 40,
                      height: _expanded ? 70 : 40,
                      child: AnimatedScale(
                        scale: _expanded ? 1 : .95,
                        duration: const Duration(milliseconds: 620),
                        curve: Curves.easeInOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/dev.jpg',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) => Column(
    key: const ValueKey<String>('expanded-petani-support-card'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.topRight,
        child: Semantics(
          button: true,
          label: 'Sembunyikan kad perkongsian',
          child: Material(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: _toggleCard,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 57),
      const _SupportPromise(
        icon: Icons.credit_card_off_outlined,
        text: 'Tiada langganan',
      ),
      const SizedBox(height: 10),
      const _SupportPromise(
        icon: Icons.mobile_off_outlined,
        text: 'Tiada iklan ketika anda menguruskan tanaman',
      ),
      const SizedBox(height: 14),
      Text(
        'Saya faham kekecawaan yang harus dihadapi ketika dipaksa untuk '
        'menonton iklan ketika menggunakan aplikasi, mahupun melanggan '
        'untuk menggunakan sesuatu fungsi. Sebagai petani yang mahu '
        'menolong petani yang lain, saya bina aplikasi ini untuk membantu '
        'memudahkan urusan kita bersama.\n\n'
        'Jika anda ingin menyokong pembinaan aplikasi ini, anda boleh '
        'menyumbang melalui saluran dibawah. Setiap sumbangan tidak kira '
        'besar atau kecil, mampu membantu saya untuk menambahbaik aplikasi '
        'Petani ini dari semasa ke semasa.\n\n'
        'Terima kasih atas sokongan anda, saya amat hargai.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: .92),
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 18),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-touch-n-go'),
        label: "Touch 'n Go",
        value: _touchNGoNumber,
        assetPath: 'assets/images/app_tng.png',
        actions: _qrActions(
          context,
          label: "Touch 'n Go",
          value: _touchNGoNumber,
          qrAssetPath: 'assets/images/qr_touch_and_go.png',
          fileName: 'petani_touch_n_go_qr.png',
        ),
      ),
      const SizedBox(height: 12),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-ocbc'),
        label: 'OCBC',
        value: _ocbcAccountNumber,
        assetPath: 'assets/images/app_ocbc.png',
        actions: _qrActions(
          context,
          label: 'OCBC',
          value: _ocbcAccountNumber,
          qrAssetPath: 'assets/images/qr_ocbc.jpeg',
          fileName: 'petani_ocbc_qr.jpg',
        ),
      ),
      const SizedBox(height: 12),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-bank-islam'),
        label: 'Bank Islam',
        value: _bankIslamAccountNumber,
        assetPath: 'assets/images/app_bank_islam.png',
        actions: _qrActions(
          context,
          label: 'Bank Islam',
          value: _bankIslamAccountNumber,
          qrAssetPath: 'assets/images/qr_bank_islam.png',
          fileName: 'petani_bank_islam_qr.png',
        ),
      ),
      const SizedBox(height: 12),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-maybank'),
        label: 'Maybank',
        value: _maybankAccountNumber,
        assetPath: 'assets/images/app_mae.png',
        actions: _qrActions(
          context,
          label: 'Maybank',
          value: _maybankAccountNumber,
          qrAssetPath: 'assets/images/qr_mae_wallet.png',
          fileName: 'petani_maybank_qr.png',
        ),
      ),
      const SizedBox(height: 12),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-wise'),
        label: 'Wise',
        value: _wiseAccountNumber,
        assetPath: 'assets/images/app_wise.png',
        actions: [
          _SupportAction(
            icon: Icons.copy_rounded,
            tooltip: 'Salin nombor akaun Wise',
            onTap: () => _copy(
              context,
              value: _wiseAccountNumber,
              message: 'Nombor akaun Wise telah disalin.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-paypal'),
        label: 'PayPal',
        value: _paypalEmail,
        assetPath: 'assets/images/app_paypal.png',
        actions: [
          _SupportAction(
            icon: Icons.copy_rounded,
            tooltip: 'Salin e-mel PayPal',
            onTap: () => _copy(
              context,
              value: _paypalEmail,
              message: 'E-mel PayPal telah disalin.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SupportDetail(
        key: const ValueKey<String>('support-detail-buy-me-a-coffee'),
        label: 'Buy Me A Coffee',
        value: 'buymeacoffee.com/nazrindev',
        assetPath: 'assets/images/app_buyme.png',
        actions: [
          _SupportAction(
            icon: Icons.north_east_rounded,
            tooltip: 'Buka Buy Me A Coffee',
            onTap: () => _openBuyMeACoffee(context),
          ),
        ],
      ),
    ],
  );

  List<_SupportAction> _qrActions(
    BuildContext context, {
    required String label,
    required String value,
    required String qrAssetPath,
    required String fileName,
  }) => [
    _SupportAction(
      icon: Icons.copy_rounded,
      tooltip: 'Salin nombor $label',
      onTap: () =>
          _copy(context, value: value, message: 'Nombor $label telah disalin.'),
    ),
    _SupportAction(
      icon: Icons.qr_code_2_rounded,
      tooltip: 'Paparkan kod QR $label',
      onTap: () => _showQrSheet(
        context,
        label: label,
        qrAssetPath: qrAssetPath,
        fileName: fileName,
      ),
    ),
  ];

  static Future<void> _showQrSheet(
    BuildContext context, {
    required String label,
    required String qrAssetPath,
    required String fileName,
  }) => showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DonationQrSheet(
      label: label,
      qrAssetPath: qrAssetPath,
      fileName: fileName,
    ),
  );

  Widget _buildCompactContent() => Semantics(
    button: true,
    label: 'Paparkan kad perkongsian',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleCard,
      child: const SizedBox(
        key: ValueKey<String>('compact-petani-support-card'),
        height: 45,
        child: Padding(
          padding: EdgeInsets.only(left: 54),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bicara Pembangun',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  static Future<void> _copy(
    BuildContext context, {
    required String value,
    required String message,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    AppToast.show(context, message);
  }

  static Future<void> _openBuyMeACoffee(BuildContext context) async {
    var opened = false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        opened = await launchUrl(
          _buyMeACoffeeUrl,
          mode: LaunchMode.externalApplication,
        );
      } on Exception {
        // Fall through to the platform-default launcher below.
      }
    } else {
      try {
        opened = await launchUrl(
          _buyMeACoffeeUrl,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
      } on Exception {
        // Fall through to the platform-default launcher below.
      }
    }

    if (!opened) {
      try {
        opened = await launchUrl(
          _buyMeACoffeeUrl,
          mode: LaunchMode.platformDefault,
        );
      } on Exception {
        // The shared error message below handles unavailable browsers.
      }
    }

    if (opened || !context.mounted) return;
    AppToast.show(
      context,
      'Pautan Buy Me A Coffee gagal dibuka.',
      isError: true,
    );
  }
}

class _SupportPromise extends StatelessWidget {
  const _SupportPromise({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _SupportDetail extends StatelessWidget {
  const _SupportDetail({
    super.key,
    required this.label,
    required this.value,
    required this.assetPath,
    required this.actions,
  });

  final String label;
  final String value;
  final String assetPath;
  final List<_SupportAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 7, 11),
        child: Row(
          children: [
            _SupportLogo(assetPath: assetPath, size: 35),
            const SizedBox(width: 11),
            Expanded(
              child: _SupportIdentity(label: label, value: value),
            ),
            for (final action in actions) _SupportActionButton(action: action),
          ],
        ),
      ),
    );
  }
}

class _SupportLogo extends StatelessWidget {
  const _SupportLogo({required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

class _SupportIdentity extends StatelessWidget {
  const _SupportIdentity({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: .62),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SupportAction {
  const _SupportAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}

class _SupportActionButton extends StatelessWidget {
  const _SupportActionButton({required this.action});

  final _SupportAction action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: action.tooltip,
      child: IconButton(
        onPressed: action.onTap,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: Icon(action.icon, color: colors.onSurface, size: 21),
      ),
    );
  }
}

class _DonationQrSheet extends StatefulWidget {
  const _DonationQrSheet({
    required this.label,
    required this.qrAssetPath,
    required this.fileName,
  });

  final String label;
  final String qrAssetPath;
  final String fileName;

  @override
  State<_DonationQrSheet> createState() => _DonationQrSheetState();
}

class _DonationQrSheetState extends State<_DonationQrSheet> {
  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      var hasAccess = await Gal.hasAccess();
      if (!hasAccess) hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        if (!mounted) return;
        AppToast.show(
          context,
          'Kebenaran galeri diperlukan untuk menyimpan kod QR.',
          isError: true,
        );
        return;
      }

      final data = await rootBundle.load(widget.qrAssetPath);
      await Gal.putImageBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        name: widget.fileName,
      );

      if (!mounted) return;
      AppToast.show(context, 'Kod QR ${widget.label} disimpan ke galeri.');
    } on GalException catch (error) {
      if (!mounted) return;
      final message = switch (error.type) {
        GalExceptionType.accessDenied =>
          'Kebenaran galeri diperlukan untuk menyimpan kod QR.',
        GalExceptionType.notEnoughSpace => 'Ruang simpanan tidak mencukupi.',
        GalExceptionType.notSupportedFormat =>
          'Format gambar ini tidak disokong.',
        GalExceptionType.unexpected =>
          'Kod QR tidak dapat disimpan. Sila cuba lagi.',
      };
      AppToast.show(context, message, isError: true);
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Kod QR tidak dapat disimpan. Sila cuba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final imageHeight = (media.size.height * .42)
        .clamp(260.0, 430.0)
        .toDouble();

    return Material(
      key: const ValueKey<String>('donation-qr-sheet'),
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * .9),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            22 + media.viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D9D7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Kod QR ${widget.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: imageHeight,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Image.asset(
                  widget.qrAssetPath,
                  key: ValueKey<String>('donation-qr-${widget.label}'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  key: const ValueKey<String>('save-donation-qr'),
                  onPressed: _isSaving ? null : _saveToGallery,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isSaving ? 'Sedang menyimpan...' : 'Simpan ke Galeri',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
