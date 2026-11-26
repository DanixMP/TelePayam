import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';
import 'package:university_messenger/features/calls/presentation/call_controller.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';
import 'package:university_messenger/features/calls/presentation/call_strings.dart';
import 'package:university_messenger/features/calls/presentation/call_widgets.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({
    this.callId,
    this.peerName = CallStrings.unknownCaller,
    this.onClosed,
    super.key,
  });

  final String? callId;
  final String peerName;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(callControllerProvider);
    final state = controller.state;
    final call = _resolveCall(state.history, state.incomingCall);
    if (state.currentCall?.id == call?.id &&
        state.currentCall?.status == CallStatus.active) {
      return Scaffold(
        body: ActiveCallBody(
          controller: controller,
          peerName: peerName,
          onClose: () => _close(context, controller),
        ),
      );
    }

    final video = call?.kind == CallKind.video;
    final noLongerRinging = call != null && call.status != CallStatus.ringing;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            if (state.failure != null)
              CallErrorBanner(
                failure: state.failure!,
                onDismiss: controller.clearFailure,
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: CallIdentity(
                      name: peerName,
                      status: noLongerRinging
                          ? CallStrings.incomingCallEnded
                          : video
                          ? CallStrings.incomingVideoCall
                          : CallStrings.incomingAudioCall,
                      video: video,
                      large: true,
                    ),
                  ),
                ),
              ),
            ),
            if (!noLongerRinging && call != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _IncomingAction(
                        icon: Icons.call_end_rounded,
                        label: CallStrings.decline,
                        color: Theme.of(context).colorScheme.error,
                        foreground: Theme.of(context).colorScheme.onError,
                        enabled: !state.isBusy,
                        onPressed: () => controller.declineIncoming(call.id),
                      ),
                      _IncomingAction(
                        icon: video
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        label: CallStrings.answer,
                        color: Theme.of(context).colorScheme.primary,
                        foreground: Theme.of(context).colorScheme.onPrimary,
                        enabled: !state.isBusy,
                        onPressed: () => controller.acceptIncoming(call.id),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  onPressed: () => _close(context, controller),
                  child: const Text(CallStrings.close),
                ),
              ),
          ],
        ),
      ),
    );
  }

  CallSession? _resolveCall(List<CallSession> history, CallSession? incoming) {
    if (callId == null) return incoming;
    if (incoming?.id == callId) return incoming;
    for (final call in history) {
      if (call.id == callId) return call;
    }
    return null;
  }

  void _close(BuildContext context, CallController controller) {
    controller.dismissFinishedCall();
    if (onClosed != null) {
      onClosed!();
    } else {
      Navigator.maybePop(context);
    }
  }
}

class _IncomingAction extends StatelessWidget {
  const _IncomingAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            onPressed: enabled ? onPressed : null,
            style: IconButton.styleFrom(
              minimumSize: const Size(64, 64),
              backgroundColor: color,
              foregroundColor: foreground,
            ),
            icon: Icon(icon, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
