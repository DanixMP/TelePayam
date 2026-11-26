import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/media_client.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';
import 'package:university_messenger/features/services/presentation/service_strings.dart';
import 'package:university_messenger/features/services/presentation/service_widgets.dart';
import 'package:university_messenger/features/services/services_providers.dart';
import 'package:university_messenger/features/services/services_routes.dart';

class ServiceRequestWizardScreen extends ConsumerStatefulWidget {
  const ServiceRequestWizardScreen({required this.serviceTypeId, super.key});

  final String serviceTypeId;

  @override
  ConsumerState<ServiceRequestWizardScreen> createState() =>
      _ServiceRequestWizardScreenState();
}

class _ServiceRequestWizardScreenState
    extends ConsumerState<ServiceRequestWizardScreen> {
  final _detailsKey = GlobalKey<FormState>();
  final _documentsKey = GlobalKey<FormState>();
  final _fieldControllers = <String, TextEditingController>{};
  final _documents = <String, MediaResource>{};
  final _uploadingDocuments = <String>{};
  final _booleans = <String, bool>{};
  final _selections = <String, String?>{};
  String? _initializedServiceId;
  var _step = 0;
  var _submitting = false;

  @override
  void dispose() {
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initialize(ServiceType service) {
    if (_initializedServiceId == service.id) return;
    _initializedServiceId = service.id;
    for (final field in service.requiredFields) {
      if (field.isBoolean) {
        _booleans[field.key] = field.initialValue == 'true';
      } else if (field.isSelect) {
        final initial = field.initialValue;
        _selections[field.key] = field.options.contains(initial)
            ? initial
            : null;
      } else {
        _fieldControllers[field.key] = TextEditingController(
          text: field.initialValue,
        );
      }
    }
  }

  List<String> _steps(ServiceType service) => [
    ServiceStrings.details,
    if (service.requiredDocuments.isNotEmpty) ServiceStrings.documents,
    ServiceStrings.review,
  ];

  bool _validateCurrent(ServiceType service) {
    final steps = _steps(service);
    if (steps[_step] == ServiceStrings.details) {
      return _detailsKey.currentState?.validate() ?? true;
    }
    if (steps[_step] == ServiceStrings.documents) {
      return _documentsKey.currentState?.validate() ?? true;
    }
    return true;
  }

  void _next(ServiceType service) {
    if (!_validateCurrent(service)) return;
    setState(() => _step += 1);
  }

  Map<String, dynamic> _requestData(ServiceType service) => {
    for (final field in service.requiredFields)
      field.key: field.isBoolean
          ? _booleans[field.key] ?? false
          : field.isSelect
          ? _selections[field.key] ?? ''
          : field.isNumeric
          ? num.tryParse(_fieldControllers[field.key]!.text.trim()) ??
                _fieldControllers[field.key]!.text.trim()
          : _fieldControllers[field.key]!.text.trim(),
  };

  Map<String, String> _documentIds(ServiceType service) => {
    for (final document in service.requiredDocuments)
      if (_documents[document] case final media?) document: media.id,
  };

  Future<void> _pickDocument(String kind) async {
    final file = await openFile();
    if (file == null) return;
    setState(() => _uploadingDocuments.add(kind));
    try {
      final media = await ref.read(mediaClientProvider).upload(file);
      if (mounted) setState(() => _documents[kind] = media);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(serviceErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _uploadingDocuments.remove(kind));
    }
  }

  Future<void> _submit(ServiceType service) async {
    setState(() => _submitting = true);
    try {
      final request = await ref
          .read(servicesApiProvider)
          .createRequest(
            serviceTypeId: service.id,
            data: _requestData(service),
            documents: _documentIds(service),
          );
      ref.invalidate(serviceRequestsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ServiceStrings.requestSubmitted)),
      );
      context.pushReplacement(ServiceRoutes.requestDetail(request.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(serviceErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(serviceCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(ServiceStrings.newRequest)),
      body: SafeArea(
        top: false,
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ServiceErrorState(
            title: ServiceStrings.loadServicesError,
            error: error,
            onRetry: () => ref.invalidate(serviceCatalogProvider),
          ),
          data: (items) {
            final service = items
                .where((item) => item.id == widget.serviceTypeId)
                .firstOrNull;
            if (service == null) {
              return const ServiceEmptyState(
                icon: Icons.search_off_rounded,
                title: ServiceStrings.unknownService,
                body: ServiceStrings.loadServicesError,
              );
            }
            _initialize(service);
            return _WizardBody(
              service: service,
              steps: _steps(service),
              step: _step,
              submitting: _submitting,
              fieldControllers: _fieldControllers,
              documentsByKind: _documents,
              uploadingDocuments: _uploadingDocuments,
              booleans: _booleans,
              selections: _selections,
              detailsKey: _detailsKey,
              documentsKey: _documentsKey,
              data: _requestData(service),
              documents: _documentIds(service),
              onBooleanChanged: (key, value) =>
                  setState(() => _booleans[key] = value),
              onSelectionChanged: (key, value) =>
                  setState(() => _selections[key] = value),
              onPickDocument: _pickDocument,
              onBack: () => setState(() => _step -= 1),
              onNext: () => _next(service),
              onSubmit: () => _submit(service),
            );
          },
        ),
      ),
    );
  }
}

class _WizardBody extends StatelessWidget {
  const _WizardBody({
    required this.service,
    required this.steps,
    required this.step,
    required this.submitting,
    required this.fieldControllers,
    required this.documentsByKind,
    required this.uploadingDocuments,
    required this.booleans,
    required this.selections,
    required this.detailsKey,
    required this.documentsKey,
    required this.data,
    required this.documents,
    required this.onBooleanChanged,
    required this.onSelectionChanged,
    required this.onPickDocument,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final ServiceType service;
  final List<String> steps;
  final int step;
  final bool submitting;
  final Map<String, TextEditingController> fieldControllers;
  final Map<String, MediaResource> documentsByKind;
  final Set<String> uploadingDocuments;
  final Map<String, bool> booleans;
  final Map<String, String?> selections;
  final GlobalKey<FormState> detailsKey;
  final GlobalKey<FormState> documentsKey;
  final Map<String, dynamic> data;
  final Map<String, String> documents;
  final void Function(String key, bool value) onBooleanChanged;
  final void Function(String key, String? value) onSelectionChanged;
  final ValueChanged<String> onPickDocument;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final current = steps[step];
    return Column(
      children: [
        LinearProgressIndicator(value: (step + 1) / steps.length, minHeight: 3),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (current == ServiceStrings.details)
                      _DynamicDetailsForm(
                        formKey: detailsKey,
                        fields: service.requiredFields,
                        controllers: fieldControllers,
                        booleans: booleans,
                        selections: selections,
                        onBooleanChanged: onBooleanChanged,
                        onSelectionChanged: onSelectionChanged,
                      )
                    else if (current == ServiceStrings.documents)
                      _DocumentForm(
                        formKey: documentsKey,
                        documents: service.requiredDocuments,
                        selected: documentsByKind,
                        uploading: uploadingDocuments,
                        onPick: onPickDocument,
                      )
                    else
                      _ReviewStep(
                        service: service,
                        data: data,
                        documents: documents,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Row(
                    children: [
                      if (step > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitting ? null : onBack,
                            child: const Text(ServiceStrings.back),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: submitting
                              ? null
                              : step == steps.length - 1
                              ? onSubmit
                              : onNext,
                          child: submitting
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  step == steps.length - 1
                                      ? ServiceStrings.submitRequest
                                      : ServiceStrings.continueLabel,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicDetailsForm extends StatelessWidget {
  const _DynamicDetailsForm({
    required this.formKey,
    required this.fields,
    required this.controllers,
    required this.booleans,
    required this.selections,
    required this.onBooleanChanged,
    required this.onSelectionChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<ServiceFieldDefinition> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> booleans;
  final Map<String, String?> selections;
  final void Function(String key, bool value) onBooleanChanged;
  final void Function(String key, String? value) onSelectionChanged;

  String? _validateText(ServiceFieldDefinition field, String? value) {
    final text = value?.trim() ?? '';
    if (field.required && text.isEmpty) return ServiceStrings.requiredField;
    if (text.isNotEmpty && field.isNumeric && num.tryParse(text) == null) {
      return ServiceStrings.invalidNumber;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return Text(
        ServiceStrings.noRequestData,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ServiceStrings.fieldHelp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < fields.length; index++) ...[
            _DynamicField(
              field: fields[index],
              controller: controllers[fields[index].key],
              booleanValue: booleans[fields[index].key] ?? false,
              selection: selections[fields[index].key],
              validator: (value) => _validateText(fields[index], value),
              onBooleanChanged: (value) =>
                  onBooleanChanged(fields[index].key, value),
              onSelectionChanged: (value) =>
                  onSelectionChanged(fields[index].key, value),
            ),
            if (index != fields.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _DynamicField extends StatelessWidget {
  const _DynamicField({
    required this.field,
    required this.controller,
    required this.booleanValue,
    required this.selection,
    required this.validator,
    required this.onBooleanChanged,
    required this.onSelectionChanged,
  });

  final ServiceFieldDefinition field;
  final TextEditingController? controller;
  final bool booleanValue;
  final String? selection;
  final String? Function(String?) validator;
  final ValueChanged<bool> onBooleanChanged;
  final ValueChanged<String?> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (field.isBoolean) {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(field.label),
        subtitle: field.description == null ? null : Text(field.description!),
        value: booleanValue,
        onChanged: onBooleanChanged,
      );
    }
    if (field.isSelect) {
      return DropdownButtonFormField<String>(
        initialValue: selection,
        decoration: InputDecoration(
          labelText: field.label,
          helperText: field.description,
        ),
        items: field.options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        validator: validator,
        onChanged: onSelectionChanged,
      );
    }
    final date = field.isDate;
    return TextFormField(
      controller: controller,
      readOnly: date,
      minLines: field.isMultiline ? 3 : 1,
      maxLines: field.isMultiline ? 6 : 1,
      keyboardType: field.isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : field.type == 'email'
          ? TextInputType.emailAddress
          : field.type == 'phone'
          ? TextInputType.phone
          : field.isMultiline
          ? TextInputType.multiline
          : TextInputType.text,
      inputFormatters: field.type == 'integer'
          ? [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))]
          : null,
      textInputAction: field.isMultiline
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.placeholder,
        helperText: field.description,
        suffixIcon: date ? const Icon(Icons.calendar_today_outlined) : null,
      ),
      validator: validator,
      onTap: date
          ? () async {
              final initial =
                  DateTime.tryParse(controller?.text ?? '') ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) {
                controller?.text = picked.toIso8601String().split('T').first;
              }
            }
          : null,
    );
  }
}

class _DocumentForm extends StatelessWidget {
  const _DocumentForm({
    required this.formKey,
    required this.documents,
    required this.selected,
    required this.uploading,
    required this.onPick,
  });

  final GlobalKey<FormState> formKey;
  final List<String> documents;
  final Map<String, MediaResource> selected;
  final Set<String> uploading;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ServiceStrings.documentHelp,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < documents.length; index++) ...[
          FormField<MediaResource>(
            initialValue: selected[documents[index]],
            validator: (_) => selected.containsKey(documents[index])
                ? null
                : ServiceStrings.requiredField,
            builder: (field) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(
                child: uploading.contains(documents[index])
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
              ),
              title: Text(documents[index]),
              subtitle: Text(
                selected[documents[index]]?.originalName ??
                    (field.hasError ? field.errorText! : 'Choose a file'),
                style: field.hasError
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              trailing: FilledButton.tonal(
                onPressed: uploading.contains(documents[index])
                    ? null
                    : () => onPick(documents[index]),
                child: Text(
                  selected.containsKey(documents[index]) ? 'Replace' : 'Upload',
                ),
              ),
            ),
          ),
          if (index != documents.length - 1) const SizedBox(height: 14),
        ],
      ],
    ),
  );
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.service,
    required this.data,
    required this.documents,
  });

  final ServiceType service;
  final Map<String, dynamic> data;
  final Map<String, String> documents;

  @override
  Widget build(BuildContext context) {
    final labels = {
      for (final field in service.requiredFields) field.key: field.label,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ServiceStrings.reviewHelp,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        if (data.isNotEmpty)
          ServiceSection(
            title: ServiceStrings.requestData,
            child: _ReviewValues(values: data, labels: labels, maskIds: false),
          ),
        if (data.isNotEmpty && documents.isNotEmpty) const SizedBox(height: 28),
        if (documents.isNotEmpty)
          ServiceSection(
            title: ServiceStrings.requiredDocuments,
            child: _ReviewValues(
              values: documents,
              labels: const {},
              maskIds: true,
            ),
          ),
      ],
    );
  }
}

class _ReviewValues extends StatelessWidget {
  const _ReviewValues({
    required this.values,
    required this.labels,
    required this.maskIds,
  });

  final Map<String, dynamic> values;
  final Map<String, String> labels;
  final bool maskIds;

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
              subtitle: Text(
                maskIds && value.length > 8
                    ? '${value.substring(0, 8)}...'
                    : value,
              ),
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
