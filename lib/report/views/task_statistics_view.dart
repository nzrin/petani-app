import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/report/controllers/report_controller.dart';
import 'package:petani/report/models/report_summary.dart';

class TaskStatisticsView extends StatefulWidget {
  const TaskStatisticsView({required this.controller, super.key});

  final ReportController controller;

  @override
  State<TaskStatisticsView> createState() => _TaskStatisticsViewState();
}

class _TaskStatisticsViewState extends State<TaskStatisticsView> {
  static const _plotHeight = 200.0;
  static const _horizontalInset = 32.0;

  final _scrollController = ScrollController();
  final _plotKey = GlobalKey();
  final _viewportKey = GlobalKey();
  Timer? _dragTimer;
  Offset? _dragPosition;
  double _plotWidth = 812;

  ReportController get _controller => widget.controller;
  double get _monthWidth => (_plotWidth - 2 * _horizontalInset) / 11;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelectedMonth());
  }

  @override
  void dispose() {
    _dragTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _centerSelectedMonth() {
    if (!mounted || !_scrollController.hasClients) return;
    final x = _horizontalInset + _controller.selectedMonth * _monthWidth;
    _scrollController.jumpTo(
      (x - _scrollController.position.viewportDimension / 2).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  void _selectAt(Offset globalPosition) {
    final box = _plotKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final x = box.globalToLocal(globalPosition).dx;
    _controller.selectMonth(((x - _horizontalInset) / _monthWidth).round());
  }

  void _startDrag(DragStartDetails details) {
    _dragPosition = details.globalPosition;
    _selectAt(details.globalPosition);
    _dragTimer?.cancel();
    _dragTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final position = _dragPosition;
      final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
      if (position == null || box == null || !_scrollController.hasClients) {
        return;
      }
      final x = box.globalToLocal(position).dx;
      final delta = x < 44 ? -8.0 : (x > box.size.width - 44 ? 8.0 : 0.0);
      if (delta == 0) return;
      _scrollController.jumpTo(
        (_scrollController.offset + delta).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
      );
      _selectAt(position);
    });
  }

  void _endDrag() {
    _dragTimer?.cancel();
    _dragTimer = null;
    _dragPosition = null;
  }

  void _stepMonth(int delta) {
    _controller.selectMonth(_controller.selectedMonth + delta);
    if (!_scrollController.hasClients) return;
    final x = _horizontalInset + _controller.selectedMonth * _monthWidth;
    _scrollController.animateTo(
      (x - _scrollController.position.viewportDimension / 2).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final status = _controller.selectedStatus;
        final color = _statusColor(status);
        final foreground = status == TaskReportStatus.pending
            ? AppColors.ink
            : Colors.white;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aktiviti Tugasan',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('task-statistics-card'),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, Color.lerp(color, Colors.white, 0.12)!],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Row(
                      children: [
                        for (final option in TaskReportStatus.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Semantics(
                                selected: option == status,
                                child: TextButton(
                                  key: ValueKey<String>(
                                    'task-status-${option.name}',
                                  ),
                                  onPressed: () =>
                                      _controller.selectStatus(option),
                                  style: TextButton.styleFrom(
                                    foregroundColor: foreground,
                                    backgroundColor: option == status
                                        ? foreground.withValues(alpha: 0.18)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 12,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(option.label),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status.label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${_controller.selectedTotal}',
                    key: const Key('task-statistics-total'),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jumlah tugasan · ${_controller.selectedMonthName}',
                    style: TextStyle(color: foreground, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${status.label} · Data kebun ${_controller.year}',
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      _plotWidth = math.max(constraints.maxWidth, 812);
                      final points = _points(_controller.values, _plotWidth);
                      final selected = points[_controller.selectedMonth];
                      return SingleChildScrollView(
                        key: _viewportKey,
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) =>
                              _selectAt(details.globalPosition),
                          child: SizedBox(
                            key: _plotKey,
                            width: _plotWidth,
                            height: _plotHeight + 48,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: _plotHeight,
                                  child: CustomPaint(
                                    key: const Key('task-statistics-chart'),
                                    painter: _TaskChartPainter(
                                      points: points,
                                      foreground: foreground,
                                      selectedMonth: _controller.selectedMonth,
                                    ),
                                  ),
                                ),
                                for (var month = 0; month < 12; month++)
                                  Positioned(
                                    left:
                                        _horizontalInset +
                                        month * _monthWidth -
                                        30,
                                    top: _plotHeight,
                                    width: 60,
                                    height: 48,
                                    child: Semantics(
                                      button: true,
                                      selected:
                                          month == _controller.selectedMonth,
                                      label:
                                          '${ReportController.monthNames[month]}, '
                                          '${_controller.values[month]} tugasan',
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            _controller.selectMonth(month),
                                        child: Center(
                                          child: Text(
                                            _shortMonth(month),
                                            style: TextStyle(
                                              color: foreground.withValues(
                                                alpha:
                                                    month ==
                                                        _controller
                                                            .selectedMonth
                                                    ? 1
                                                    : 0.75,
                                              ),
                                              fontSize: 13,
                                              fontWeight:
                                                  month ==
                                                      _controller.selectedMonth
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  left: selected.dx - 24,
                                  top: selected.dy - 24,
                                  width: 48,
                                  height: 48,
                                  child: Semantics(
                                    label: 'Bulan dipilih',
                                    value:
                                        '${_controller.selectedMonthName}, '
                                        '${_controller.selectedTotal} tugasan',
                                    increasedValue:
                                        _controller.selectedMonth < 11
                                        ? ReportController
                                              .monthNames[_controller
                                                  .selectedMonth +
                                              1]
                                        : null,
                                    decreasedValue:
                                        _controller.selectedMonth > 0
                                        ? ReportController
                                              .monthNames[_controller
                                                  .selectedMonth -
                                              1]
                                        : null,
                                    onIncrease: _controller.selectedMonth < 11
                                        ? () => _stepMonth(1)
                                        : null,
                                    onDecrease: _controller.selectedMonth > 0
                                        ? () => _stepMonth(-1)
                                        : null,
                                    child: GestureDetector(
                                      key: const Key('task-chart-marker'),
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: _startDrag,
                                      onPanUpdate: (details) {
                                        _dragPosition = details.globalPosition;
                                        _selectAt(details.globalPosition);
                                      },
                                      onPanEnd: (_) => _endDrag(),
                                      onPanCancel: _endDrag,
                                      child: Center(
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: foreground.withValues(
                                              alpha: 0.22,
                                            ),
                                            border: Border.all(
                                              color: foreground.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: foreground,
                                                shape: BoxShape.circle,
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
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                    child: Text(
                      'Seret bulatan untuk pilih bulan · Leret untuk teroka',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static List<Offset> _points(List<int> values, double width) {
    final peak = values.fold<int>(0, math.max);
    final maximum = math.max(1.0, peak * 1.15);
    return [
      for (var index = 0; index < values.length; index++)
        Offset(
          _horizontalInset + index * (width - 2 * _horizontalInset) / 11,
          _plotHeight - 24 - values[index] / maximum * (_plotHeight - 48),
        ),
    ];
  }
}

class _TaskChartPainter extends CustomPainter {
  const _TaskChartPainter({
    required this.points,
    required this.foreground,
    required this.selectedMonth,
  });

  final List<Offset> points;
  final Color foreground;
  final int selectedMonth;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = foreground.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = 24 + index * (size.height - 48) / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final point = points[index];
      final middle = (previous.dx + point.dx) / 2;
      path.cubicTo(middle, previous.dy, middle, point.dy, point.dx, point.dy);
    }

    final area = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            foreground.withValues(alpha: 0.18),
            foreground.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawLine(
      points[selectedMonth],
      Offset(points[selectedMonth].dx, size.height),
      gridPaint,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = foreground.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TaskChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.foreground != foreground ||
        oldDelegate.selectedMonth != selectedMonth;
  }
}

Color _statusColor(TaskReportStatus status) => switch (status) {
  TaskReportStatus.pending => AppColors.yellow,
  TaskReportStatus.completed => AppColors.primaryAction,
  TaskReportStatus.overdue => const Color(0xFFC62828),
};

String _shortMonth(int month) => const [
  'Jan',
  'Feb',
  'Mac',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Ogo',
  'Sep',
  'Okt',
  'Nov',
  'Dis',
][month];
