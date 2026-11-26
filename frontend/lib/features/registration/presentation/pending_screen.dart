import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/app/theme/app_tokens.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/core/widgets/inline_error.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => ref.read(authControllerProvider).refreshStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.watch(authControllerProvider);
    final state = controller.state;
    return AuthScaffold(
      title: l10n.pendingTitle,
      description: l10n.pendingBody,
      steps: authSteps(l10n),
      currentStep: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ApprovalTimeline(
            labels: [l10n.submitted, l10n.underReview, l10n.decision],
          ),
          const SizedBox(height: 24),
          InlineError(message: localizedAuthError(l10n, state.errorCode)),
          if (state.errorCode != null) const SizedBox(height: 14),
          AsyncPrimaryButton(
            label: state.isBusy ? l10n.checking : l10n.refreshStatus,
            isLoading: state.isBusy,
            icon: Icons.refresh_rounded,
            onPressed: controller.refreshStatus,
          ),
          if (state.lastChecked != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.lastChecked,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.isBusy ? null : controller.logout,
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTimeline extends StatelessWidget {
  const _ApprovalTimeline({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Semantics(
      label: labels.join(', '),
      child: ExcludeSemantics(
        child: Column(
          children: List.generate(labels.length, (index) {
            final complete = index == 0;
            final active = index == 1;
            final color = complete
                ? tokens.success
                : active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        complete
                            ? Icons.check_rounded
                            : Icons.more_horiz_rounded,
                        color: complete || active
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    if (index < labels.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: index == 0
                            ? tokens.success
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[index],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: index == 2
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
