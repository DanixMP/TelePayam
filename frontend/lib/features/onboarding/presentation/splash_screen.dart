import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/widgets/messenger_mark.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.watch(authControllerProvider);
    final hasError = controller.state.errorCode != null;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MessengerMark(size: 84),
                const SizedBox(height: 24),
                Text(
                  context.l10n.appTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
                ),
                const SizedBox(height: 28),
                if (hasError) ...[
                  Text(
                    context.l10n.genericError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: controller.retryBootstrap,
                    child: Text(context.l10n.tryAgain),
                  ),
                ] else
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
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
