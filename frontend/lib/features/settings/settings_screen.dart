import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/widgets/inline_error.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _save(Future<void> Function() update) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await update();
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final canPop = context.canPop();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: canPop
            ? null
            : BackButton(onPressed: () => context.go('/welcome')),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_saveFailed) ...[
                  InlineError(message: l10n.settingsSaveError),
                  const SizedBox(height: 16),
                ],
                Semantics(
                  header: true,
                  child: Text(l10n.language, style: textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                RadioGroup<Locale>(
                  groupValue: settings.locale,
                  onChanged: (locale) {
                    if (locale != null) _save(() => settings.setLocale(locale));
                  },
                  child: Column(
                    children: [
                      RadioListTile(
                        value: const Locale('fa'),
                        enabled: !_saving,
                        title: Text(l10n.persian),
                        secondary: const Icon(Icons.language_outlined),
                      ),
                      RadioListTile(
                        value: const Locale('en'),
                        enabled: !_saving,
                        title: Text(l10n.english),
                        secondary: const Icon(Icons.language_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(l10n.appearance, style: textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                RadioGroup<ThemeMode>(
                  groupValue: settings.themeMode,
                  onChanged: (mode) {
                    if (mode != null) _save(() => settings.setThemeMode(mode));
                  },
                  child: Column(
                    children: [
                      RadioListTile(
                        value: ThemeMode.system,
                        enabled: !_saving,
                        title: Text(l10n.systemTheme),
                        subtitle: Text(l10n.systemThemeDescription),
                        secondary: const Icon(Icons.brightness_auto_outlined),
                      ),
                      RadioListTile(
                        value: ThemeMode.light,
                        enabled: !_saving,
                        title: Text(l10n.lightTheme),
                        secondary: const Icon(Icons.light_mode_outlined),
                      ),
                      RadioListTile(
                        value: ThemeMode.dark,
                        enabled: !_saving,
                        title: Text(l10n.darkTheme),
                        secondary: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
