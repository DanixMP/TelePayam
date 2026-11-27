import 'dart:ui' show TextDirection;

import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:web/web.dart' as web;

void updateAppLocale(AppLocalizations l10n, TextDirection direction) {
  final root = web.document.documentElement;
  if (root == null) return;
  if (root.getAttribute('lang') != l10n.localeName) {
    root.setAttribute('lang', l10n.localeName);
    web.document
        .querySelector('meta[name="description"]')
        ?.setAttribute('content', l10n.appDescription);
    web.document
        .querySelector('meta[name="apple-mobile-web-app-title"]')
        ?.setAttribute('content', l10n.appTitle);
    web.document
        .querySelector('link[rel="manifest"]')
        ?.setAttribute(
          'href',
          l10n.localeName == 'en' ? 'manifest-en.json' : 'manifest.json',
        );
  }
  if (root.getAttribute('dir') != direction.name) {
    root.setAttribute('dir', direction.name);
  }
  final accessibility = web.document.querySelector('flt-semantics-placeholder');
  if (accessibility != null &&
      accessibility.getAttribute('aria-label') != l10n.enableAccessibility) {
    accessibility.setAttribute('aria-label', l10n.enableAccessibility);
  }
}
