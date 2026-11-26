import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/reports/data/reports_api.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/presentation/report_ui.dart';
import 'package:university_messenger/features/reports/report_strings.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  List<ReportRecord>? _reports;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final reports = await ReportsApi(
        ref.read(apiClientProvider),
      ).listMyReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = reportErrorText(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(ReportStrings.myReportsTitle),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: ReportStrings.refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_loading && _reports == null) {
      return Center(
        child: Semantics(
          label: ReportStrings.loadingReports,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && _reports == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ReportErrorPanel(message: _error!, onRetry: _load),
          ),
        ),
      );
    }
    final reports = _reports ?? const <ReportRecord>[];
    if (reports.isEmpty) {
      return const ReportEmptyState(
        icon: Icons.outlined_flag_rounded,
        title: ReportStrings.noReportsTitle,
        body: ReportStrings.noReportsBody,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: reports.length + (_error == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (_error != null && index == 0) {
            return ReportErrorPanel(message: _error!, onRetry: _load);
          }
          final reportIndex = index - (_error == null ? 0 : 1);
          return _MyReportCard(report: reports[reportIndex]);
        },
      ),
    );
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({required this.report});

  final ReportRecord report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outcome = report.resolutionOutcome;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_targetIcon(report.targetType), color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reason,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${reportTargetLabel(report.targetType)} | ${reportDateTime(context, report.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: report.status),
              ],
            ),
            if (report.note?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Directionality(
                textDirection: reportTextDirection(report.note!),
                child: Text(report.note!),
              ),
            ],
            const SizedBox(height: 14),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 14),
            if (outcome == null)
              Text(
                ReportStrings.awaitingOutcome,
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else ...[
              Text(
                resolutionOutcomeLabel(outcome),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (report.resolutionNote case final note?) ...[
                const SizedBox(height: 5),
                Text('${ReportStrings.moderatorNote}: $note'),
              ],
              if (report.resolvedAt case final resolvedAt?) ...[
                const SizedBox(height: 5),
                Text(
                  '${ReportStrings.resolvedOn}: ${reportDateTime(context, resolvedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _targetIcon(ReportTargetType type) => switch (type) {
    ReportTargetType.message => Icons.chat_bubble_outline_rounded,
    ReportTargetType.user => Icons.person_outline_rounded,
    ReportTargetType.group => Icons.group_outlined,
    ReportTargetType.channel => Icons.campaign_outlined,
    ReportTargetType.unknown => Icons.help_outline_rounded,
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active =
        status == ReportStatus.open || status == ReportStatus.assigned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        reportStatusLabel(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: active ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
