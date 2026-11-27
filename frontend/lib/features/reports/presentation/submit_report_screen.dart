import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/reports/data/reports_api.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/presentation/report_ui.dart';
import 'package:university_messenger/features/reports/report_strings.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class SubmitReportScreen extends ConsumerStatefulWidget {
  const SubmitReportScreen({required this.target, this.onSubmitted, super.key});

  final ReportTargetContext target;
  final ValueChanged<ReportRecord>? onSubmitted;

  @override
  ConsumerState<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends ConsumerState<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customReasonController = TextEditingController();
  final _noteController = TextEditingController();
  ReportReason? _selectedReason;
  Object? _error;
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
    final reason = _selectedReason == ReportReason.other
        ? customReason
        : _selectedReason!.wireValue;
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
        _error = error;
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
        title: Text(context.l10n.reportSubmitTitle),
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
      ),
      body: SafeArea(
        child: submittedReport == null
            ? _buildForm(context)
            : _buildSuccess(context, submittedReport),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;
    return Align(
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
                  l10n.reportSubmitBody,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _TargetSummary(target: widget.target),
                const SizedBox(height: 24),
                DropdownButtonFormField<ReportReason>(
                  initialValue: _selectedReason,
                  decoration: InputDecoration(
                    labelText: l10n.reportReason,
                    hintText: l10n.reportChooseReason,
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  items: ReportReason.values
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason.label(l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _selectedReason = value),
                  validator: (value) =>
                      value == null ? l10n.reportReasonRequired : null,
                ),
                if (_selectedReason == ReportReason.other) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _customReasonController,
                    enabled: !_submitting,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.reportDescribeReason,
                    ),
                    validator: (value) {
                      final reason = value?.trim() ?? '';
                      if (reason.length < 2) return l10n.reportReasonTooShort;
                      if (reason.length > 80) return l10n.reportReasonTooLong;
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
                  decoration: InputDecoration(
                    labelText: l10n.reportNote,
                    hintText: l10n.reportNoteHint,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value?.length ?? 0) > 1000
                      ? l10n.reportNoteTooLong
                      : null,
                ),
                const SizedBox(height: 16),
                _PrivacyNotice(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ReportErrorPanel(message: reportErrorText(l10n, _error!)),
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
                        ? l10n.reportSubmitting
                        : l10n.reportSubmitAction,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _submitting ? null : _close,
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              context.l10n.reportSubmitted,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.reportSubmittedBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(shortIdentifier(report.id)),
            ),
            if (Navigator.of(context).canPop()) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: _close, child: Text(context.l10n.close)),
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
                  context.l10n.reportTarget,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label?.isNotEmpty == true
                      ? label!
                      : reportTargetLabel(context.l10n, target.type),
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
              context.l10n.reportPrivacyNotice,
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
