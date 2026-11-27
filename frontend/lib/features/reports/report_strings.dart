import 'package:university_messenger/l10n/generated/app_localizations.dart';

enum ReportReason {
  harassment('Harassment or abuse'),
  spam('Spam or scam'),
  hate('Hate or discrimination'),
  impersonation('Impersonation'),
  violence('Violence or threat'),
  other('Other');

  const ReportReason(this.wireValue);

  // Keep the stored values used by earlier clients and existing reports.
  final String wireValue;

  String label(AppLocalizations l10n) => switch (this) {
    harassment => l10n.reportReasonHarassment,
    spam => l10n.reportReasonSpam,
    hate => l10n.reportReasonHate,
    impersonation => l10n.reportReasonImpersonation,
    violence => l10n.reportReasonViolence,
    other => l10n.reportReasonOther,
  };
}

String reportReasonLabel(AppLocalizations l10n, String reason) {
  for (final option in ReportReason.values) {
    if (reason == option.wireValue) return option.label(l10n);
  }
  return reason;
}
