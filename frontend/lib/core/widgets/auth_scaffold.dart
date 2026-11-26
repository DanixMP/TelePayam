import 'package:flutter/material.dart';
import 'package:university_messenger/app/theme/app_tokens.dart';
import 'package:university_messenger/core/widgets/messenger_mark.dart';
import 'package:university_messenger/core/widgets/verification_thread.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.description,
    required this.steps,
    required this.currentStep,
    required this.child,
    this.actions = const [],
    this.footer,
    super.key,
  });

  final String title;
  final String description;
  final List<String> steps;
  final int currentStep;
  final Widget child;
  final List<Widget> actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(body: width >= 840 ? _desktop(context) : _mobile(context));
  }

  Widget _desktop(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final direction = Directionality.of(context);
    return SafeArea(
      child: Row(
        textDirection: direction,
        children: [
          Expanded(
            flex: 4,
            child: ColoredBox(
              color: tokens.heroBlue,
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const MessengerMark(size: 68),
                        const Spacer(),
                        ...actions,
                      ],
                    ),
                    const Spacer(),
                    VerificationThread(steps: steps, currentStep: currentStep),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(flex: 6, child: _formSurface(context, showTitle: false)),
        ],
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return ColoredBox(
      color: tokens.heroBlue,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Row(
                children: [
                  const MessengerMark(size: 52),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 98, 24, 0),
              child: VerificationThread(steps: steps, currentStep: currentStep),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 174),
              child: _formSurface(context, showTitle: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formSurface(BuildContext context, {required bool showTitle}) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: showTitle
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showTitle) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  child,
                  if (footer != null) ...[const SizedBox(height: 22), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
