import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';

class ProfileLoginCard extends StatelessWidget {
  const ProfileLoginCard({required this.onLogin, super.key});

  final VoidCallback onLogin;

  static const _paragraphs = [
    'Tanpa log masuk, rekod tanaman, projek dan tugasan anda disimpan '
        'dalam peranti ini sahaja. Jika aplikasi dipadam atau peranti hilang, '
        'rekod yang belum disandarkan mungkin tidak dapat dipulihkan.',
    'Dengan log masuk, rekod anda boleh disandarkan ke akaun anda. '
        'Gunakan akaun yang sama untuk mengakses sandaran tersebut apabila '
        'bertukar atau menggunakan peranti lain.',
    'Sandaran memerlukan sambungan internet. Penyegerakan dilakukan apabila '
        'aplikasi dibuka atau disambung semula, serta secara berkala. '
        'Perubahan yang belum disegerakkan masih berada pada peranti ini.',
    'Anda masih boleh menggunakan Petani tanpa log masuk. Log masuk '
        'membantu anda menyimpan sandaran rekod dan memulihkannya kemudian.',
  ];

  Future<void> _showWhyLogin(BuildContext context) async {
    await showAppConfirmationSheet(
      context: context,
      imagePath: 'assets/images/farmer_phone.png',
      title: 'Kenapa mesti Log Masuk',
      description: _paragraphs.join('\n\n'),
      confirmLabel: 'Faham',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('profile-login-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.profileCard),
        border: Border.all(color: AppColors.cellBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0B3D2E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Data Selamat',
                  key: Key('profile-login-title'),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('profile-why-login-button'),
                    onPressed: () => _showWhyLogin(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: AppColors.forest,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 30),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text(
                      'Apa Maksudnya?',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('profile-login-button'),
              onPressed: onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Log Masuk', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
