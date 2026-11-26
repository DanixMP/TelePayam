import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/reports/data/reports_api.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/presentation/report_ui.dart';
import 'package:university_messenger/features/reports/report_strings.dart';

class SubmitReportScreen extends ConsumerStatefulWidget {
  const SubmitReportScreen({required this.target, this.onSubmitted, super.key});

  final ReportTargetContext target;
  final ValueChanged<ReportRecord>? onSubmitted;

  @override
  ConsumerState<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends ConsumerState<SubmitReportScreen> {
  static const _reasons = [
    ReportStrings.reasonHarassment,
    ReportStrings.reasonSpam,
    ReportStrings.reasonHate,
    ReportStrings.reasonImpersonation,
    ReportStrings.reasonViolence,
    ReportStrings.reasonOther,
  ];

  final _formKey = GlobalKey<FormState>();
  final _customReasonController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedReason;
  String? _error;
  bool _submitting = false;
  ReportRecord? _submittedReport;

  @override
  void dispose() {
    _customReasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final customReason = _customReasonController.text.trim();
    final reason = _selectedReason == ReportStrings.reasonOther
        ? customReason
        : _selectedReason!;
    final note = _noteController.text.trim();
    try {
      final report = await ReportsApi(ref.read(apiClientProvider)).submitReport(
        target: widget.target,
        reason: reason,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      setState(() {
        _submittedReport = report;
        _submitting = false;
      });
      widget.onSubmitted?.call(report);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = reportErrorText(error);
        _submitting = false;
      });
    }
  }

  void _close() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final submittedReport = _submittedReport;
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReportStrings.submitTitle),
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
      ),
      body: SafeArea(
        child: submittedReport == null
            ? _buildForm(context)
            : _buildSuccess(context, submittedReport),
      ),
    );
  }

  Widget _buildForm(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ReportStrings.submitBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _TargetSummary(target: widget.target),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  labelText: ReportStrings.reason,
                  hintText: ReportStrings.chooseReason,
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: _reasons
                    .map(
                      (reason) =>
                          DropdownMenuItem(value: reason, child: Text(reason)),
                    )
                    .toList(growable: false),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _selectedReason = value),
                validator: (value) =>
                    value == null ? ReportStrings.reasonRequired : null,
              ),
              if (_selectedReason == ReportStrings.reasonOther) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customReasonController,
                  enabled: !_submitting,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: ReportStrings.describeReason,
                  ),
                  validator: (value) {
                    final reason = value?.trim() ?? '';
                    if (reason.length < 2) return ReportStrings.reasonTooShort;
                    if (reason.length > 80) return ReportStrings.reasonTooLong;
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                enabled: !_submitting,
                minLines: 3,
                maxLines: 7,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: ReportStrings.note,
                  hintText: ReportStrings.noteHint,
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.length ?? 0) > 1000
                    ? ReportStrings.noteTooLong
                    : null,
              ),
              const SizedBox(height: 16),
              _PrivacyNotice(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ReportErrorPanel(message: _error!),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.outlined_flag_rounded),
                label: Text(
                  _submitting
                      ? ReportStrings.submitting
                      : ReportStrings.submitAction,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting ? null : _close,
                child: const Text(ReportStrings.cancel),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildSuccess(BuildContext context, ReportRecord report) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              ReportStrings.submitted,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              ReportStrings.submittedBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(shortIdentifier(report.id)),
            ),
            if (Navigator.of(context).canPop()) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _close,
                child: const Text(ReportStrings.close),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TargetSummary extends StatelessWidget {
  const _TargetSummary({required this.target});

  final ReportTargetContext target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = target.label?.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.adjust_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReportStrings.target,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label?.isNotEmpty == true
                      ? label!
                      : reportTargetLabel(target.type),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    shortIdentifier(target.targetId),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ReportStrings.privacyNotice,
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
