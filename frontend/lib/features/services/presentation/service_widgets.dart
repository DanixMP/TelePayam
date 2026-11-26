import 'package:flutter/material.dart';
import 'package:university_messenger/app/theme/app_tokens.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';
import 'package:university_messenger/features/services/presentation/service_strings.dart';

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
      label: Text(serviceStatusLabel(status)),
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
    body: serviceErrorMessage(error),
    action: FilledButton.tonalIcon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text(ServiceStrings.retry),
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

String serviceStatusLabel(ServiceRequestStatus status) => switch (status) {
  ServiceRequestStatus.draft => ServiceStrings.draft,
  ServiceRequestStatus.submitted => ServiceStrings.submitted,
  ServiceRequestStatus.inReview => ServiceStrings.inReview,
  ServiceRequestStatus.needsInfo => ServiceStrings.needsInfo,
  ServiceRequestStatus.approved => ServiceStrings.approved,
  ServiceRequestStatus.rejected => ServiceStrings.rejected,
  ServiceRequestStatus.readyForPickup => ServiceStrings.readyForPickup,
  ServiceRequestStatus.deliveredDigitally => ServiceStrings.deliveredDigitally,
  ServiceRequestStatus.completed => ServiceStrings.completed,
  ServiceRequestStatus.cancelled => ServiceStrings.cancelled,
  ServiceRequestStatus.unknown => ServiceStrings.unknownStatus,
};

String serviceEventLabel(String kind) {
  if (kind.startsWith('status:')) {
    final status = ServiceRequestStatus.fromJson(kind.substring(7));
    return '${ServiceStrings.eventStatusChanged}: ${serviceStatusLabel(status)}';
  }
  return switch (kind) {
    'submitted' => ServiceStrings.eventSubmitted,
    'claimed' => ServiceStrings.eventClaimed,
    'result_uploaded' => ServiceStrings.eventResultUploaded,
    'cancelled' => ServiceStrings.eventCancelled,
    _ =>
      kind
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' '),
  };
}

String serviceErrorMessage(Object error) => switch (error) {
  ApiException(:final detail) when detail.isNotEmpty => detail,
  _ => ServiceStrings.actionError,
};

String formatServiceDate(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date, $time';
}

String shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

bool isUuid(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
).hasMatch(value.trim());
