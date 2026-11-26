import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';
import 'package:university_messenger/features/calls/presentation/call_strings.dart';
import 'package:university_messenger/features/calls/presentation/incoming_call_screen.dart';

typedef IncomingCallPresenter =
    void Function(BuildContext context, CallSession call);

class CallIncomingListener extends ConsumerStatefulWidget {
  const CallIncomingListener({
    required this.child,
    this.onIncomingCall,
    this.peerNameForCall,
    super.key,
  });

  final Widget child;
  final IncomingCallPresenter? onIncomingCall;
  final String Function(CallSession call)? peerNameForCall;

  @override
  ConsumerState<CallIncomingListener> createState() =>
      _CallIncomingListenerState();
}

class _CallIncomingListenerState extends ConsumerState<CallIncomingListener> {
  final Set<String> _presentedCalls = {};

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(callControllerProvider).state.incomingCall;
    if (call != null && _presentedCalls.add(call.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final presenter = widget.onIncomingCall;
        if (presenter != null) {
          presenter(context, call);
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => IncomingCallScreen(
              callId: call.id,
              peerName:
                  widget.peerNameForCall?.call(call) ??
                  CallStrings.unknownCaller,
            ),
          ),
        );
      });
    }
    return widget.child;
  }
}
