import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class RejectedScreen extends ConsumerWidget {
  const RejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(authControllerProvider);
    final profilePath = controller.state.account?.role == UserRole.professor
        ? '/register/professor'
        : '/register/student';
    return AuthScaffold(
      title: l10n.rejectedTitle,
      description: l10n.rejectedBody,
      steps: authSteps(l10n),
      currentStep: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 68,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 22),
          AsyncPrimaryButton(
            label: l10n.correctSubmission,
            onPressed: () => context.go(profilePath),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.state.isBusy ? null : controller.logout,
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
