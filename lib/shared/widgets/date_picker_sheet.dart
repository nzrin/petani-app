import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';

abstract final class AppDatePickerStyle {
  static const accentColor = AppColors.ink;
  static const textColor = AppColors.ink;
  static const fontSize = 22.0;
  static const fontWeight = FontWeight.w400;
}

class AppDateButton extends StatelessWidget {
  const AppDateButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.fontSize = 15,
    this.icon = Icons.calendar_month_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final double fontSize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F3F2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppDatePickerStyle.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppDatePickerStyle.textColor,
                    fontSize: fontSize,
                    fontWeight: AppDatePickerStyle.fontWeight,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> showAppDatePickerSheet({
  required BuildContext context,
  required DateTime initialDate,
  String title = 'Tarikh Tanam',
  String description = 'Pilih tarikh tanaman anda.',
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) => DatePickerSheet(
      initialDate: initialDate,
      title: title,
      description: description,
    ),
  );
}

class DatePickerSheet extends StatefulWidget {
  const DatePickerSheet({
    required this.initialDate,
    this.title = 'Tarikh Tanam',
    this.description = 'Pilih tarikh tanaman anda.',
    super.key,
  });

  final DateTime initialDate;
  final String title;
  final String description;

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5D9D7),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ColoredBox(
              color: Color(0xFFF7F8F7),
              child: SizedBox(
                height: 230,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    primaryColor: AppDatePickerStyle.accentColor,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: AppDatePickerStyle.textColor,
                        fontFamily: 'ProductSans',
                        fontSize: AppDatePickerStyle.fontSize,
                        fontWeight: AppDatePickerStyle.fontWeight,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    key: const Key('planted-date-picker'),
                    mode: CupertinoDatePickerMode.date,
                    dateOrder: DatePickerDateOrder.dmy,
                    initialDateTime: _selectedDate,
                    minimumDate: DateTime(2000),
                    maximumDate: DateTime(2100),
                    onDateTimeChanged: (date) {
                      _selectedDate = DateUtils.dateOnly(date);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      key: const Key('cancel-date-button'),
                      label: 'Batal',
                      onPressed: () => Navigator.pop(context),
                      foregroundColor: AppColors.green,
                      borderColor: const Color(0xFFB8C8C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      key: const Key('confirm-date-button'),
                      label: 'Sahkan Tarikh',
                      onPressed: () => Navigator.pop(context, _selectedDate),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
