import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/authenticated_media.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';
import 'package:university_messenger/features/services/presentation/service_strings.dart';
import 'package:university_messenger/features/services/presentation/service_widgets.dart';
import 'package:university_messenger/features/services/services_providers.dart';
import 'package:university_messenger/features/services/services_routes.dart';

class ServiceRequestDetailScreen extends ConsumerStatefulWidget {
  const ServiceRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends ConsumerState<ServiceRequestDetailScreen> {
  var _acting = false;

  Future<void> _runAction(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    setState(() => _acting = true);
    try {
      await action();
      ref.invalidate(serviceRequestDetailProvider(widget.requestId));
      ref.invalidate(serviceRequestsProvider);
      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(serviceErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ServiceStrings.cancellationTitle),
        content: const Text(ServiceStrings.cancellationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(ServiceStrings.keepRequest),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(ServiceStrings.cancelRequest),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() async {
      await ref.read(servicesApiProvider).cancel(widget.requestId);
    }, successMessage: ServiceStrings.requestCancelled);
  }

  Future<void> _changeStatus(ServiceRequestDetail detail) async {
    final transitions =
        allowedStaffStatusTransitions[detail.status] ?? const [];
    if (transitions.isEmpty) return;
    final change = await showDialog<_StatusChange>(
      context: context,
      builder: (_) => _StatusChangeDialog(transitions: transitions),
    );
    if (change == null) return;
    await _runAction(() async {
      await ref
          .read(servicesApiProvider)
          .changeStatus(widget.requestId, change.status, note: change.note);
    });
  }

  Future<void> _associateResult(ServiceRequestDetail detail) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PDF documents', extensions: ['pdf']),
      ],
    );
    if (file == null) return;
    await _runAction(() async {
      final media = await ref.read(mediaClientProvider).upload(file);
      await ref
          .read(servicesApiProvider)
          .associateResult(widget.requestId, media.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(serviceRealtimeSyncProvider);
    final detail = ref.watch(serviceRequestDetailProvider(widget.requestId));
    final catalog = ref.watch(serviceCatalogProvider).valueOrNull ?? const [];
    final role = ref.watch(authControllerProvider).state.account?.role;
    return Scaffold(
      appBar: AppBar(title: const Text(ServiceStrings.requestDetails)),
      body: SafeArea(
        top: false,
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ServiceErrorState(
            title: ServiceStrings.loadRequestError,
            error: error,
            onRetry: () =>
                ref.invalidate(serviceRequestDetailProvider(widget.requestId)),
          ),
          data: (request) {
            final service = catalog
                .where((item) => item.id == request.serviceTypeId)
                .firstOrNull;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(serviceRequestDetailProvider(widget.requestId));
                await ref.read(
                  serviceRequestDetailProvider(widget.requestId).future,
                );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      24,
                      20,
                      36,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _DetailContent(
                            detail: request,
                            service: service,
                            isStaff: role == UserRole.staff,
                            acting: _acting,
                            onCancel: _cancelRequest,
                            onChangeStatus: () => _changeStatus(request),
                            onAssociateResult: () => _associateResult(request),
                            onChat: () => context.push(
                              ServiceRoutes.ticketChat(widget.requestId),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.service,
    required this.isStaff,
    required this.acting,
    required this.onCancel,
    required this.onChangeStatus,
    required this.onAssociateResult,
    required this.onChat,
  });

  final ServiceRequestDetail detail;
  final ServiceType? service;
  final bool isStaff;
  final bool acting;
  final VoidCallback onCancel;
  final VoidCallback onChangeStatus;
  final VoidCallback onAssociateResult;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final transitions =
        allowedStaffStatusTransitions[detail.status] ?? const [];
    final regularDocuments = detail.documents
        .where((document) => document.kind != 'result')
        .toList();
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final summary = _RequestSummary(detail: detail, service: service);
    final actions = _RequestActions(
      detail: detail,
      isStaff: isStaff,
      acting: acting,
      canChangeStatus: transitions.isNotEmpty,
      onCancel: onCancel,
      onChangeStatus: onChangeStatus,
      onAssociateResult: onAssociateResult,
      onChat: onChat,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: summary),
              const SizedBox(width: 24),
              SizedBox(width: 280, child: actions),
            ],
          )
        else ...[
          summary,
          const SizedBox(height: 20),
          actions,
        ],
        const SizedBox(height: 32),
        ServiceSection(
          title: ServiceStrings.requestData,
          child: _RequestData(detail: detail, service: service),
        ),
        const SizedBox(height: 32),
        ServiceSection(
          title: ServiceStrings.documents,
          child: regularDocuments.isEmpty
              ? const Text(ServiceStrings.noDocuments)
              : _DocumentList(documents: regularDocuments),
        ),
        if (detail.resultDocument != null) ...[
          const SizedBox(height: 32),
          ServiceSection(
            title: ServiceStrings.resultDocument,
            child: _DocumentList(documents: [detail.resultDocument!]),
          ),
        ],
        const SizedBox(height: 32),
        ServiceSection(
          title: ServiceStrings.timeline,
          child: detail.timeline.isEmpty
              ? const Text(ServiceStrings.noTimeline)
              : _Timeline(events: detail.timeline),
        ),
      ],
    );
  }
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.detail, required this.service});

  final ServiceRequestDetail detail;
  final ServiceType? service;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        service?.name ?? ServiceStrings.unknownService,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      ServiceStatusChip(status: detail.status),
      const SizedBox(height: 20),
      _InfoLine(
        icon: Icons.tag_rounded,
        label: ServiceStrings.request,
        value: shortId(detail.id),
        ltrValue: true,
      ),
      _InfoLine(
        icon: Icons.update_rounded,
        label: ServiceStrings.lastUpdated,
        value: formatServiceDate(context, detail.updatedAt),
      ),
      _InfoLine(
        icon: Icons.assignment_ind_outlined,
        label: ServiceStrings.assigned,
        value: detail.isAssigned
            ? ServiceStrings.assigned
            : ServiceStrings.unassigned,
      ),
      if (service?.assigneeDepartment.isNotEmpty == true)
        _InfoLine(
          icon: Icons.account_balance_outlined,
          label: ServiceStrings.department,
          value: service!.assigneeDepartment,
        ),
      if (detail.verificationCode != null)
        _InfoLine(
          icon: Icons.verified_outlined,
          label: ServiceStrings.verificationCode,
          value: detail.verificationCode!,
          ltrValue: true,
        ),
    ],
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.ltrValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ltrValue;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Directionality(
                    textDirection: ltrValue
                        ? TextDirection.ltr
                        : Directionality.of(context),
                    child: SelectableText(value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({
    required this.detail,
    required this.isStaff,
    required this.acting,
    required this.canChangeStatus,
    required this.onCancel,
    required this.onChangeStatus,
    required this.onAssociateResult,
    required this.onChat,
  });

  final ServiceRequestDetail detail;
  final bool isStaff;
  final bool acting;
  final bool canChangeStatus;
  final VoidCallback onCancel;
  final VoidCallback onChangeStatus;
  final VoidCallback onAssociateResult;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: acting ? null : onChat,
        icon: const Icon(Icons.forum_outlined),
        label: const Text(ServiceStrings.ticketChat),
      ),
      if (isStaff) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: acting || !canChangeStatus ? null : onChangeStatus,
          icon: const Icon(Icons.change_circle_outlined),
          label: const Text(ServiceStrings.changeStatus),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: acting ? null : onAssociateResult,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(
            detail.resultDocument == null
                ? ServiceStrings.associateResult
                : ServiceStrings.replaceResult,
          ),
        ),
      ] else if (detail.canCancel) ...[
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: acting ? null : onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text(ServiceStrings.cancelRequest),
        ),
      ],
      if (acting) ...[
        const SizedBox(height: 10),
        const LinearProgressIndicator(minHeight: 2),
      ],
    ],
  );
}

class _RequestData extends StatelessWidget {
  const _RequestData({required this.detail, required this.service});

  final ServiceRequestDetail detail;
  final ServiceType? service;

  @override
  Widget build(BuildContext context) {
    if (detail.data.isEmpty) return const Text(ServiceStrings.noRequestData);
    final labels = {
      for (final field
          in service?.requiredFields ?? const <ServiceFieldDefinition>[])
        field.key: field.label,
    };
    return _KeyValueList(values: detail.data, labels: labels);
  }
}

class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.values, required this.labels});

  final Map<String, dynamic> values;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: values.entries.indexed.map((indexed) {
        final entry = indexed.$2;
        final value = entry.value is bool
            ? entry.value as bool
                  ? ServiceStrings.yes
                  : ServiceStrings.no
            : entry.value.toString();
        return Column(
          children: [
            ListTile(
              title: Text(labels[entry.key] ?? entry.key),
              subtitle: SelectableText(value),
            ),
            if (indexed.$1 != values.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        );
      }).toList(),
    ),
  );
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({required this.documents});

  final List<ServiceRequestDocument> documents;

  @override
  Widget build(BuildContext context) => Column(
    children: documents
        .map(
          (document) => AuthenticatedMediaTile(
            mediaId: document.mediaId,
            label: document.kind,
          ),
        )
        .toList(),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<ServiceRequestEvent> events;

  @override
  Widget build(BuildContext context) => Column(
    children: events.indexed.map((indexed) {
      final event = indexed.$2;
      final last = indexed.$1 == events.length - 1;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Icon(
                    last ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (!last)
                    Expanded(
                      child: VerticalDivider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceEventLabel(event.kind),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      formatServiceDate(context, event.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (event.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(event.note!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

class _StatusChange {
  const _StatusChange(this.status, this.note);

  final ServiceRequestStatus status;
  final String? note;
}

class _StatusChangeDialog extends StatefulWidget {
  const _StatusChangeDialog({required this.transitions});

  final List<ServiceRequestStatus> transitions;

  @override
  State<_StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<_StatusChangeDialog> {
  late ServiceRequestStatus _status = widget.transitions.first;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(ServiceStrings.changeStatus),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ServiceRequestStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: ServiceStrings.status),
            items: widget.transitions
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(serviceStatusLabel(status)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _status = value ?? _status),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: ServiceStrings.optionalNote,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(ServiceStrings.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _StatusChange(
            _status,
            _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
        ),
        child: const Text(ServiceStrings.updateStatus),
      ),
    ],
  );
}

class _MediaIdDialog extends StatefulWidget {
  const _MediaIdDialog({
    required this.title,
    required this.help,
    required this.label,
  });

  final String title;
  final String help;
  final String label;

  @override
  State<_MediaIdDialog> createState() => _MediaIdDialogState();
}

class _MediaIdDialogState extends State<_MediaIdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mediaId = TextEditingController();

  @override
  void dispose() {
    _mediaId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.help),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _mediaId,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: widget.label),
                validator: (value) =>
                    isUuid(value ?? '') ? null : ServiceStrings.invalidMediaId,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(ServiceStrings.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() != true) return;
          Navigator.pop(context, _mediaId.text.trim());
        },
        child: Text(widget.title),
      ),
    ],
  );
}
