import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/reports/data/reports_api.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/presentation/moderator_report_screen.dart';
import 'package:university_messenger/features/reports/presentation/report_ui.dart';
import 'package:university_messenger/features/reports/report_strings.dart';

typedef OpenModeratorReport = Future<void> Function(ReportRecord report);

class ModeratorQueueScreen extends ConsumerStatefulWidget {
  const ModeratorQueueScreen({this.onOpenReport, super.key});

  final OpenModeratorReport? onOpenReport;

  @override
  ConsumerState<ModeratorQueueScreen> createState() =>
      _ModeratorQueueScreenState();
}

class _ModeratorQueueScreenState extends ConsumerState<ModeratorQueueScreen> {
  List<ReportRecord>? _reports;
  String? _error;
  bool _loading = false;
  bool _requested = false;

  Future<void> _load() async {
    final account = ref.read(authControllerProvider).state.account;
    if (account?.role != UserRole.moderator) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await ReportsApi(
        ref.read(apiClientProvider),
      ).listModerationQueue();
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

  Future<void> _openReport(ReportRecord report) async {
    if (widget.onOpenReport case final callback?) {
      await callback(report);
    } else {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ModeratorReportScreen(initialReport: report),
        ),
      );
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authControllerProvider).state.account;
    final isModerator = account?.role == UserRole.moderator;
    if (isModerator && !_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReportStrings.moderationTitle),
        actions: [
          if (isModerator)
            IconButton(
              onPressed: _loading ? null : _load,
              tooltip: ReportStrings.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: isModerator
            ? _buildQueue()
            : const ReportEmptyState(
                icon: Icons.lock_outline_rounded,
                title: ReportStrings.moderationAccessTitle,
                body: ReportStrings.moderationAccessBody,
              ),
      ),
    );
  }

  Widget _buildQueue() {
    if ((_loading || !_requested) && _reports == null) {
      return Center(
        child: Semantics(
          label: ReportStrings.loadingQueue,
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
        icon: Icons.task_alt_rounded,
        title: ReportStrings.noQueueTitle,
        body: ReportStrings.noQueueBody,
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
          final report = reports[reportIndex];
          return _QueueReportTile(
            report: report,
            currentAccountId: ref
                .read(authControllerProvider)
                .state
                .account!
                .id,
            onTap: () => _openReport(report),
          );
        },
      ),
    );
  }
}

class _QueueReportTile extends StatelessWidget {
  const _QueueReportTile({
    required this.report,
    required this.currentAccountId,
    required this.onTap,
  });

  final ReportRecord report;
  final String currentAccountId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = report.assignedTo == currentAccountId;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 16),
          child: Row(
            children: [
              Icon(
                mine
                    ? Icons.assignment_ind_rounded
                    : Icons.outlined_flag_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reportTargetLabel(report.targetType)} | ${mine ? ReportStrings.assignedToYou : ReportStrings.unassigned}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportDateTime(context, report.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                tooltip: ReportStrings.openReport,
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
