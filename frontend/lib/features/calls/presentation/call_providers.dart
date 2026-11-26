import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/calls/data/call_api.dart';
import 'package:university_messenger/features/calls/data/call_media_adapter.dart';
import 'package:university_messenger/features/calls/data/call_realtime_gateway.dart';
import 'package:university_messenger/features/calls/data/livekit_call_media_adapter.dart';
import 'package:university_messenger/features/calls/presentation/call_controller.dart';

final callApiProvider = Provider<CallApi>(
  (ref) => CallApi(ref.watch(apiClientProvider)),
);

final callRealtimeGatewayProvider = Provider<CallRealtimeGateway>(
  (ref) => AppCallRealtimeGateway(ref.watch(realtimeClientProvider)),
);

final callMediaAdapterProvider = Provider<CallMediaAdapter>((ref) {
  final adapter = LiveKitCallMediaAdapter();
  ref.onDispose(adapter.dispose);
  return adapter;
});

final callBootstrapProvider = Provider<bool>((ref) => true);

final callControllerProvider = ChangeNotifierProvider<CallController>((ref) {
  final controller = CallController(
    api: ref.watch(callApiProvider),
    realtime: ref.watch(callRealtimeGatewayProvider),
    media: ref.watch(callMediaAdapterProvider),
    accountId: () => ref.read(authControllerProvider).state.account?.id,
  );
  final bootstrap = ref.watch(callBootstrapProvider);
  unawaited(
    controller.initialize(loadHistory: bootstrap, connectRealtime: bootstrap),
  );
  return controller;
});
