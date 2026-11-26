import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AppSettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureAppSettingsStore implements AppSettingsStore {
  SecureAppSettingsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class MemoryAppSettingsStore implements AppSettingsStore {
  MemoryAppSettingsStore([Map<String, String>? values])
    : _values = {...?values};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class SettingsController extends ChangeNotifier {
  SettingsController({required AppSettingsStore store}) : _store = store {
    unawaited(_load());
  }

  static const localeKey = 'settings.locale';
  static const themeKey = 'settings.theme';

  final AppSettingsStore _store;
  Locale _locale = const Locale('fa');
  ThemeMode _themeMode = ThemeMode.system;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> _load() async {
    final values = await Future.wait([
      _store.read(localeKey),
      _store.read(themeKey),
    ]);
    if (values[0] != null) _locale = Locale(values[0]!);
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == values[1],
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    _locale = Locale(_locale.languageCode == 'fa' ? 'en' : 'fa');
    notifyListeners();
    await _store.write(localeKey, _locale.languageCode);
  }

  Future<void> cycleTheme() async {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
    await _store.write(themeKey, _themeMode.name);
  }
}
