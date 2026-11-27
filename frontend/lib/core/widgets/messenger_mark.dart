import 'package:flutter/material.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class MessengerMark extends StatelessWidget {
  const MessengerMark({super.key, this.size = 72, this.onPrimary = true});

  final double size;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: context.l10n.appTitle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onPrimary ? Colors.white : scheme.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.send_rounded,
          size: size * 0.47,
          color: onPrimary ? scheme.primary : scheme.onPrimary,
        ),
      ),
    );
  }
}
