import 'package:flutter/material.dart';
import 'package:university_messenger/app/theme/app_tokens.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class ServiceStatusChip extends StatelessWidget {
  const ServiceStatusChip({required this.status, super.key});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final (background, foreground, icon) = switch (status) {
      ServiceRequestStatus.completed ||
      ServiceRequestStatus.deliveredDigitally => (
        tokens.success.withValues(alpha: 0.14),
        tokens.success,
        Icons.check_circle_outline_rounded,
      ),
      ServiceRequestStatus.approved || ServiceRequestStatus.readyForPickup => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.task_alt_rounded,
      ),
      ServiceRequestStatus.rejected || ServiceRequestStatus.cancelled => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.cancel_outlined,
      ),
      ServiceRequestStatus.needsInfo => (
        tokens.warning.withValues(alpha: 0.15),
        tokens.warning,
        Icons.info_outline_rounded,
      ),
      _ => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.schedule_rounded,
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 18, color: foreground),
      label: Text(serviceStatusLabel(context.l10n, status)),
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class ServiceEmptyState extends StatelessWidget {
  const ServiceEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

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
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class ServiceErrorState extends StatelessWidget {
  const ServiceErrorState({
    required this.title,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final String title;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ServiceEmptyState(
    icon: Icons.cloud_off_rounded,
    title: title,
    body: serviceErrorMessage(context.l10n, error),
    action: FilledButton.tonalIcon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(context.l10n.retry),
    ),
  );
}

class ServiceSection extends StatelessWidget {
  const ServiceSection({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}

String serviceStatusLabel(AppLocalizations l10n, ServiceRequestStatus status) =>
    switch (status) {
      ServiceRequestStatus.draft => l10n.serviceDraft,
      ServiceRequestStatus.submitted => l10n.submitted,
      ServiceRequestStatus.inReview => l10n.serviceInReview,
      ServiceRequestStatus.needsInfo => l10n.serviceNeedsInfo,
      ServiceRequestStatus.approved => l10n.serviceApproved,
      ServiceRequestStatus.rejected => l10n.serviceRejected,
      ServiceRequestStatus.readyForPickup => l10n.serviceReadyForPickup,
      ServiceRequestStatus.deliveredDigitally => l10n.serviceDeliveredDigitally,
      ServiceRequestStatus.completed => l10n.serviceCompleted,
      ServiceRequestStatus.cancelled => l10n.serviceCancelled,
      ServiceRequestStatus.unknown => l10n.serviceUnknownStatus,
    };

String serviceEventLabel(AppLocalizations l10n, String kind) {
  if (kind.startsWith('status:')) {
    final status = ServiceRequestStatus.fromJson(kind.substring(7));
    return l10n.serviceEventStatusChanged(serviceStatusLabel(l10n, status));
  }
  return switch (kind) {
    'submitted' => l10n.serviceRequestSubmitted,
    'claimed' => l10n.serviceEventClaimed,
    'result_uploaded' => l10n.serviceEventResultUploaded,
    'cancelled' => l10n.serviceRequestCancelled,
    _ => l10n.serviceUnknownEvent,
  };
}

String serviceErrorMessage(AppLocalizations l10n, Object error) {
  final code = apiErrorCode(error);
  return switch (code) {
    'service_request_not_found' => l10n.serviceRequestMissing,
    'service_type_not_found' => l10n.serviceTypeMissing,
    'service_requirements_missing' => l10n.serviceRequirementsMissing,
    'invalid_document' ||
    'invalid_result_document' ||
    'invalid_attachment' => l10n.serviceDocumentUnavailable,
    'already_assigned' => l10n.serviceAlreadyAssigned,
    'invalid_status_transition' => l10n.serviceInvalidTransition,
    'request_not_cancellable' => l10n.serviceCannotCancel,
    _ => localizedMediaError(l10n, error, localizedApiError(l10n, code)),
  };
}

String serviceFieldLabel(AppLocalizations l10n, String key) =>
    switch (key.toLowerCase()) {
      'name' || 'full_name' => l10n.name,
      'first_name' => l10n.firstName,
      'last_name' => l10n.lastName,
      'student_id' || 'university_id' => l10n.universityId,
      'national_id' => l10n.nationalId,
      'department' => l10n.department,
      'degree' => l10n.degree,
      'phone' || 'phone_number' => l10n.phoneLabel,
      'email' => l10n.serviceEmail,
      'date' => l10n.serviceDate,
      'note' || 'notes' => l10n.serviceNote,
      _ => l10n.serviceFieldIdentifier('\u2068$key\u2069'),
    };

String formatServiceDate(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return context.l10n.dateAndTime(date, time);
}

String shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
