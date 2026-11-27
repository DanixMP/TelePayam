import 'package:flutter/material.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

String reportTargetLabel(AppLocalizations l10n, ReportTargetType type) =>
    switch (type) {
      ReportTargetType.message => l10n.message,
      ReportTargetType.user => l10n.account,
      ReportTargetType.group => l10n.group,
      ReportTargetType.channel => l10n.channel,
      ReportTargetType.unknown => l10n.reportTargetUnknown,
    };

String reportStatusLabel(AppLocalizations l10n, ReportStatus status) =>
    switch (status) {
      ReportStatus.open => l10n.open,
      ReportStatus.assigned => l10n.reportStatusAssigned,
      ReportStatus.resolved => l10n.reportStatusResolved,
      ReportStatus.dismissed => l10n.reportStatusDismissed,
      ReportStatus.unknown => l10n.unknown,
    };

String resolutionOutcomeLabel(
  AppLocalizations l10n,
  ResolutionOutcome outcome,
) => switch (outcome) {
  ResolutionOutcome.dismiss => l10n.reportStatusDismissed,
  ResolutionOutcome.warn => l10n.reportOutcomeWarn,
  ResolutionOutcome.mute => l10n.reportOutcomeMute,
  ResolutionOutcome.removeContent => l10n.reportOutcomeRemoveContent,
  ResolutionOutcome.ban => l10n.reportOutcomeBan,
  ResolutionOutcome.escalate => l10n.reportOutcomeEscalate,
  ResolutionOutcome.unknown => l10n.reportOutcomeUnknown,
};

String reportErrorText(AppLocalizations l10n, Object error) {
  final code = error is ApiException ? error.code : null;
  return switch (code) {
    'invalid_report_target' => l10n.reportInvalidTargetError,
    'message_required' => l10n.reportMessageRequiredError,
    'report_not_found' || 'message_not_found' => l10n.reportNotFoundError,
    'moderator_conflict' => l10n.reportModeratorConflictError,
    'report_already_assigned' => l10n.reportAlreadyAssignedError,
    'report_grant_required' => l10n.reportEvidenceExpired,
    'report_closed' => l10n.reportClosedError,
    'unsafe_ban_target' => l10n.reportUnsafeBanError,
    _ => localizedApiError(l10n, code),
  };
}

String reportDateTime(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final day = localizations.formatMediumDate(local);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return context.l10n.dateAndTime(day, time);
}

String shortIdentifier(String value) {
  if (value.length <= 12) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
}

TextDirection reportTextDirection(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value)
    ? TextDirection.rtl
    : TextDirection.ltr;

class ReportErrorPanel extends StatelessWidget {
  const ReportErrorPanel({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
                child: Text(context.l10n.retry),
              ),
          ],
        ),
      ),
    );
  }
}

class ReportEmptyState extends StatelessWidget {
  const ReportEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReportDetailRow extends StatelessWidget {
  const ReportDetailRow({
    required this.label,
    required this.value,
    this.forceLtr = false,
    super.key,
  });

  final String label;
  final String value;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Directionality(
            textDirection: forceLtr
                ? TextDirection.ltr
                : reportTextDirection(value),
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}
