import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizedDegree(AppLocalizations l10n, String degree) =>
    switch (degree.trim().toLowerCase()) {
      'bsc' ||
      'bachelor' ||
      'bachelor’s' ||
      'bachelor\'s' ||
      'کارشناسی' => l10n.degreeBachelor,
      'msc' ||
      'master' ||
      'master’s' ||
      'master\'s' ||
      'کارشناسی ارشد' => l10n.degreeMaster,
      'doctorate' || 'phd' || 'دکتری' => l10n.degreeDoctorate,
      'other' || 'سایر' => l10n.degreeOther,
      _ => degree,
    };

String localizedMessageType(AppLocalizations l10n, String type) =>
    switch (type) {
      'text' => l10n.message,
      'deleted' => l10n.messageDeleted,
      'image' || 'photo' => l10n.photo,
      'video' => l10n.video,
      'voice' => l10n.voiceMessage,
      'audio' => l10n.audio,
      'file' => l10n.file,
      'document' => l10n.document,
      'album' => l10n.album,
      'poll' => l10n.poll,
      'sticker' => l10n.sticker,
      'animation' || 'gif' => l10n.gif,
      _ => l10n.attachment,
    };

String localizedApiError(AppLocalizations l10n, String? code) => switch (code) {
  'network_error' => l10n.networkError,
  'forbidden' => l10n.forbiddenError,
  'account_blocked' => l10n.blockedTitle,
  'validation_error' || 'invalid_request' => l10n.invalidForm,
  'messenger_server_required' => l10n.chatServerRequired,
  'invalid_refresh_token' ||
  'refresh_expired' ||
  'refresh_reuse_detected' ||
  'session_expired' ||
  'authentication_required' => l10n.sessionExpired,
  _ => l10n.genericError,
};

String? apiErrorCode(Object error) => switch (error) {
  ApiException() => error.code,
  DioException() => ApiException.fromDio(error).code,
  _ => null,
};

String localizedMediaError(
  AppLocalizations l10n,
  Object error,
  String fallback,
) {
  final code = apiErrorCode(error);
  return switch (code) {
    'file_too_large' => l10n.mediaInvalidSize,
    'unsupported_media_type' => l10n.mediaUnsupportedType,
    'invalid_file_content' => l10n.mediaInvalidContent,
    'network_error' ||
    'account_blocked' ||
    'forbidden' ||
    'session_expired' => localizedApiError(l10n, code),
    _ => fallback,
  };
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
      _ => localizedApiError(l10n, code),
    };
