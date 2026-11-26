import 'package:flutter/widgets.dart';

enum CallMediaConnection {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

abstract class CallMediaAdapter extends ChangeNotifier {
  CallMediaConnection get connection;
  bool get microphoneEnabled;
  bool get cameraEnabled;
  bool get speakerEnabled;
  bool get hasRemoteVideo;
  bool get hasLocalVideo;

  Future<void> connect({
    required String url,
    required String token,
    required bool video,
  });

  Future<void> disconnect();
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> setSpeakerEnabled(bool enabled);
  Future<void> switchCamera();

  Widget buildVideoView({required bool local, required Widget placeholder});
}
