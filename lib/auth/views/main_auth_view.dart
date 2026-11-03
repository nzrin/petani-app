import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/auth/views/email_login_view.dart';
import 'package:petani/auth/views/email_sign_up_view.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';

const _mainAuthTransitionDuration = Duration(milliseconds: 420);
const _mainAuthReverseTransitionDuration = Duration(milliseconds: 320);

enum _MainAuthResult { authenticated, emailVerificationPending }

Future<bool?> showMainAuthPage(
  BuildContext context, {
  AuthService? authService,
}) async {
  final route = PageRouteBuilder<_MainAuthResult>(
    settings: const RouteSettings(name: 'main-auth'),
    transitionDuration: _mainAuthTransitionDuration,
    reverseTransitionDuration: _mainAuthReverseTransitionDuration,
    pageBuilder: (_, _, _) => MainAuthView(authService: authService),
    transitionsBuilder: (_, animation, _, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
  final result = await Navigator.of(context).push<_MainAuthResult>(route);

  if (result == _MainAuthResult.emailVerificationPending) {
    // Wait until the closing route has been removed from the overlay before
    // presenting the sheet on the page underneath it.
    await route.completed;
    if (!context.mounted) return true;

    await showAppConfirmationSheet(
      context: context,
      imagePath: 'assets/images/farmer_phone.png',
      title: 'Semak Emel anda',
      description:
          'Pendaftaran berjaya. Kami telah menghantar pautan pengesahan ke '
          'alamat emel anda. Buka emel tersebut dan sahkan akaun anda '
          'sebelum log masuk. Jika emel tidak ditemui, semak folder Spam.',
      confirmLabel: 'Baik, Saya Faham',
    );
    return true;
  }

  return result == _MainAuthResult.authenticated ? true : null;
}

class MainAuthView extends StatefulWidget {
  const MainAuthView({super.key, this.authService});

  final AuthService? authService;

  @override
  State<MainAuthView> createState() => _MainAuthViewState();
}

class _MainAuthViewState extends State<MainAuthView> {
  late final AuthService _authService;
  bool _isStartingProvider = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? SupabaseAuthService.instance;
    _authService.addListener(_handleAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (!_authService.isAuthenticated || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == true) {
        _closeAfterAuthentication();
      }
    });
  }

  void _closeAfterAuthentication() {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    Navigator.pop(context, _MainAuthResult.authenticated);
  }

  Future<void> _openEmailLogin() async {
    final succeeded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmailLoginView(
          onSubmit: _authService.signInWithEmail,
          onPasswordReset: _authService.sendPasswordReset,
        ),
      ),
    );
    if (!mounted || succeeded != true) return;

    Navigator.pop(context, _MainAuthResult.authenticated);
  }

  Future<void> _openEmailSignUp() async {
    final succeeded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmailSignUpView(onSubmit: _authService.signUpWithEmail),
      ),
    );
    if (!mounted || succeeded != true) return;

    Navigator.pop(context, _MainAuthResult.emailVerificationPending);
  }

  Future<void> _startProviderLogin(SocialAuthProvider provider) async {
    if (_isStartingProvider) return;
    setState(() => _isStartingProvider = true);
    try {
      await _authService.signInWithProvider(provider);
    } on Object catch (error) {
      if (!mounted) return;
      AppToast.show(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isStartingProvider = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const Key('main-auth-page'),
        backgroundColor: AppColors.cream,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      key: const Key('close-main-auth-button'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 32),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/farmer_phone.png',
                      key: const Key('main-auth-illustration'),
                      width: 235,
                      height: 235,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  'Simpan setiap rekod bersama anda',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 29,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Daftar akaun untuk melindungi rekod tanaman, projek dan '
                  'tugasan anda di semua peranti.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _AuthProviderButton(
                  key: const Key('continue-with-apple-button'),
                  provider: const Icon(Icons.apple_rounded, size: 28),
                  label: 'Teruskan dengan Apple',
                  onPressed: _isStartingProvider
                      ? null
                      : () => _startProviderLogin(SocialAuthProvider.apple),
                ),
                const SizedBox(height: 10),
                _AuthProviderButton(
                  key: const Key('continue-with-google-button'),
                  provider: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  label: 'Teruskan dengan Google',
                  onPressed: _isStartingProvider
                      ? null
                      : () => _startProviderLogin(SocialAuthProvider.google),
                ),
                const SizedBox(height: 14),
                const _OrDivider(),
                const SizedBox(height: 14),
                AppButton(
                  key: const Key('sign-up-with-email-button'),
                  label: 'Daftar dengan E-mel',
                  onPressed: _openEmailSignUp,
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Sudah berdaftar? ',
                      style: TextStyle(color: AppColors.ink, fontSize: 15),
                    ),
                    TextButton(
                      key: const Key('auth-sign-in-button'),
                      onPressed: _openEmailLogin,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Log Masuk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  key: const Key('continue-as-guest-button'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Teruskan sebagai tetamu',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.provider,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final Widget provider;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.white,
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: provider),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ATAU',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }
}
