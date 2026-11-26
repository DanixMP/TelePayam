import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(authControllerProvider);
    return AuthScaffold(
      title: l10n.blockedTitle,
      description: l10n.blockedBody,
      steps: authSteps(l10n),
      currentStep: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: controller.state.isBusy ? null : controller.logout,
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
