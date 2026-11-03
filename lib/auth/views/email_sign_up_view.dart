import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/auth/models/email_sign_up_data.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';

typedef EmailSignUpSubmit = Future<bool> Function(EmailSignUpData data);

class EmailSignUpView extends StatefulWidget {
  const EmailSignUpView({super.key, this.onSubmit});

  final EmailSignUpSubmit? onSubmit;

  @override
  State<EmailSignUpView> createState() => _EmailSignUpViewState();
}

class _EmailSignUpViewState extends State<EmailSignUpView> {
  static const _totalProgressSegments = 3;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isSubmitting = false;
  String? _fieldError;
  String? _confirmationError;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_refreshFormState);
    _emailController.addListener(_refreshFormState);
    _passwordController.addListener(_refreshFormState);
    _confirmPasswordController.addListener(_refreshFormState);
  }

  void _refreshFormState() {
    setState(() {
      if (_step == 0 && _usernameController.text.trim().length >= 3) {
        _fieldError = null;
      } else if (_step == 1 && _isValidEmail(_emailController.text)) {
        _fieldError = null;
      }
    });
  }

  bool get _canContinue {
    if (_isSubmitting) return false;
    return switch (_step) {
      0 => _usernameController.text.trim().isNotEmpty,
      1 => _isValidEmail(_emailController.text),
      _ =>
        _passwordController.text.length >= 8 &&
            _confirmPasswordController.text == _passwordController.text,
    };
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  @override
  void dispose() {
    _usernameController
      ..removeListener(_refreshFormState)
      ..dispose();
    _emailController
      ..removeListener(_refreshFormState)
      ..dispose();
    _passwordController
      ..removeListener(_refreshFormState)
      ..dispose();
    _confirmPasswordController
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
      _confirmationError = null;
    });
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;

    if (_step < 2) {
      setState(() {
        _step++;
        _fieldError = null;
        _confirmationError = null;
      });
      return;
    }

    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      AppToast.show(
        context,
        'Supabase belum dikonfigurasi. Tambah publishable key dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    var succeeded = false;
    try {
      succeeded = await onSubmit(
        EmailSignUpData(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        AppToast.show(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted || !succeeded) return;
    Navigator.pop(context, true);
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      final username = _usernameController.text.trim();
      setState(() {
        _fieldError = username.length < 3
            ? 'Nama pengguna mesti mempunyai sekurang-kurangnya 3 aksara.'
            : null;
      });
      return _fieldError == null;
    }

    if (_step == 1) {
      final isValid = _isValidEmail(_emailController.text);
      setState(() {
        _fieldError = isValid ? null : 'Masukkan alamat e-mel yang sah.';
      });
      return isValid;
    }

    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;
    setState(() {
      _fieldError = password.length < 8
          ? 'Kata laluan mesti mempunyai sekurang-kurangnya 8 aksara.'
          : null;
      _confirmationError = confirmation != password
          ? 'Pengesahan kata laluan tidak sepadan.'
          : null;
    });
    return _fieldError == null && _confirmationError == null;
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
          key: const Key('email-sign-up-view'),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      key: const Key('email-sign-up-back-button'),
                      onPressed: _goBack,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.chevron_left_rounded, size: 38),
                      tooltip: 'Kembali',
                    ),
                  ),
                  const SizedBox(height: 34),
                  _AuthProgressIndicator(
                    activeSegments: _step + 1,
                    totalSegments: _totalProgressSegments,
                  ),
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
                          child: _buildStep(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    key: const Key('email-sign-up-continue-button'),
                    label: _step == 2
                        ? _isSubmitting
                              ? 'Memproses...'
                              : 'Daftar'
                        : 'Seterusnya',
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

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => _UsernameStep(
        controller: _usernameController,
        errorText: _fieldError,
      ),
      1 => _EmailStep(controller: _emailController, errorText: _fieldError),
      _ => _PasswordStep(
        passwordController: _passwordController,
        confirmationController: _confirmPasswordController,
        passwordVisible: _passwordVisible,
        confirmationVisible: _confirmPasswordVisible,
        passwordError: _fieldError,
        confirmationError: _confirmationError,
        onTogglePassword: () =>
            setState(() => _passwordVisible = !_passwordVisible),
        onToggleConfirmation: () =>
            setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
      ),
    };
  }
}

class _UsernameStep extends StatelessWidget {
  const _UsernameStep({required this.controller, required this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _AuthStepLayout(
      title: 'Pilih nama pengguna anda',
      description:
          'Nama ini hanya digunakan untuk memudahkan urusan dalam aplikasi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AuthTextField(
            key: const Key('sign-up-username-field'),
            controller: controller,
            hintText: 'NamaPetani',
            errorText: errorText,
            maxLength: 20,
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.text.characters.length}/20',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({required this.controller, required this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _AuthStepLayout(
      title: 'Apakah e-mel anda?',
      description:
          'Kami akan menggunakannya untuk memastikan data anda '
          'sentiasa diselaraskan.',
      child: _AuthTextField(
        key: const Key('sign-up-email-field'),
        controller: controller,
        hintText: 'anda@contoh.com',
        errorText: errorText,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
      ),
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.passwordController,
    required this.confirmationController,
    required this.passwordVisible,
    required this.confirmationVisible,
    required this.passwordError,
    required this.confirmationError,
    required this.onTogglePassword,
    required this.onToggleConfirmation,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final bool passwordVisible;
  final bool confirmationVisible;
  final String? passwordError;
  final String? confirmationError;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmation;

  @override
  Widget build(BuildContext context) {
    return _AuthStepLayout(
      title: 'Pilih kata laluan anda',
      description:
          'Gunakan sekurang-kurangnya 8 aksara untuk melindungi '
          'akaun anda.',
      child: Column(
        children: [
          _AuthTextField(
            key: const Key('sign-up-password-field'),
            controller: passwordController,
            hintText: 'Sekurang-kurangnya 8 aksara',
            errorText: passwordError,
            autofocus: true,
            obscureText: !passwordVisible,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              key: const Key('toggle-sign-up-password'),
              onPressed: onTogglePassword,
              icon: Icon(
                passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _AuthTextField(
            key: const Key('sign-up-confirm-password-field'),
            controller: confirmationController,
            hintText: 'Sahkan kata laluan anda',
            errorText: confirmationError,
            obscureText: !confirmationVisible,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              key: const Key('toggle-sign-up-confirmation'),
              onPressed: onToggleConfirmation,
              icon: Icon(
                confirmationVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthStepLayout extends StatelessWidget {
  const _AuthStepLayout({
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    super.key,
    this.errorText,
    this.maxLength,
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
  final int? maxLength;
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
      maxLength: maxLength,
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
        counterText: '',
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

class _AuthProgressIndicator extends StatelessWidget {
  const _AuthProgressIndicator({
    required this.activeSegments,
    required this.totalSegments,
  });

  final int activeSegments;
  final int totalSegments;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('email-sign-up-progress'),
      children: [
        for (var index = 0; index < totalSegments; index++) ...[
          if (index > 0) const SizedBox(width: 7),
          Expanded(
            child: AnimatedContainer(
              key: ValueKey<String>('auth-progress-segment-$index'),
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
