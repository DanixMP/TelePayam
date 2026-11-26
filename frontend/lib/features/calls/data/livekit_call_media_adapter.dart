import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:university_messenger/features/calls/data/call_media_adapter.dart';

class LiveKitCallMediaAdapter extends CallMediaAdapter {
  Room? _room;
  EventsListener<RoomEvent>? _events;
  CallMediaConnection _connection = CallMediaConnection.disconnected;
  bool _microphoneEnabled = true;
  bool _cameraEnabled = false;
  bool _speakerEnabled = false;
  bool _usingFrontCamera = true;

  @override
  CallMediaConnection get connection => _connection;

  @override
  bool get microphoneEnabled => _microphoneEnabled;

  @override
  bool get cameraEnabled => _cameraEnabled;

  @override
  bool get speakerEnabled => _speakerEnabled;

  @override
  bool get hasRemoteVideo => _videoTrack(local: false) != null;

  @override
  bool get hasLocalVideo => _videoTrack(local: true) != null;

  @override
  Future<void> connect({
    required String url,
    required String token,
    required bool video,
  }) async {
    await disconnect();
    _setConnection(CallMediaConnection.connecting);
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    _room = room;
    room.addListener(_syncRoomState);
    _events = room.createListener()
      ..on<RoomDisconnectedEvent>((_) {
        _setConnection(CallMediaConnection.disconnected);
      });
    try {
      await room.prepareConnection(url, token);
      await room.connect(url, token);
      final participant = room.localParticipant;
      if (participant == null) {
        throw StateError('LiveKit connected without a local participant');
      }
      await participant.setMicrophoneEnabled(true);
      await participant.setCameraEnabled(video);
      await room.setSpeakerOn(video);
      _microphoneEnabled = true;
      _cameraEnabled = video;
      _speakerEnabled = video;
      _setConnection(CallMediaConnection.connected);
    } catch (_) {
      await disconnect();
      _setConnection(CallMediaConnection.failed);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final room = _room;
    if (room == null) {
      _setConnection(CallMediaConnection.disconnected);
      return;
    }
    _room = null;
    await _events?.dispose();
    _events = null;
    room.removeListener(_syncRoomState);
    try {
      await room.disconnect();
    } finally {
      await room.dispose();
      _cameraEnabled = false;
      _setConnection(CallMediaConnection.disconnected);
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    await participant.setMicrophoneEnabled(enabled);
    _microphoneEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    await participant.setCameraEnabled(enabled);
    _cameraEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setSpeakerEnabled(bool enabled) async {
    await _room?.setSpeakerOn(enabled);
    _speakerEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> switchCamera() async {
    final track = _videoTrack(local: true);
    if (track is! LocalVideoTrack) return;
    final useFrontCamera = !_usingFrontCamera;
    await track.setCameraPosition(
      useFrontCamera ? CameraPosition.front : CameraPosition.back,
    );
    _usingFrontCamera = useFrontCamera;
    notifyListeners();
  }

  @override
  Widget buildVideoView({required bool local, required Widget placeholder}) {
    final track = _videoTrack(local: local);
    return track == null
        ? placeholder
        : VideoTrackRenderer(track, fit: VideoViewFit.cover);
  }

  VideoTrack? _videoTrack({required bool local}) {
    final room = _room;
    if (room == null) return null;
    Participant? participant;
    if (local) {
      participant = room.localParticipant;
    } else {
      for (final remote in room.remoteParticipants.values) {
        participant = remote;
        break;
      }
    }
    if (participant == null) return null;
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (!publication.muted && track is VideoTrack) return track;
    }
    return null;
  }

  void _syncRoomState() {
    final state = _room?.connectionState.name;
    _connection = switch (state) {
      'connecting' => CallMediaConnection.connecting,
      'connected' => CallMediaConnection.connected,
      'reconnecting' => CallMediaConnection.reconnecting,
      'disconnected' => CallMediaConnection.disconnected,
      _ => _connection,
    };
    notifyListeners();
  }

  void _setConnection(CallMediaConnection value) {
    if (_connection == value) return;
    _connection = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    super.dispose();
  }
}
