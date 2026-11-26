import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';
import 'package:university_messenger/features/calls/presentation/call_strings.dart';
import 'package:university_messenger/features/calls/presentation/call_widgets.dart';

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({
    this.peerName = CallStrings.unknownCaller,
    this.onClosed,
    super.key,
  });

  final String peerName;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(callControllerProvider);
    return Scaffold(
      body: ActiveCallBody(
        controller: controller,
        peerName: peerName,
        onClose: () {
          controller.dismissFinishedCall();
          if (onClosed != null) {
            onClosed!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
    );
  }
}
