import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/reports/data/reports_api.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/presentation/report_ui.dart';
import 'package:university_messenger/features/reports/report_strings.dart';

class ModeratorReportScreen extends ConsumerStatefulWidget {
  const ModeratorReportScreen({required this.initialReport, super.key});

  final ReportRecord initialReport;

  @override
  ConsumerState<ModeratorReportScreen> createState() =>
      _ModeratorReportScreenState();
}

class _ModeratorReportScreenState extends ConsumerState<ModeratorReportScreen> {
  late ReportRecord _report = widget.initialReport;
  List<ReportEvidenceMessage>? _evidence;
  String? _actionError;
  String? _evidenceError;
  bool _claiming = false;
  bool _loadingEvidence = false;
  bool _resolving = false;
  bool _autoEvidenceRequested = false;

  String? get _accountId => ref.read(authControllerProvider).state.account?.id;

  bool get _isMine => _report.assignedTo == _accountId;

  Future<void> _claim() async {
    setState(() {
      _claiming = true;
      _actionError = null;
    });
    try {
      final report = await ReportsApi(
        ref.read(apiClientProvider),
      ).claimReport(_report.id);
      if (!mounted) return;
      setState(() {
        _report = report;
        _claiming = false;
      });
      await _loadEvidence();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = reportErrorText(error);
        _claiming = false;
      });
    }
  }

  Future<void> _loadEvidence() async {
    if (!_isMine || _report.conversationId == null) return;
    setState(() {
      _loadingEvidence = true;
      _evidenceError = null;
    });
    try {
      final evidence = await ReportsApi(
        ref.read(apiClientProvider),
      ).listEvidence(_report.id);
      if (!mounted) return;
      setState(() {
        _evidence = evidence;
        _loadingEvidence = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _evidenceError = reportErrorText(error);
        _loadingEvidence = false;
      });
    }
  }

  Future<void> _showResolveSheet() async {
    final draft = await showModalBottomSheet<_ResolutionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ResolveSheet(report: _report),
    );
    if (draft == null || !mounted) return;
    setState(() {
      _resolving = true;
      _actionError = null;
    });
    try {
      final report = await ReportsApi(ref.read(apiClientProvider))
          .resolveReport(
            reportId: _report.id,
            outcome: draft.outcome,
            note: draft.note,
          );
      if (!mounted) return;
      setState(() {
        _report = report;
        _evidence = null;
        _resolving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportStrings.reportResolved)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = reportErrorText(error);
        _resolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authControllerProvider).state.account;
    if (account?.role != UserRole.moderator) {
      return Scaffold(
        appBar: AppBar(title: const Text(ReportStrings.reportDetails)),
        body: const SafeArea(
          child: ReportEmptyState(
            icon: Icons.lock_outline_rounded,
            title: ReportStrings.moderationAccessTitle,
            body: ReportStrings.moderationAccessBody,
          ),
        ),
      );
    }
    if (_isMine &&
        _report.status == ReportStatus.assigned &&
        _report.conversationId != null &&
        !_autoEvidenceRequested) {
      _autoEvidenceRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadEvidence();
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text(ReportStrings.reportDetails)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReportSummary(report: _report),
                  if (_actionError != null) ...[
                    const SizedBox(height: 16),
                    ReportErrorPanel(message: _actionError!),
                  ],
                  const SizedBox(height: 24),
                  if (_report.status == ReportStatus.open &&
                      _report.assignedTo == null)
                    _ClaimPanel(loading: _claiming, onClaim: _claim)
                  else if (!_isMine && _report.status == ReportStatus.assigned)
                    const ReportErrorPanel(
                      message: ReportStrings.assignedElsewhere,
                    ),
                  if (_report.status == ReportStatus.resolved ||
                      _report.status == ReportStatus.dismissed) ...[
                    _ResolvedPanel(report: _report),
                  ] else ...[
                    const SizedBox(height: 24),
                    _EvidenceHeader(reportId: _report.id),
                    const SizedBox(height: 12),
                    _buildEvidence(),
                    if (_isMine) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _resolving ? null : _showResolveSheet,
                        icon: _resolving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.task_alt_rounded),
                        label: Text(
                          _resolving
                              ? ReportStrings.resolvingReport
                              : ReportStrings.resolveReport,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidence() {
    if (_report.conversationId == null) {
      return const ReportEmptyState(
        icon: Icons.comments_disabled_outlined,
        title: ReportStrings.evidenceTitle,
        body: ReportStrings.noConversationEvidence,
      );
    }
    if (!_isMine) {
      return const ReportEmptyState(
        icon: Icons.lock_outline_rounded,
        title: ReportStrings.evidenceTitle,
        body: ReportStrings.evidenceAfterClaim,
      );
    }
    if (_loadingEvidence && _evidence == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Semantics(
            label: ReportStrings.loadingEvidence,
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (_evidenceError != null && _evidence == null) {
      return ReportErrorPanel(message: _evidenceError!, onRetry: _loadEvidence);
    }
    final evidence = _evidence ?? const <ReportEvidenceMessage>[];
    if (evidence.isEmpty) {
      return const ReportEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: ReportStrings.evidenceTitle,
        body: ReportStrings.noEvidenceMessages,
      );
    }
    return Column(
      children: [
        if (_evidenceError != null) ...[
          ReportErrorPanel(message: _evidenceError!, onRetry: _loadEvidence),
          const SizedBox(height: 10),
        ],
        for (final message in evidence) ...[
          _EvidenceMessageTile(
            message: message,
            reported: message.id == _report.messageId,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final ReportRecord report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                report.reason,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reportStatusLabel(report.status),
                style: TextStyle(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ReportDetailRow(
          label: ReportStrings.reportId,
          value: report.id,
          forceLtr: true,
        ),
        ReportDetailRow(
          label: ReportStrings.reporterId,
          value: report.reporterId,
          forceLtr: true,
        ),
        ReportDetailRow(
          label: ReportStrings.target,
          value: reportTargetLabel(report.targetType),
        ),
        ReportDetailRow(
          label: ReportStrings.targetId,
          value: report.targetId,
          forceLtr: true,
        ),
        if (report.conversationId case final id?)
          ReportDetailRow(
            label: ReportStrings.conversationId,
            value: id,
            forceLtr: true,
          ),
        if (report.messageId case final id?)
          ReportDetailRow(
            label: ReportStrings.messageId,
            value: id,
            forceLtr: true,
          ),
        ReportDetailRow(
          label: ReportStrings.submittedOn,
          value: reportDateTime(context, report.createdAt),
        ),
        const SizedBox(height: 14),
        Text(
          ReportStrings.reportNote,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Directionality(
          textDirection: reportTextDirection(
            report.note?.isNotEmpty == true
                ? report.note!
                : ReportStrings.noNote,
          ),
          child: Text(
            report.note?.isNotEmpty == true
                ? report.note!
                : ReportStrings.noNote,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _ClaimPanel extends StatelessWidget {
  const _ClaimPanel({required this.loading, required this.onClaim});

  final bool loading;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ReportStrings.claimBody,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: loading ? null : onClaim,
            icon: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.assignment_ind_outlined),
            label: Text(
              loading
                  ? ReportStrings.claimingReport
                  : ReportStrings.claimReport,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceHeader extends StatelessWidget {
  const _EvidenceHeader({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.policy_outlined, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ReportStrings.evidenceAccess} #${shortIdentifier(reportId)}',
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ReportStrings.evidenceAccessBody,
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceMessageTile extends StatelessWidget {
  const _EvidenceMessageTile({required this.message, required this.reported});

  final ReportEvidenceMessage message;
  final bool reported;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = message.deletedAt == null
        ? message.body ?? '${ReportStrings.messageType}: ${message.type}'
        : ReportStrings.deletedMessage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reported ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (reported)
                Text(
                  ReportStrings.reportedMessage,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                '${ReportStrings.sender}: ${shortIdentifier(message.senderId)}',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                '${ReportStrings.sequence}: ${message.sequence}',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                reportDateTime(context, message.createdAt),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Directionality(
            textDirection: reportTextDirection(body),
            child: SelectableText(body, style: const TextStyle(height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _ResolvedPanel extends StatelessWidget {
  const _ResolvedPanel({required this.report});

  final ReportRecord report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outcome = report.resolutionOutcome;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outcome == null
                ? ReportStrings.reportResolved
                : resolutionOutcomeLabel(outcome),
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ReportStrings.resolvedBody,
            style: TextStyle(color: scheme.onSecondaryContainer),
          ),
          if (report.resolutionNote case final note?) ...[
            const SizedBox(height: 8),
            Text(
              '${ReportStrings.moderatorNote}: $note',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolutionDraft {
  const _ResolutionDraft({required this.outcome, this.note});

  final ResolutionOutcome outcome;
  final String? note;
}

class _ResolveSheet extends StatefulWidget {
  const _ResolveSheet({required this.report});

  final ReportRecord report;

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  ResolutionOutcome? _outcome;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<(ResolutionOutcome, String, String)> get _options => [
    (
      ResolutionOutcome.dismiss,
      ReportStrings.dismissAction,
      ReportStrings.dismissDescription,
    ),
    if (widget.report.messageId != null)
      (
        ResolutionOutcome.removeContent,
        ReportStrings.removeContentAction,
        ReportStrings.removeContentDescription,
      ),
    if (widget.report.targetType == ReportTargetType.user ||
        widget.report.targetType == ReportTargetType.message)
      (
        ResolutionOutcome.ban,
        ReportStrings.banAction,
        ReportStrings.banDescription,
      ),
  ];

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final outcome = _outcome;
    if (outcome == null) return;
    final note = _noteController.text.trim();
    Navigator.of(
      context,
    ).pop(_ResolutionDraft(outcome: outcome, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ReportStrings.resolveReport,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              ReportStrings.resolutionFinal,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in _options)
              Semantics(
                selected: _outcome == option.$1,
                button: true,
                child: ListTile(
                  onTap: () => setState(() => _outcome = option.$1),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _outcome == option.$1
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  title: Text(option.$2),
                  subtitle: Text(option.$3),
                ),
              ),
            TextFormField(
              controller: _noteController,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: ReportStrings.resolutionNote,
                hintText: ReportStrings.resolutionNoteHint,
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.length ?? 0) > 500
                  ? ReportStrings.resolutionNoteTooLong
                  : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _outcome == null ? null : _submit,
              child: const Text(ReportStrings.resolveReport),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(ReportStrings.cancel),
            ),
          ],
        ),
      ),
    ),
  );
}
