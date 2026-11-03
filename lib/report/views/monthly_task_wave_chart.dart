import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/report/controllers/report_controller.dart';
import 'package:petani/report/models/report_summary.dart';

class MonthlyTaskWaveChart extends StatefulWidget {
  const MonthlyTaskWaveChart({
    required this.data,
    required this.year,
    required this.initialMonth,
    super.key,
  });

  final MonthlyTaskTrendData data;
  final int year;
  final int initialMonth;

  @override
  State<MonthlyTaskWaveChart> createState() => _MonthlyTaskWaveChartState();
}

class _MonthlyTaskWaveChartState extends State<MonthlyTaskWaveChart> {
  static const _chartWidth = 720.0;
  static const _chartHeight = 310.0;
  static const _leftInset = 38.0;
  static const _rightInset = 18.0;

  final _scrollController = ScrollController();
  late int _selectedMonth;

  double get _monthWidth => (_chartWidth - _leftInset - _rightInset) / 11;

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
    final x = _leftInset + _selectedMonth * _monthWidth;
    _scrollController.jumpTo(
      (x - _scrollController.position.viewportDimension / 2).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  void _selectMonth(double x) {
    final next = ((x - _leftInset) / _monthWidth).round().clamp(0, 11);
    if (_selectedMonth == next) return;
    setState(() => _selectedMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final scheduled = widget.data.scheduled[_selectedMonth];
    final completed = widget.data.completed[_selectedMonth];
    final markerX = _leftInset + _selectedMonth * _monthWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Trend Tugasan',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          key: const Key('monthly-task-wave-card'),
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Perancangan & Penyelesaian',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tugasan bulanan · ${widget.year}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _ChartLegend(color: AppColors.yellow, label: 'Dirancang'),
                    _ChartLegend(
                      color: AppColors.primaryAction,
                      label: 'Diselesaikan',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                key: const Key('monthly-task-wave-scroll'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _selectMonth(details.localPosition.dx),
                  onHorizontalDragUpdate: (details) =>
                      _selectMonth(details.localPosition.dx),
                  child: Semantics(
                    label: 'Trend tugasan bulanan',
                    value:
                        '${ReportController.monthNames[_selectedMonth]}: '
                        '$scheduled dirancang, $completed diselesaikan',
                    child: SizedBox(
                      width: _chartWidth,
                      height: _chartHeight,
                      child: Stack(
                        children: [
                          CustomPaint(
                            key: const Key('monthly-task-wave-chart'),
                            size: const Size(_chartWidth, _chartHeight),
                            painter: _MonthlyTaskWavePainter(
                              scheduled: widget.data.scheduled,
                              completed: widget.data.completed,
                              selectedMonth: _selectedMonth,
                            ),
                          ),
                          Positioned(
                            left: (markerX - 88).clamp(8.0, _chartWidth - 184),
                            top: 8,
                            width: 176,
                            child: IgnorePointer(
                              child: Container(
                                key: const Key('monthly-task-wave-tooltip'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forest,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  '${ReportController.shortMonthNames[_selectedMonth]}: '
                                  '$scheduled dirancang · $completed diselesaikan',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
                  'Leret carta untuk melihat bulan lain.',
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

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MonthlyTaskWavePainter extends CustomPainter {
  const _MonthlyTaskWavePainter({
    required this.scheduled,
    required this.completed,
    required this.selectedMonth,
  });

  static const _left = 38.0;
  static const _right = 18.0;
  static const _top = 52.0;
  static const _bottom = 34.0;

  final List<int> scheduled;
  final List<int> completed;
  final int selectedMonth;

  @override
  void paint(Canvas canvas, Size size) {
    final maximumValue = [...scheduled, ...completed].fold<int>(0, math.max);
    final maximum = math.max(1, maximumValue);
    final plotBottom = size.height - _bottom;
    final plotHeight = plotBottom - _top;
    final plotWidth = size.width - _left - _right;

    final scheduledPoints = _points(scheduled, maximum, plotWidth, plotHeight);
    final completedPoints = _points(completed, maximum, plotWidth, plotHeight);

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
      _drawText(
        canvas,
        '$value',
        Offset(_left - 8, y),
        align: TextAlign.right,
        anchorRight: true,
        color: AppColors.muted,
      );
    }

    final selectedX = _left + selectedMonth * plotWidth / 11;
    canvas.drawLine(
      Offset(selectedX, _top),
      Offset(selectedX, plotBottom),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );

    _drawSeries(
      canvas,
      scheduledPoints,
      plotBottom,
      AppColors.yellow,
      AppColors.yellow.withValues(alpha: 0.16),
    );
    _drawSeries(
      canvas,
      completedPoints,
      plotBottom,
      AppColors.primaryAction,
      AppColors.mint.withValues(alpha: 0.72),
    );

    for (var month = 0; month < 12; month++) {
      final x = _left + month * plotWidth / 11;
      _drawText(
        canvas,
        ReportController.shortMonthNames[month],
        Offset(x, plotBottom + 19),
        color: month == selectedMonth ? AppColors.ink : AppColors.muted,
        fontWeight: month == selectedMonth ? FontWeight.w700 : FontWeight.w400,
      );
    }

    for (final point in [
      scheduledPoints[selectedMonth],
      completedPoints[selectedMonth],
    ]) {
      final color = point == scheduledPoints[selectedMonth]
          ? AppColors.yellow
          : AppColors.primaryAction;
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  List<Offset> _points(
    List<int> values,
    int maximum,
    double width,
    double height,
  ) {
    return [
      for (var index = 0; index < 12; index++)
        Offset(
          _left + index * width / 11,
          _top + (1 - values[index] / maximum) * height,
        ),
    ];
  }

  void _drawSeries(
    Canvas canvas,
    List<Offset> points,
    double bottom,
    Color stroke,
    Color fill,
  ) {
    final path = _smoothPath(points);
    final area = Path.from(path)
      ..lineTo(points.last.dx, bottom)
      ..lineTo(points.first.dx, bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final point = points[index];
      final middle = (previous.dx + point.dx) / 2;
      path.cubicTo(middle, previous.dy, middle, point.dy, point.dx, point.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _MonthlyTaskWavePainter oldDelegate) {
    return oldDelegate.scheduled != scheduled ||
        oldDelegate.completed != completed ||
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

void _drawText(
  Canvas canvas,
  String text,
  Offset center, {
  Color color = AppColors.muted,
  FontWeight fontWeight = FontWeight.w400,
  TextAlign align = TextAlign.center,
  bool anchorRight = false,
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
    textAlign: align,
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
