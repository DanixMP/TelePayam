import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';
import 'package:university_messenger/features/calls/presentation/call_controller.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';
import 'package:university_messenger/features/calls/presentation/call_widgets.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  const OutgoingCallScreen({
    required this.conversationId,
    required this.kind,
    this.peerName,
    this.onClosed,
    super.key,
  });

  final String conversationId;
  final CallKind kind;
  final String? peerName;
  final VoidCallback? onClosed;

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen> {
  bool _startScheduled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.watch(callControllerProvider);
    final state = controller.state;
    final current = state.currentCall;
    final belongsToScreen = current?.conversationId == widget.conversationId;

    if (!_startScheduled && !state.isBusy && !belongsToScreen) {
      _startScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(callControllerProvider)
              .startOutgoing(
                conversationId: widget.conversationId,
                kind: widget.kind,
              ),
        );
      });
    }

    return Scaffold(
      body: belongsToScreen
          ? ActiveCallBody(
              controller: controller,
              peerName: widget.peerName,
              onClose: () => _close(context, controller),
            )
          : SafeArea(
              child: Column(
                children: [
                  if (state.failure != null)
                    CallErrorBanner(
                      failure: state.failure!,
                      onDismiss: controller.clearFailure,
                      onRetry: () {
                        controller.clearFailure();
                        setState(() => _startScheduled = false);
                      },
                    ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CallIdentity(
                          name: widget.peerName,
                          status: state.operation == CallOperation.starting
                              ? l10n.callCalling
                              : l10n.callOutgoingCall,
                          video: widget.kind == CallKind.video,
                          large: true,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: FilledButton.tonalIcon(
                      onPressed: () => _close(context, controller),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n.close),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _close(BuildContext context, CallController controller) {
    controller.dismissFinishedCall();
    if (widget.onClosed != null) {
      widget.onClosed!();
    } else {
      Navigator.maybePop(context);
    }
  }
}
