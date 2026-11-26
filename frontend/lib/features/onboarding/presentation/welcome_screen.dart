import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    return AuthScaffold(
      title: l10n.welcomeTitle,
      description: l10n.welcomeBody,
      steps: authSteps(l10n),
      currentStep: 0,
      actions: [
        IconButton(
          onPressed: settings.toggleLocale,
          tooltip: l10n.languageTooltip,
          color: Colors.white,
          icon: const Icon(Icons.translate_rounded),
        ),
        IconButton(
          onPressed: settings.cycleTheme,
          tooltip: l10n.themeTooltip,
          color: Colors.white,
          icon: const Icon(Icons.brightness_6_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.welcomeBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          AsyncPrimaryButton(
            label: l10n.continueLabel,
            icon: Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_back_rounded
                : Icons.arrow_forward_rounded,
            onPressed: () => context.go('/phone'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: settings.toggleLocale,
            icon: const Icon(Icons.language_rounded),
            label: Text(
              settings.locale.languageCode == 'fa'
                  ? l10n.english
                  : l10n.persian,
            ),
          ),
        ],
      ),
    );
  }
}
