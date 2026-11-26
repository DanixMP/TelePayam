enum CallKind {
  audio,
  video;

  static CallKind fromJson(Object? value) => CallKind.values.firstWhere(
    (kind) => kind.name == value?.toString(),
    orElse: () => CallKind.audio,
  );
}

enum CallStatus {
  ringing,
  active,
  declined,
  ended;

  static CallStatus fromJson(Object? value) => CallStatus.values.firstWhere(
    (status) => status.name == value?.toString(),
    orElse: () => CallStatus.ended,
  );
}

enum CallParticipantStatus {
  invited,
  accepted,
  declined,
  ended;

  static CallParticipantStatus fromJson(Object? value) =>
      CallParticipantStatus.values.firstWhere(
        (status) => status.name == value?.toString(),
        orElse: () => CallParticipantStatus.ended,
      );
}

class CallParticipant {
  const CallParticipant({
    required this.userId,
    required this.status,
    this.respondedAt,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) =>
      CallParticipant(
        userId: json['user_id'].toString(),
        status: CallParticipantStatus.fromJson(json['status']),
        respondedAt: DateTime.tryParse(json['responded_at']?.toString() ?? ''),
      );

  final String userId;
  final CallParticipantStatus status;
  final DateTime? respondedAt;
}

class CallSession {
  const CallSession({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.clientCallId,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.participants,
    this.startedAt,
    this.endedAt,
    this.endedBy,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
    id: json['id'].toString(),
    conversationId: json['conversation_id'].toString(),
    callerId: json['caller_id'].toString(),
    clientCallId: json['client_call_id'].toString(),
    kind: CallKind.fromJson(json['kind']),
    status: CallStatus.fromJson(json['status']),
    startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
    endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? ''),
    endedBy: json['ended_by']?.toString(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    participants: (json['participants'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CallParticipant.fromJson)
        .toList(growable: false),
  );

  final String id;
  final String conversationId;
  final String callerId;
  final String clientCallId;
  final CallKind kind;
  final CallStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? endedBy;
  final DateTime createdAt;
  final List<CallParticipant> participants;

  bool isIncomingFor(String? accountId) =>
      accountId != null && callerId != accountId;

  CallParticipant? participantFor(String? accountId) {
    if (accountId == null) return null;
    for (final participant in participants) {
      if (participant.userId == accountId) return participant;
    }
    return null;
  }

  String? peerIdFor(String? accountId) {
    if (accountId == null) return null;
    for (final participant in participants) {
      if (participant.userId != accountId) return participant.userId;
    }
    return null;
  }
}

class CallJoinToken {
  const CallJoinToken({
    required this.url,
    required this.room,
    required this.token,
  });

  factory CallJoinToken.fromJson(Map<String, dynamic> json) => CallJoinToken(
    url: json['url'].toString(),
    room: json['room'].toString(),
    token: json['token'].toString(),
  );

  final String url;
  final String room;
  final String token;
}
