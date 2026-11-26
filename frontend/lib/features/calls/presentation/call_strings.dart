abstract final class CallStrings {
  static const history = 'Call history';
  static const noCalls = 'No calls yet';
  static const noCallsBody = 'Calls you make or receive will appear here.';
  static const audioCall = 'Audio call';
  static const videoCall = 'Video call';
  static const incomingAudioCall = 'Incoming audio call';
  static const incomingVideoCall = 'Incoming video call';
  static const unknownCaller = 'Unknown caller';
  static const outgoingCall = 'Outgoing call';
  static const calling = 'Calling...';
  static const ringing = 'Ringing...';
  static const connecting = 'Connecting securely...';
  static const reconnecting = 'Reconnecting...';
  static const connected = 'Connected';
  static const waitingForAnswer = 'Waiting for an answer';
  static const callEnded = 'Call ended';
  static const declined = 'Declined';
  static const missed = 'Missed';
  static const answer = 'Answer';
  static const decline = 'Decline';
  static const endCall = 'End call';
  static const close = 'Close';
  static const retry = 'Retry';
  static const dismiss = 'Dismiss';
  static const microphoneOn = 'Mute microphone';
  static const microphoneOff = 'Unmute microphone';
  static const speakerOn = 'Use earpiece';
  static const speakerOff = 'Use speaker';
  static const cameraOn = 'Turn camera off';
  static const cameraOff = 'Turn camera on';
  static const switchCamera = 'Switch camera';
  static const waitingForVideo = 'Waiting for video';
  static const incomingCallEnded = 'This call is no longer ringing.';
  static const callUnavailable = 'Call unavailable';
  static const callInProgress = 'A call is already in progress.';
  static const directCallsOnly = 'Calls are available in direct messages only.';
  static const directCallUnavailable = 'This conversation cannot be called.';
  static const networkError =
      'Could not reach the server. Check your connection and try again.';
  static const mediaConnectionError =
      'Could not connect call audio or video. Check permissions and try again.';
  static const mediaDeviceError =
      'Could not change that device setting. Check device permissions.';
  static const genericError = 'Something went wrong. Please try again.';
  static const activeCallRequired = 'The call has already ended.';

  static String errorFor(String? code) => switch (code) {
    'network_error' => networkError,
    'group_calls_unsupported' => directCallsOnly,
    'call_in_progress' => callInProgress,
    'call_unavailable' => directCallUnavailable,
    'call_not_ringing' => incomingCallEnded,
    'call_not_active' || 'active_call_required' => activeCallRequired,
    'media_connection_failed' => mediaConnectionError,
    'media_device_error' => mediaDeviceError,
    _ => genericError,
  };
}
