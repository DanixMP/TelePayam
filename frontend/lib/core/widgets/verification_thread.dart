import 'package:flutter/material.dart';

class VerificationThread extends StatelessWidget {
  const VerificationThread({
    required this.steps,
    required this.currentStep,
    super.key,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const threadColor = Colors.white;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return Semantics(
      label:
          '${steps[currentStep.clamp(0, steps.length - 1)]}, '
          '${currentStep + 1} of ${steps.length}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: List.generate(steps.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final complete = index ~/ 2 < currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      height: 2,
                      color: complete
                          ? threadColor
                          : threadColor.withValues(alpha: 0.35),
                    ),
                  );
                }
                final step = index ~/ 2;
                final complete = step < currentStep;
                final active = step == currentStep;
                return AnimatedContainer(
                  duration: duration,
                  width: active ? 28 : 20,
                  height: active ? 28 : 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete || active
                        ? threadColor
                        : Colors.transparent,
                    border: Border.all(
                      color: threadColor.withValues(alpha: 0.75),
                      width: 2,
                    ),
                  ),
                  child: complete
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: scheme.primary,
                        )
                      : null,
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              steps[currentStep.clamp(0, steps.length - 1)],
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: threadColor),
            ),
          ],
        ),
      ),
    );
  }
}
