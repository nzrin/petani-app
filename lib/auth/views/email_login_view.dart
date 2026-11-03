import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';

typedef EmailLoginSubmit = Future<bool> Function(EmailLoginData data);
typedef PasswordResetSubmit = Future<void> Function(String email);

class EmailLoginView extends StatefulWidget {
  const EmailLoginView({super.key, this.onSubmit, this.onPasswordReset});

  final EmailLoginSubmit? onSubmit;
  final PasswordResetSubmit? onPasswordReset;

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  int _step = 0;
  bool _passwordVisible = false;
  bool _isSubmitting = false;
  bool _isRequestingPasswordReset = false;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refreshFormState);
    _passwordController.addListener(_refreshFormState);
  }

  void _refreshFormState() {
    setState(() {
      if (_step == 0 && _isValidEmail(_emailController.text)) {
        _fieldError = null;
      } else if (_step == 1 && _passwordController.text.length >= 8) {
        _fieldError = null;
      }
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  bool get _canContinue {
    if (_isSubmitting || _isRequestingPasswordReset) return false;
    return switch (_step) {
      0 => _isValidEmail(_emailController.text),
      _ => _passwordController.text.length >= 8,
    };
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_refreshFormState)
      ..dispose();
    _passwordController
      ..removeListener(_refreshFormState)
      ..dispose();
    super.dispose();
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step--;
      _fieldError = null;
    });
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (!_isValidEmail(_emailController.text)) return;
      setState(() {
        _step = 1;
        _fieldError = null;
      });
      return;
    }

    if (_passwordController.text.length < 8) return;
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      AppToast.show(
        context,
        'Log masuk Supabase belum diaktifkan.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    var succeeded = false;
    try {
      succeeded = await onSubmit(
        EmailLoginData(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        AppToast.show(context, error.toString(), isError: true);
      }
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;

    if (succeeded) {
      Navigator.pop(context, true);
    } else {
      AppToast.show(
        context,
        'E-mel atau kata laluan tidak dapat disahkan.',
        isError: true,
      );
    }
  }

  Future<void> _requestPasswordReset() async {
    final onPasswordReset = widget.onPasswordReset;
    if (onPasswordReset == null || _isRequestingPasswordReset) return;
    FocusScope.of(context).unfocus();
    setState(() => _isRequestingPasswordReset = true);
    try {
      await onPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      AppToast.show(context, 'Pautan pemulihan kata laluan telah dihantar.');
    } on Object catch (error) {
      if (!mounted) return;
      AppToast.show(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isRequestingPasswordReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Scaffold(
          key: const Key('email-login-view'),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      key: const Key('email-login-back-button'),
                      onPressed: _goBack,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.chevron_left_rounded, size: 38),
                      tooltip: 'Kembali',
                    ),
                  ),
                  const SizedBox(height: 34),
                  _LoginProgressIndicator(activeSegments: _step + 1),
                  const SizedBox(height: 38),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_step),
                          child: _step == 0
                              ? _buildEmailStep(context)
                              : _buildPasswordStep(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    key: const Key('email-login-continue-button'),
                    label: _step == 0
                        ? 'Seterusnya'
                        : _isSubmitting
                        ? 'Memproses...'
                        : 'Log Masuk',
                    onPressed: _canContinue ? _continue : null,
                    height: 58,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    return _LoginStepLayout(
      title: 'Selamat kembali',
      description: 'Masukkan e-mel yang disambungkan kepada akaun anda.',
      child: _LoginTextField(
        key: const Key('login-email-field'),
        controller: _emailController,
        hintText: 'anda@contoh.com',
        errorText: _fieldError,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
      ),
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    return _LoginStepLayout(
      title: 'Masukkan kata laluan anda',
      description: 'Satu langkah terakhir, kemudian rekod anda sedia.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LoginTextField(
            key: const Key('login-password-field'),
            controller: _passwordController,
            hintText: 'Sekurang-kurangnya 8 aksara',
            errorText: _fieldError,
            autofocus: true,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              key: const Key('toggle-login-password'),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            key: const Key('forgot-password-button'),
            onPressed: _isRequestingPasswordReset
                ? null
                : _requestPasswordReset,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isRequestingPasswordReset
                  ? const Row(
                      key: ValueKey<String>('password-reset-loading'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            key: Key('password-reset-loading-indicator'),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 9),
                        Text('Menghantar pautan...'),
                      ],
                    )
                  : const Text(
                      'Lupa kata laluan?',
                      key: ValueKey<String>('password-reset-idle'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginStepLayout extends StatelessWidget {
  const _LoginStepLayout({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 14),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 34),
        child,
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    super.key,
    this.errorText,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);

    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      obscureText: obscureText,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colors.onSurfaceVariant.withValues(alpha: 0.48),
          fontSize: 18,
        ),
        errorText: errorText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colors.outlineVariant, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 2),
        ),
      ),
    );
  }
}

class _LoginProgressIndicator extends StatelessWidget {
  const _LoginProgressIndicator({required this.activeSegments});

  final int activeSegments;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('email-login-progress'),
      children: [
        for (var index = 0; index < 2; index++) ...[
          if (index > 0) const SizedBox(width: 7),
          Expanded(
            child: AnimatedContainer(
              key: ValueKey<String>('login-progress-segment-$index'),
              duration: const Duration(milliseconds: 180),
              height: 5,
              decoration: BoxDecoration(
                color: index < activeSegments
                    ? AppColors.green
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
