import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/features/settings/settings_screen.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.welcomeTitle,
      description: l10n.welcomeBody,
      steps: authSteps(l10n),
      currentStep: 0,
      actions: [
        IconButton(
          tooltip: l10n.settings,
          color: Colors.white,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(SettingsScreen.path),
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
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/phone'),
          ),
        ],
      ),
    );
  }
}
