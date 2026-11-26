import 'dart:async';
import 'dart:convert';

import 'package:university_messenger/core/config/app_config.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeEvent {
  const RealtimeEvent(this.type, this.data);

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeEvent(json['type']?.toString() ?? 'unknown', json['data']);

  final String type;
  final Object? data;
}

class RealtimeClient {
  RealtimeClient(this._tokenStore);

  final TokenStore _tokenStore;
  final _events = StreamController<RealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  var _reconnectAttempt = 0;
  var _disposed = false;
  Future<void>? _connecting;

  Stream<RealtimeEvent> get events => _events.stream;
  bool get isConnected => _channel != null;

  Future<void> connect() =>
      _connecting ??= _connect().whenComplete(() => _connecting = null);

  Future<void> _connect() async {
    if (_disposed || _channel != null) return;
    final tokens = await _tokenStore.read();
    if (tokens == null) return;
    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final socketUri = apiUri.replace(
      scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws',
      queryParameters: {'token': tokens.accessToken},
    );
    try {
      final channel = WebSocketChannel.connect(socketUri);
      await channel.ready;
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _reconnectAttempt = 0;
      _events.add(const RealtimeEvent('connected', null));
      _subscription = channel.stream.listen(
        _handleFrame,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(
        const Duration(seconds: 25),
        (_) => send('ping'),
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleFrame(Object? frame) {
    if (frame is! String) return;
    try {
      final json = jsonDecode(frame) as Map<String, dynamic>;
      _events.add(RealtimeEvent.fromJson(json));
    } catch (_) {
      // Invalid server frames are ignored; reconnect handles closed sockets.
    }
  }

  void send(String type, [Map<String, dynamic>? data]) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({'type': type, 'data': ?data}));
  }

  void sendMessage({
    required String conversationId,
    required String clientMessageId,
    required String body,
  }) => send('msg.send', {
    'conv': conversationId,
    'client_msg_id': clientMessageId,
    'type': 'text',
    'body': body,
  });

  void sendTyping(String conversationId, bool typing) => send('typing', {
    'conv': conversationId,
    'action': typing ? 'typing' : 'stopped',
  });

  void sendRead(String conversationId, int sequence) =>
      send('read', {'conv': conversationId, 'seq': sequence});

  void sync(Map<String, int> cursors) => send('sync', {'conv': cursors});

  void _handleDisconnect() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (_disposed || _reconnectTimer?.isActive == true) return;
    final seconds = 1 << _reconnectAttempt.clamp(0, 5).toInt();
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), connect);
  }

  Future<void> dispose() async {
    _disposed = true;
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _events.close();
  }
}
