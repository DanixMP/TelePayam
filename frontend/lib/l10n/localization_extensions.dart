import 'package:flutter/widgets.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizedAuthError(AppLocalizations l10n, String? code) =>
    switch (code) {
      null => '',
      'invalid_phone' => l10n.invalidPhone,
      'otp_expired' => l10n.otpExpired,
      'otp_invalid' => l10n.otpIncorrect,
      'otp_locked' => l10n.otpLocked,
      'otp_rate_limited' => l10n.otpRateLimited,
      'student_identity_exists' => l10n.profileExists,
      'profile_already_submitted' => l10n.profileExists,
      'invalid_refresh_token' => l10n.sessionExpired,
      'refresh_expired' => l10n.sessionExpired,
      'session_expired' => l10n.sessionExpired,
      _ => l10n.genericError,
    };
