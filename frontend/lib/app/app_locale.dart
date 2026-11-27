import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';

const _windowChannel = OptionalMethodChannel('university_messenger/window');
String? _windowTitle;

void updateAppLocale(AppLocalizations l10n, TextDirection direction) {
  if (defaultTargetPlatform != TargetPlatform.windows ||
      _windowTitle == l10n.appTitle) {
    return;
  }
  _windowTitle = l10n.appTitle;
  unawaited(_windowChannel.invokeMethod<void>('setTitle', l10n.appTitle));
}
