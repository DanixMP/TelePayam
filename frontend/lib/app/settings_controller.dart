import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';

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
    _initialLoad = _load();
  }

  static const localeKey = 'settings.locale';
  static const themeKey = 'settings.theme';

  final AppSettingsStore _store;
  late final Future<void> _initialLoad;
  Future<void> _pendingWrite = Future.value();
  Locale _locale = const Locale('fa');
  ThemeMode _themeMode = ThemeMode.system;
  bool _disposed = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> _load() async {
    final (locale, theme) = await (_read(localeKey), _read(themeKey)).wait;
    if (_disposed) return;
    _locale = AppLocalizations.supportedLocales.firstWhere(
      (supported) => supported.languageCode == locale,
      orElse: () => _locale,
    );
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == theme,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<String?> _read(String key) async {
    try {
      return await _store.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
    }
    await _save(localeKey, locale.languageCode, () => _locale = locale);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _save(themeKey, mode.name, () => _themeMode = mode);

  Future<void> _save(String key, String value, VoidCallback update) {
    final write = _pendingWrite.then((_) async {
      await _initialLoad;
      await _store.write(key, value);
      if (_disposed) return;
      update();
      notifyListeners();
    });
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
