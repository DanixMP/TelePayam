import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

String callErrorLabel(AppLocalizations l10n, String? code) => switch (code) {
  'group_calls_unsupported' => l10n.callDirectCallsOnly,
  'call_in_progress' => l10n.callCallInProgress,
  'call_unavailable' => l10n.callDirectCallUnavailable,
  'call_not_found' => l10n.callCallUnavailable,
  'call_not_ringing' => l10n.callIncomingCallEnded,
  'call_not_active' || 'active_call_required' => l10n.callActiveCallRequired,
  'media_connection_failed' => l10n.callMediaConnectionError,
  'media_device_error' => l10n.callMediaDeviceError,
  _ => localizedApiError(l10n, code),
};
