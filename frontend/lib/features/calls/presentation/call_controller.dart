import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/core/network/realtime_client.dart';
import 'package:university_messenger/features/calls/data/call_api.dart';
import 'package:university_messenger/features/calls/data/call_media_adapter.dart';
import 'package:university_messenger/features/calls/data/call_realtime_gateway.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';

enum CallOperation {
  idle,
  loadingHistory,
  starting,
  accepting,
  declining,
  ending,
}

class CallFailure {
  const CallFailure(this.code, this.detail);

  final String code;
  final String detail;
}

class CallControllerState {
  const CallControllerState({
    this.history = const [],
    this.operation = CallOperation.idle,
    this.elapsed = Duration.zero,
    this.historyLoaded = false,
    this.currentCall,
    this.incomingCall,
    this.failure,
  });

  final List<CallSession> history;
  final CallOperation operation;
  final Duration elapsed;
  final bool historyLoaded;
  final CallSession? currentCall;
  final CallSession? incomingCall;
  final CallFailure? failure;

  bool get isBusy => operation != CallOperation.idle;

  CallControllerState copyWith({
    List<CallSession>? history,
    CallOperation? operation,
    Duration? elapsed,
    bool? historyLoaded,
    CallSession? currentCall,
    bool clearCurrentCall = false,
    CallSession? incomingCall,
    bool clearIncomingCall = false,
    CallFailure? failure,
    bool clearFailure = false,
  }) => CallControllerState(
    history: history ?? this.history,
    operation: operation ?? this.operation,
    elapsed: elapsed ?? this.elapsed,
    historyLoaded: historyLoaded ?? this.historyLoaded,
    currentCall: clearCurrentCall ? null : currentCall ?? this.currentCall,
    incomingCall: clearIncomingCall ? null : incomingCall ?? this.incomingCall,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class CallController extends ChangeNotifier {
  CallController({
    required CallGateway api,
    required CallRealtimeGateway realtime,
    required CallMediaAdapter media,
    required String? Function() accountId,
    Random? random,
  }) : _api = api,
       _realtime = realtime,
       _media = media,
       _accountId = accountId,
       _random = random ?? Random.secure() {
    _media.addListener(_handleMediaChanged);
  }

  final CallGateway _api;
  final CallRealtimeGateway _realtime;
  final CallMediaAdapter _media;
  final String? Function() _accountId;
  final Random _random;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  Timer? _durationTimer;
  Timer? _ringingPollTimer;
  String? _joiningCallId;
  String? _joinedCallId;
  bool _ringingPollInFlight = false;
  bool _initialized = false;
  bool _disposed = false;
  CallControllerState _state = const CallControllerState();

  CallControllerState get state => _state;
  CallMediaAdapter get media => _media;

  Future<void> initialize({
    bool loadHistory = true,
    bool connectRealtime = true,
  }) async {
    if (_initialized || _disposed) return;
    _initialized = true;
    _realtimeSubscription = _realtime.events.listen(_handleRealtimeEvent);
    if (connectRealtime) await _realtime.connect();
    if (loadHistory) await refreshHistory();
  }

  Future<void> refreshHistory() async {
    _setState(
      _state.copyWith(
        operation: CallOperation.loadingHistory,
        clearFailure: true,
      ),
    );
    try {
      final calls = await _api.history();
      calls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      CallSession? incoming;
      CallSession? current = _state.currentCall;
      for (final call in calls) {
        if (call.status == CallStatus.ringing) {
          if (_isIncomingInvitation(call) && incoming == null) {
            incoming = call;
          } else if (call.callerId == _accountId() && current == null) {
            current = call;
          }
        } else if (call.status == CallStatus.active && current == null) {
          current = call;
        }
      }
      _setState(
        _state.copyWith(
          history: calls,
          historyLoaded: true,
          operation: CallOperation.idle,
          currentCall: current,
          clearCurrentCall: current == null,
          incomingCall: incoming,
          clearIncomingCall: incoming == null,
          clearFailure: true,
        ),
      );
      if (current?.status == CallStatus.active) {
        unawaited(_join(current!));
      } else if (current?.status == CallStatus.ringing) {
        _startRingingPoll(current!);
      }
    } catch (error) {
      _recordFailure(error, operation: CallOperation.idle);
    }
  }

  Future<bool> startOutgoing({
    required String conversationId,
    required CallKind kind,
  }) async {
    if (_state.isBusy) return false;
    final current = _state.currentCall;
    if (current != null &&
        (current.status == CallStatus.ringing ||
            current.status == CallStatus.active)) {
      _setState(
        _state.copyWith(
          failure: const CallFailure(
            'call_in_progress',
            'A call is already in progress',
          ),
        ),
      );
      return false;
    }
    _setState(
      _state.copyWith(operation: CallOperation.starting, clearFailure: true),
    );
    try {
      final call = await _api.createCall(
        conversationId: conversationId,
        clientCallId: _newClientCallId(),
        kind: kind,
      );
      _applyCall(call, clearOperation: true);
      return true;
    } catch (error) {
      _recordFailure(error, operation: CallOperation.idle);
      return false;
    }
  }

  Future<bool> acceptIncoming([String? callId]) async {
    final call = _findCall(callId) ?? _state.incomingCall;
    if (call == null || _state.isBusy) return false;
    _setState(
      _state.copyWith(operation: CallOperation.accepting, clearFailure: true),
    );
    try {
      final accepted = await _api.accept(call.id);
      _applyCall(accepted, clearOperation: true);
      await _join(accepted);
      return true;
    } catch (error) {
      _recordFailure(error, operation: CallOperation.idle);
      return false;
    }
  }

  Future<bool> declineIncoming([String? callId]) async {
    final call = _findCall(callId) ?? _state.incomingCall;
    if (call == null || _state.isBusy) return false;
    _setState(
      _state.copyWith(operation: CallOperation.declining, clearFailure: true),
    );
    try {
      final declined = await _api.decline(call.id);
      _applyCall(declined, clearOperation: true);
      return true;
    } catch (error) {
      _recordFailure(error, operation: CallOperation.idle);
      return false;
    }
  }

  Future<bool> endCurrent() async {
    final call = _state.currentCall;
    if (call == null || _state.isBusy) return false;
    _setState(
      _state.copyWith(operation: CallOperation.ending, clearFailure: true),
    );
    try {
      final ended = await _api.end(call.id);
      _applyCall(ended, clearOperation: true);
      return true;
    } catch (error) {
      _recordFailure(error, operation: CallOperation.idle);
      return false;
    }
  }

  Future<void> setMicrophoneEnabled(bool enabled) =>
      _runMediaAction(() => _media.setMicrophoneEnabled(enabled));

  Future<void> setCameraEnabled(bool enabled) =>
      _runMediaAction(() => _media.setCameraEnabled(enabled));

  Future<void> setSpeakerEnabled(bool enabled) =>
      _runMediaAction(() => _media.setSpeakerEnabled(enabled));

  Future<void> switchCamera() => _runMediaAction(_media.switchCamera);

  Future<void> retryMediaConnection() async {
    final call = _state.currentCall;
    if (call == null || call.status != CallStatus.active) return;
    _joinedCallId = null;
    _joiningCallId = null;
    await _media.disconnect();
    clearFailure();
    await _join(call);
  }

  void clearFailure() => _setState(_state.copyWith(clearFailure: true));

  void dismissFinishedCall() {
    final call = _state.currentCall;
    if (call == null ||
        call.status == CallStatus.ringing ||
        call.status == CallStatus.active) {
      return;
    }
    _setState(
      _state.copyWith(
        clearCurrentCall: true,
        elapsed: Duration.zero,
        clearFailure: true,
      ),
    );
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (event.type == 'connected') {
      if (_state.historyLoaded) unawaited(refreshHistory());
      return;
    }
    if (!const {
      'call.invite',
      'call.accept',
      'call.decline',
      'call.end',
      'call.state',
    }.contains(event.type)) {
      return;
    }
    final data = event.data;
    if (data is! Map) return;
    try {
      final call = CallSession.fromJson(Map<String, dynamic>.from(data));
      _applyCall(call, clearOperation: false);
      if (call.status == CallStatus.active) unawaited(_join(call));
    } catch (_) {
      // Malformed call events are ignored; REST history repairs state on reconnect.
    }
  }

  void _applyCall(CallSession call, {required bool clearOperation}) {
    final history = [..._state.history];
    history.removeWhere((item) => item.id == call.id);
    history.add(call);
    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    CallSession? current = _state.currentCall;
    CallSession? incoming = _state.incomingCall;
    if (call.status == CallStatus.ringing) {
      if (_isIncomingInvitation(call)) {
        incoming = call;
      } else if (call.callerId == _accountId()) {
        current = call;
        _startRingingPoll(call);
      }
    } else if (call.status == CallStatus.active) {
      _stopRingingPoll();
      current = call;
      if (incoming?.id == call.id) incoming = null;
      _startDuration(call);
    } else {
      _stopRingingPoll();
      if (current?.id == call.id || call.callerId == _accountId()) {
        current = call;
      }
      if (incoming?.id == call.id) incoming = null;
      _stopDuration();
      if (_joinedCallId == call.id || _joiningCallId == call.id) {
        _joinedCallId = null;
        _joiningCallId = null;
        unawaited(_media.disconnect());
      }
    }
    _setState(
      _state.copyWith(
        history: history,
        historyLoaded: true,
        operation: clearOperation ? CallOperation.idle : null,
        currentCall: current,
        clearCurrentCall: current == null,
        incomingCall: incoming,
        clearIncomingCall: incoming == null,
        clearFailure: clearOperation,
      ),
    );
  }

  Future<void> _join(CallSession call) async {
    if (call.status != CallStatus.active ||
        _joinedCallId == call.id ||
        _joiningCallId == call.id) {
      return;
    }
    _joiningCallId = call.id;
    try {
      final token = await _api.tokenFor(call.id);
      if (_state.currentCall?.id != call.id ||
          _state.currentCall?.status != CallStatus.active) {
        return;
      }
      await _media.connect(
        url: token.url,
        token: token.token,
        video: call.kind == CallKind.video,
      );
      if (_state.currentCall?.id != call.id ||
          _state.currentCall?.status != CallStatus.active) {
        await _media.disconnect();
        return;
      }
      _joinedCallId = call.id;
      _startDuration(call);
    } catch (error) {
      _recordFailure(
        error,
        operation: CallOperation.idle,
        fallbackCode: 'media_connection_failed',
      );
    } finally {
      _joiningCallId = null;
    }
  }

  Future<void> _runMediaAction(Future<void> Function() action) async {
    try {
      await action();
      clearFailure();
    } catch (error) {
      _recordFailure(
        error,
        operation: CallOperation.idle,
        fallbackCode: 'media_device_error',
      );
    }
  }

  bool _isIncomingInvitation(CallSession call) =>
      call.isIncomingFor(_accountId()) &&
      call.participantFor(_accountId())?.status ==
          CallParticipantStatus.invited;

  CallSession? _findCall(String? id) {
    if (id == null) return null;
    if (_state.currentCall?.id == id) return _state.currentCall;
    if (_state.incomingCall?.id == id) return _state.incomingCall;
    for (final call in _state.history) {
      if (call.id == id) return call;
    }
    return null;
  }

  String _newClientCallId() {
    final random = List.generate(
      12,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  void _startDuration(CallSession call) {
    _durationTimer?.cancel();
    void update() {
      final startedAt = call.startedAt;
      final elapsed = startedAt == null
          ? Duration.zero
          : DateTime.now().toUtc().difference(startedAt.toUtc());
      _setState(
        _state.copyWith(elapsed: elapsed.isNegative ? Duration.zero : elapsed),
      );
    }

    update();
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => update(),
    );
  }

  void _stopDuration() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _startRingingPoll(CallSession call) {
    if (_ringingPollTimer?.isActive == true) return;
    _ringingPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_ringingPollInFlight || _state.currentCall?.id != call.id) return;
      _ringingPollInFlight = true;
      try {
        final latest = await _api.getCall(call.id);
        _applyCall(latest, clearOperation: false);
        if (latest.status == CallStatus.active) unawaited(_join(latest));
      } catch (_) {
        // Websocket reconnect and the next poll remain available for recovery.
      } finally {
        _ringingPollInFlight = false;
      }
    });
  }

  void _stopRingingPoll() {
    _ringingPollTimer?.cancel();
    _ringingPollTimer = null;
    _ringingPollInFlight = false;
  }

  void _handleMediaChanged() {
    if (_disposed) return;
    final call = _state.currentCall;
    if (call?.status == CallStatus.active &&
        _joinedCallId == call?.id &&
        _media.connection == CallMediaConnection.disconnected) {
      _joinedCallId = null;
      _setState(
        _state.copyWith(
          failure: const CallFailure(
            'media_connection_failed',
            'The media room disconnected',
          ),
        ),
      );
      return;
    }
    notifyListeners();
  }

  void _recordFailure(
    Object error, {
    required CallOperation operation,
    String fallbackCode = 'request_failed',
  }) {
    final failure = error is ApiException
        ? CallFailure(error.code, error.detail)
        : CallFailure(fallbackCode, error.toString());
    _setState(_state.copyWith(operation: operation, failure: failure));
  }

  void _setState(CallControllerState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopDuration();
    _stopRingingPoll();
    _media.removeListener(_handleMediaChanged);
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_media.disconnect());
    super.dispose();
  }
}
