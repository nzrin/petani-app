import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';

typedef UsernameSubmit = Future<void> Function(String username);

class SocialUsernameView extends StatefulWidget {
  const SocialUsernameView({required this.onSubmit, super.key});

  final UsernameSubmit onSubmit;

  @override
  State<SocialUsernameView> createState() => _SocialUsernameViewState();
}

class _SocialUsernameViewState extends State<SocialUsernameView> {
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  bool get _canSubmit =>
      !_isSubmitting && _usernameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_refreshFormState);
  }

  void _refreshFormState() {
    setState(() {
      if (_usernameController.text.trim().length >= 3) _errorText = null;
    });
  }

  @override
  void dispose() {
    _usernameController
      ..removeListener(_refreshFormState)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      setState(() {
        _errorText =
            'Nama pengguna mesti mempunyai sekurang-kurangnya 3 aksara.';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(username);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (error) {
      if (mounted) {
        AppToast.show(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const Key('social-username-view'),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('social-username-back-button'),
                    onPressed: () => Navigator.pop(context, false),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.chevron_left_rounded, size: 38),
                    tooltip: 'Kembali',
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  key: const Key('social-username-progress'),
                  width: double.infinity,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 38),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih nama pengguna anda',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Lengkapkan langkah ini sebelum akaun anda boleh '
                          'digunakan.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 34),
                        TextField(
                          key: const Key('social-username-field'),
                          controller: _usernameController,
                          autofocus: true,
                          maxLength: 20,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_canSubmit) _submit();
                          },
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'NamaPetani',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.48,
                              ),
                              fontSize: 18,
                            ),
                            errorText: _errorText,
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: const BorderSide(
                                color: AppColors.green,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: const BorderSide(
                                color: Color(0xFFB42318),
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: borderRadius,
                              borderSide: const BorderSide(
                                color: Color(0xFFB42318),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_usernameController.text.characters.length}/20',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  key: const Key('social-username-submit-button'),
                  label: _isSubmitting ? 'Menyimpan...' : 'Selesai',
                  onPressed: _canSubmit ? _submit : null,
                  height: 58,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
