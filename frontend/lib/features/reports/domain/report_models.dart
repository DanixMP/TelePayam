enum ReportTargetType {
  message('message'),
  user('user'),
  group('group'),
  channel('channel'),
  unknown('unknown');

  const ReportTargetType(this.wireValue);

  final String wireValue;

  static ReportTargetType fromWire(String value) =>
      ReportTargetType.values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => ReportTargetType.unknown,
      );
}

enum ReportStatus {
  open('open'),
  assigned('assigned'),
  resolved('resolved'),
  dismissed('dismissed'),
  unknown('unknown');

  const ReportStatus(this.wireValue);

  final String wireValue;

  static ReportStatus fromWire(String value) => ReportStatus.values.firstWhere(
    (item) => item.wireValue == value,
    orElse: () => ReportStatus.unknown,
  );
}

enum ResolutionOutcome {
  dismiss('dismiss'),
  warn('warn'),
  mute('mute'),
  removeContent('remove_content'),
  ban('ban'),
  escalate('escalate'),
  unknown('unknown');

  const ResolutionOutcome(this.wireValue);

  final String wireValue;

  static ResolutionOutcome fromWire(String value) =>
      ResolutionOutcome.values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => ResolutionOutcome.unknown,
      );
}

class ReportTargetContext {
  const ReportTargetContext({
    required this.type,
    required this.targetId,
    this.conversationId,
    this.messageId,
    this.label,
  }) : assert(type != ReportTargetType.unknown),
       assert(type != ReportTargetType.message || messageId != null);

  const ReportTargetContext.message({
    required String messageId,
    required String conversationId,
    String? label,
  }) : this(
         type: ReportTargetType.message,
         targetId: messageId,
         messageId: messageId,
         conversationId: conversationId,
         label: label,
       );

  final ReportTargetType type;
  final String targetId;
  final String? conversationId;
  final String? messageId;
  final String? label;

  Map<String, dynamic> toJson({required String reason, String? note}) => {
    'target_type': type.wireValue,
    'target_id': targetId,
    'conversation_id': ?conversationId,
    'message_id': ?messageId,
    'reason': reason,
    'note': ?note,
  };
}

class ReportRecord {
  const ReportRecord({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.messageId,
    this.note,
    this.assignedTo,
    this.resolution,
    this.resolvedAt,
  });

  factory ReportRecord.fromJson(Map<String, dynamic> json) => ReportRecord(
    id: json['id'].toString(),
    reporterId: json['reporter_id'].toString(),
    targetType: ReportTargetType.fromWire(json['target_type'].toString()),
    targetId: json['target_id'].toString(),
    conversationId: json['conversation_id']?.toString(),
    messageId: json['message_id']?.toString(),
    reason: json['reason']?.toString() ?? '',
    note: json['note']?.toString(),
    status: ReportStatus.fromWire(json['status'].toString()),
    assignedTo: json['assigned_to']?.toString(),
    resolution: json['resolution']?.toString(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
  );

  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String? conversationId;
  final String? messageId;
  final String reason;
  final String? note;
  final ReportStatus status;
  final String? assignedTo;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ResolutionOutcome? get resolutionOutcome {
    final value = resolution;
    if (value == null || value.isEmpty) return null;
    return ResolutionOutcome.fromWire(value.split(':').first.trim());
  }

  String? get resolutionNote {
    final value = resolution;
    if (value == null) return null;
    final separator = value.indexOf(':');
    if (separator < 0) return null;
    final result = value.substring(separator + 1).trim();
    return result.isEmpty ? null : result;
  }
}

class ConversationReviewState {
  const ConversationReviewState({required this.underReview, this.startedAt});

  factory ConversationReviewState.fromJson(Map<String, dynamic> json) =>
      ConversationReviewState(
        underReview: json['under_review'] == true,
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
      );

  final bool underReview;
  final DateTime? startedAt;
}

class ReportEvidenceMessage {
  const ReportEvidenceMessage({
    required this.id,
    required this.conversationId,
    required this.sequence,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.body,
    this.editedAt,
    this.deletedAt,
  });

  factory ReportEvidenceMessage.fromJson(Map<String, dynamic> json) =>
      ReportEvidenceMessage(
        id: json['id'].toString(),
        conversationId: json['conversation_id'].toString(),
        sequence: (json['seq'] as num?)?.toInt() ?? 0,
        senderId: json['sender_id'].toString(),
        type: json['type']?.toString() ?? 'text',
        body: json['body']?.toString(),
        editedAt: DateTime.tryParse(json['edited_at']?.toString() ?? ''),
        deletedAt: DateTime.tryParse(json['deleted_at']?.toString() ?? ''),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;
  final String conversationId;
  final int sequence;
  final String senderId;
  final String type;
  final String? body;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
}
