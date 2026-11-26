import 'package:university_messenger/core/network/realtime_client.dart';

abstract interface class CallRealtimeGateway {
  Stream<RealtimeEvent> get events;
  Future<void> connect();
}

class AppCallRealtimeGateway implements CallRealtimeGateway {
  const AppCallRealtimeGateway(this._client);

  final RealtimeClient _client;

  @override
  Stream<RealtimeEvent> get events => _client.events;

  @override
  Future<void> connect() => _client.connect();
}
