import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/report/controllers/report_controller.dart';
import 'package:petani/report/models/report_summary.dart';

class MonthlyPlantBarChart extends StatefulWidget {
  const MonthlyPlantBarChart({
    required this.data,
    required this.year,
    required this.initialMonth,
    super.key,
  });

  final MonthlyPlantingData data;
  final int year;
  final int initialMonth;

  @override
  State<MonthlyPlantBarChart> createState() => _MonthlyPlantBarChartState();
}

class _MonthlyPlantBarChartState extends State<MonthlyPlantBarChart> {
  static const _chartWidth = 720.0;
  static const _chartHeight = 290.0;
  static const _leftInset = 42.0;
  static const _rightInset = 18.0;

  final _scrollController = ScrollController();
  late int _selectedMonth;

  double get _monthWidth => (_chartWidth - _leftInset - _rightInset) / 12;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth.clamp(0, 11);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelection());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerSelection() {
    if (!mounted || !_scrollController.hasClients) return;
    final x = _leftInset + (_selectedMonth + 0.5) * _monthWidth;
    _scrollController.jumpTo(
      (x - _scrollController.position.viewportDimension / 2).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  void _selectMonth(double x) {
    final next = ((x - _leftInset) / _monthWidth).floor().clamp(0, 11);
    if (_selectedMonth == next) return;
    setState(() => _selectedMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final selectedValue = widget.data.plantCount[_selectedMonth];
    final markerX = _leftInset + (_selectedMonth + 0.5) * _monthWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rekod Tanaman',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          key: const Key('monthly-plant-bar-card'),
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pokok Mengikut Bulan Tanam',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Jumlah anak pokok direkodkan · ${widget.year}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                key: const Key('monthly-plant-bar-scroll'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _selectMonth(details.localPosition.dx),
                  onHorizontalDragUpdate: (details) =>
                      _selectMonth(details.localPosition.dx),
                  child: Semantics(
                    label: 'Jumlah pokok mengikut bulan tanam',
                    value:
                        '${ReportController.monthNames[_selectedMonth]}: '
                        '${_formatNumber(selectedValue)} pokok',
                    child: SizedBox(
                      width: _chartWidth,
                      height: _chartHeight,
                      child: Stack(
                        children: [
                          CustomPaint(
                            key: const Key('monthly-plant-bar-chart'),
                            size: const Size(_chartWidth, _chartHeight),
                            painter: _MonthlyPlantBarPainter(
                              values: widget.data.plantCount,
                              selectedMonth: _selectedMonth,
                            ),
                          ),
                          Positioned(
                            left: (markerX - 64).clamp(8.0, _chartWidth - 136),
                            top: 5,
                            width: 128,
                            child: IgnorePointer(
                              child: Container(
                                key: const Key('monthly-plant-bar-tooltip'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forest,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  '${_formatNumber(selectedValue)} pokok',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Nilai mengikut tarikh tanam plot.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyPlantBarPainter extends CustomPainter {
  const _MonthlyPlantBarPainter({
    required this.values,
    required this.selectedMonth,
  });

  static const _left = 42.0;
  static const _right = 18.0;
  static const _top = 48.0;
  static const _bottom = 34.0;

  final List<int> values;
  final int selectedMonth;

  @override
  void paint(Canvas canvas, Size size) {
    final maximumValue = values.fold<int>(0, math.max);
    final maximum = math.max(1, maximumValue);
    final plotBottom = size.height - _bottom;
    final plotHeight = plotBottom - _top;
    final plotWidth = size.width - _left - _right;
    final slotWidth = plotWidth / 12;

    final gridPaint = Paint()
      ..color = const Color(0xFFD7DDD9)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = _top + index * plotHeight / 3;
      _drawDottedLine(
        canvas,
        Offset(_left, y),
        Offset(size.width - _right, y),
        gridPaint,
      );
      final value = (maximum * (3 - index) / 3).round();
      _paintLabel(
        canvas,
        _compactNumber(value),
        Offset(_left - 8, y),
        anchorRight: true,
      );
    }

    for (var month = 0; month < 12; month++) {
      final centerX = _left + (month + 0.5) * slotWidth;
      final height = values[month] / maximum * plotHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - 16,
          plotBottom - height,
          32,
          math.max(height, 2),
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = month == selectedMonth
              ? AppColors.yellow
              : AppColors.primaryAction.withValues(alpha: 0.72),
      );
      _paintLabel(
        canvas,
        ReportController.shortMonthNames[month],
        Offset(centerX, plotBottom + 19),
        color: month == selectedMonth ? AppColors.ink : AppColors.muted,
        fontWeight: month == selectedMonth ? FontWeight.w700 : FontWeight.w400,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyPlantBarPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedMonth != selectedMonth;
  }
}

void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  const dash = 2.0;
  const gap = 4.0;
  var x = start.dx;
  while (x < end.dx) {
    canvas.drawLine(
      Offset(x, start.dy),
      Offset(math.min(x + dash, end.dx), end.dy),
      paint,
    );
    x += dash + gap;
  }
}

void _paintLabel(
  Canvas canvas,
  String text,
  Offset center, {
  bool anchorRight = false,
  Color color = AppColors.muted,
  FontWeight fontWeight = FontWeight.w400,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontFamily: 'ProductSans',
        fontSize: 11,
        fontWeight: fontWeight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(
      anchorRight ? center.dx - painter.width : center.dx - painter.width / 2,
      center.dy - painter.height / 2,
    ),
  );
}

String _formatNumber(int value) {
  final digits = '$value';
  final result = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write(',');
    result.write(digits[index]);
  }
  return result.toString();
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    final amount = value / 1000000;
    return '${amount.toStringAsFixed(amount >= 10 ? 0 : 1)}j';
  }
  if (value >= 1000) {
    final amount = value / 1000;
    return '${amount.toStringAsFixed(amount >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
