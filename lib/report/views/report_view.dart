import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/report/controllers/report_controller.dart';
import 'package:petani/report/models/report_summary.dart';
import 'package:petani/report/repositories/report_repository.dart';
import 'package:petani/report/views/monthly_plant_bar_chart.dart';
import 'package:petani/report/views/monthly_task_wave_chart.dart';
import 'package:petani/report/views/task_statistics_view.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key, this.controller});

  final ReportController? controller;

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late final ReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        ReportController(
          repository: SqliteReportRepository(AppDatabase.instance),
        );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.primaryAction,
          onRefresh: _controller.load,
          child: SingleChildScrollView(
            key: const Key('report-scroll-view'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              safePadding.top + 20,
              20,
              safePadding.bottom + 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Ringkasan prestasi tanaman anda.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_controller.isLoading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    key: Key('report-loading-indicator'),
                    color: AppColors.primaryAction,
                    backgroundColor: AppColors.mint,
                    minHeight: 3,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _SummaryCard(_controller.summaries[0])),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(_controller.summaries[1])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _SummaryCard(_controller.summaries[2])),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(_controller.summaries[3])),
                  ],
                ),
                if (_controller.hasError) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Data laporan tidak dapat dimuatkan.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('retry-report-button'),
                        onPressed: _controller.load,
                        child: const Text('Cuba Lagi'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                TaskStatisticsView(controller: _controller),
                const SizedBox(height: 24),
                MonthlyTaskWaveChart(
                  data: _controller.data.taskTrend,
                  year: _controller.year,
                  initialMonth: _controller.selectedMonth,
                ),
                const SizedBox(height: 24),
                MonthlyPlantBarChart(
                  data: _controller.data.plantingTrend,
                  year: _controller.year,
                  initialMonth: _controller.selectedMonth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.summary);

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('report-summary-${summary.label}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(summary.icon, color: AppColors.green, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            summary.value,
            key: ValueKey<String>('report-summary-value-${summary.label}'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            summary.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
