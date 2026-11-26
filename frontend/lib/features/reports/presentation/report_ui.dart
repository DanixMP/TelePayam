import 'package:flutter/material.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/report_strings.dart';

String reportTargetLabel(ReportTargetType type) => switch (type) {
  ReportTargetType.message => ReportStrings.targetMessage,
  ReportTargetType.user => ReportStrings.targetUser,
  ReportTargetType.group => ReportStrings.targetGroup,
  ReportTargetType.channel => ReportStrings.targetChannel,
  ReportTargetType.unknown => ReportStrings.targetUnknown,
};

String reportStatusLabel(ReportStatus status) => switch (status) {
  ReportStatus.open => ReportStrings.statusOpen,
  ReportStatus.assigned => ReportStrings.statusAssigned,
  ReportStatus.resolved => ReportStrings.statusResolved,
  ReportStatus.dismissed => ReportStrings.statusDismissed,
  ReportStatus.unknown => ReportStrings.statusUnknown,
};

String resolutionOutcomeLabel(ResolutionOutcome outcome) => switch (outcome) {
  ResolutionOutcome.dismiss => ReportStrings.outcomeDismiss,
  ResolutionOutcome.warn => ReportStrings.outcomeWarn,
  ResolutionOutcome.mute => ReportStrings.outcomeMute,
  ResolutionOutcome.removeContent => ReportStrings.outcomeRemoveContent,
  ResolutionOutcome.ban => ReportStrings.outcomeBan,
  ResolutionOutcome.escalate => ReportStrings.outcomeEscalate,
  ResolutionOutcome.unknown => ReportStrings.outcomeUnknown,
};

String reportErrorText(Object error) {
  final code = error is ApiException ? error.code : null;
  return switch (code) {
    'network_error' => ReportStrings.networkError,
    'invalid_report_target' => ReportStrings.invalidTargetError,
    'message_required' => ReportStrings.messageRequiredError,
    'report_not_found' ||
    'message_not_found' => ReportStrings.reportNotFoundError,
    'moderator_conflict' => ReportStrings.moderatorConflictError,
    'report_already_assigned' => ReportStrings.alreadyAssignedError,
    'report_grant_required' => ReportStrings.evidenceExpired,
    'report_closed' => ReportStrings.reportClosedError,
    'unsafe_ban_target' => ReportStrings.unsafeBanError,
    'forbidden' => ReportStrings.forbiddenError,
    _ => ReportStrings.genericError,
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
  return '$day, $time';
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
                child: const Text(ReportStrings.retry),
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
