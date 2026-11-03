import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/auth/views/main_auth_view.dart';
import 'package:petani/core/config/feature_flags.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/models/app_icon_option.dart';
import 'package:petani/profile/services/app_icon_service.dart';
import 'package:petani/profile/views/app_icon_picker_sheet.dart';
import 'package:petani/profile/views/petani_support_card.dart';
import 'package:petani/profile/views/profile_login_card.dart';
import 'package:petani/profile/views/reminder_settings_view.dart';
import 'package:petani/shared/services/app_review_service.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';
import 'package:petani/shared/widgets/delete_account_sheet.dart';
import 'package:petani/shared/widgets/pulsing_indicator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    this.onLogout,
    this.authService,
    this.onOpenReviewPage,
    this.appIconService,
    this.onAppIconChanged,
  });

  final VoidCallback? onLogout;
  final AuthService? authService;
  final Future<bool> Function()? onOpenReviewPage;
  final AppIconService? appIconService;
  final ValueChanged<AppIconOption>? onAppIconChanged;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const _supportCardSettingKey = 'profile_support_card_hidden';
  static const _supportCardViewedSettingKey = 'profile_support_card_viewed';
  static final _faqUrl = Uri.https('petaniapp.nazrin.codes', '/faq');
  static final _privacyUrl = Uri.https('petaniapp.nazrin.codes', '/privacy');
  static final _termsUrl = Uri.https('petaniapp.nazrin.codes', '/terms');

  late final AuthService _authService;
  late final AppIconService _iconService;
  AppIconOption _selectedIcon = AppIconOption.options.first;
  bool _supportCardHidden = true;
  bool _supportCardViewed = false;
  bool _authActionInProgress = false;
  String _appVersionLabel = 'Memuatkan…';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? SupabaseAuthService.instance;
    _iconService = widget.appIconService ?? const AppIconService();
    _authService.addListener(_handleAuthChanged);
    unawaited(_loadSelectedIcon());
    unawaited(_loadAppVersion());
    if (FeatureFlags.showPetaniSupportSection) {
      unawaited(_loadSupportCardPreference());
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAppVersion() async {
    var label = 'Tidak tersedia';
    try {
      // iOS Info.plist and Android versionName/versionCode already use
      // app_version.xcconfig. Read the installed app's metadata, not a second
      // hardcoded value or Flutter's fallback version in pubspec.yaml.
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      if (version.isNotEmpty) {
        label = build.isEmpty ? version : '$version (Binaan $build)';
      }
    } on Exception {
      // Do not display a made-up version if native metadata is unavailable.
    }
    if (!mounted) return;
    setState(() => _appVersionLabel = label);
  }

  Future<void> _loadSelectedIcon() async {
    final nativeName = await _iconService.getCurrentIcon();
    if (!mounted) return;
    setState(() => _selectedIcon = AppIconOption.fromNativeName(nativeName));
  }

  Future<void> _openIconPicker() async {
    final selected = await showAppIconPickerSheet(
      context: context,
      selectedIcon: _selectedIcon,
      service: _iconService,
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedIcon = selected);
    widget.onAppIconChanged?.call(selected);
  }

  Future<void> _loadSupportCardPreference() async {
    try {
      final database = await AppDatabase.instance.database;
      final rows = await database.query(
        'app_settings',
        columns: ['setting_key', 'setting_value'],
        where: 'setting_key IN (?, ?)',
        whereArgs: [_supportCardSettingKey, _supportCardViewedSettingKey],
      );
      if (!mounted) return;
      final settings = {
        for (final row in rows)
          row['setting_key'] as String: row['setting_value'] as String,
      };
      setState(() {
        final hiddenValue = settings[_supportCardSettingKey];
        final viewedValue = settings[_supportCardViewedSettingKey];
        if (hiddenValue != null) _supportCardHidden = hiddenValue == '1';
        if (viewedValue != null) _supportCardViewed = viewedValue == '1';
      });
    } catch (_) {
      // The card remains closed when the preference cannot be loaded.
    }
  }

  Future<void> _setSupportCardHidden(bool hidden) async {
    if (mounted) {
      setState(() {
        _supportCardHidden = hidden;
        _supportCardViewed = true;
      });
    }
    try {
      final database = await AppDatabase.instance.database;
      final batch = database.batch();
      batch.insert('app_settings', {
        'setting_key': _supportCardSettingKey,
        'setting_value': hidden ? '1' : '0',
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('app_settings', {
        'setting_key': _supportCardViewedSettingKey,
        'setting_value': '1',
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    } catch (_) {
      // Keeping the in-memory state still gives immediate visual feedback.
    }
  }

  Future<void> _openWebPage(Uri url) async {
    var opened = false;

    try {
      opened = await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      );
    } on Exception {
      // Fall through to the platform-default browser below.
    }

    if (!opened) {
      try {
        opened = await launchUrl(url, mode: LaunchMode.platformDefault);
      } on Exception {
        // The shared error message below handles unavailable browsers.
      }
    }

    if (opened || !mounted) return;
    AppToast.show(
      context,
      'Halaman tidak dapat dibuka. Sila cuba lagi.',
      isError: true,
    );
  }

  Future<void> _openReviewPage() async {
    final opened =
        await (widget.onOpenReviewPage?.call() ??
            AppReviewService.instance.openReviewPage());
    if (opened || !mounted) return;

    AppToast.show(
      context,
      'Halaman penilaian belum dapat dibuka. Sila cuba lagi kemudian.',
      isError: true,
    );
  }

  Future<void> _openAuth() async {
    await showMainAuthPage(context, authService: _authService);
  }

  Future<void> _requestLogout() async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: 'Log Keluar?',
      description:
          'Rekod dalam peranti ini akan kekal tersedia secara lokal. '
          'Penyelarasan dengan storan awan akan berhenti sehingga anda log masuk semula.',
      confirmLabel: 'Log Keluar',
      imagePath: 'assets/images/farmer_logout.png',
      confirmColor: const Color(0xFFE12D3B),
    );
    if (!mounted || !confirmed) return;

    setState(() => _authActionInProgress = true);
    try {
      await _authService.signOut();
      if (mounted) widget.onLogout?.call();
    } on Object catch (error) {
      if (!mounted) return;
      AppToast.show(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _authActionInProgress = false);
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: 'Padam Akaun?',
      description:
          'Semua data akaun anda akan dipadam secara kekal. Tindakan ini '
          'tidak boleh dibuat asal.',
      confirmLabel: 'Padam Akaun',
      imagePath: 'assets/images/farmer_delete_account.png',
      confirmColor: const Color(0xFFE12D3B),
    );
    if (!mounted || !confirmed) return;

    final permanentlyConfirmed = await showDeleteAccountSheet(context);
    if (!mounted || !permanentlyConfirmed) return;

    setState(() => _authActionInProgress = true);
    try {
      await _authService.deleteAccount();
      if (mounted) widget.onLogout?.call();
    } on Object catch (error) {
      if (!mounted) return;
      AppToast.show(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _authActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        safePadding.top + 16,
        20,
        safePadding.bottom + 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            'Profil dan konfigurasi tetapan mengikut kehendak anda.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          if (!_authService.isAuthenticated) ...[
            const SizedBox(height: 20),
            ProfileLoginCard(onLogin: _openAuth),
            const SizedBox(height: 32),
          ] else
            const SizedBox(height: 20),
          // Keep the original section for future use, but omit it completely
          // (including its indicator and spacing) while the flag is disabled.
          if (FeatureFlags.showPetaniSupportSection) ...[
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Dari Petani Kepada Petani'),
                  if (!_supportCardViewed)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: PulsingIndicator(
                          key: ValueKey<String>('petani-support-indicator'),
                          color: AppColors.yellow,
                        ),
                      ),
                    ),
                ],
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            PetaniSupportCard(
              initiallyHidden: _supportCardHidden,
              onHiddenChanged: _setSupportCardHidden,
            ),
            const SizedBox(height: 32),
          ],
          const _SectionTitle('Tetapan Umum'),
          const SizedBox(height: 14),
          _SettingsCard(
            children: [
              _SettingsTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    _selectedIcon.assetPath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: 'Ikon Aplikasi',
                subtitle: 'Ikon semasa: ${_selectedIcon.label}',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openIconPicker,
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Peringatan',
                subtitle: 'Tetapkan masa peringatan tugasan kebun.',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReminderSettingsView(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _SectionTitle('Tentang Petani App'),
          const SizedBox(height: 14),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Soalan Lazim',
                subtitle: 'Dapatkan jawapan ringkas kepada soalan umum.',
                trailing: const Icon(Icons.north_east_rounded),
                onTap: () => _openWebPage(_faqUrl),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Polisi Privasi',
                subtitle: 'Ketahui cara maklumat anda dilindungi.',
                trailing: const Icon(Icons.north_east_rounded),
                onTap: () => _openWebPage(_privacyUrl),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.gavel_rounded,
                title: 'Terma dan Syarat',
                subtitle: 'Semak syarat penggunaan aplikasi Petani.',
                trailing: const Icon(Icons.north_east_rounded),
                onTap: () => _openWebPage(_termsUrl),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.star_rounded,
                title: 'Nilai Petani',
                subtitle: 'Kongsi pengalaman anda menggunakan Petani.',
                trailing: const Icon(Icons.north_east_rounded),
                onTap: _openReviewPage,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _SectionTitle('Zon Bahaya'),
          const SizedBox(height: 14),
          _SettingsCard(
            children: [
              if (_authService.isAuthenticated) ...[
                _DangerZoneTile(
                  key: const Key('logout-button'),
                  icon: Icons.logout_rounded,
                  title: 'Log Keluar',
                  actionLabel: 'Teruskan',
                  actionColor: const Color(0xFFE12D3B),
                  onPressed: _authActionInProgress ? null : _requestLogout,
                ),
                const _SettingsDivider(),
                _DangerZoneTile(
                  key: const Key('delete-account-button'),
                  icon: Icons.person_remove_alt_1_outlined,
                  title: 'Padam Akaun',
                  actionLabel: 'Padam',
                  actionColor: const Color(0xFFE12D3B),
                  onPressed: _authActionInProgress
                      ? null
                      : _requestAccountDeletion,
                ),
                const _SettingsDivider(),
              ],
              _DangerZoneTile(
                icon: Icons.info_outline_rounded,
                title: 'Versi',
                trailing: Text(
                  _appVersionLabel,
                  key: const Key('profile-app-version'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Hak Cipta © 2026 | Petani App',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.profileCard),
        border: Border.all(color: AppColors.cellBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.profileCard),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.cellBorder);
  }
}

class _DangerZoneTile extends StatelessWidget {
  const _DangerZoneTile({
    required this.icon,
    required this.title,
    super.key,
    this.actionLabel,
    this.actionColor,
    this.onPressed,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final Color? actionColor;
  final VoidCallback? onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.onSurface, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actionLabel case final actionLabel?) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                height: 46,
                child: FilledButton(
                  key: ValueKey<String>('danger-zone-action-$title'),
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(104, 46),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ] else if (trailing != null) ...[
              const SizedBox(width: 10),
              DefaultTextStyle.merge(
                style: TextStyle(color: colors.onSurfaceVariant),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colors.onSurface, size: 23),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              IconTheme(
                data: IconThemeData(color: colors.onSurfaceVariant, size: 24),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: colors.onSurfaceVariant),
                  child: trailing!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
