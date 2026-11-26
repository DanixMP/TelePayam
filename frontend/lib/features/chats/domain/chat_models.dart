enum ConversationType { dm, group, channel }

enum MessageDelivery { sending, sent, failed }

class MediaAttachment {
  const MediaAttachment({
    required this.id,
    required this.kind,
    required this.mime,
    required this.size,
    required this.status,
    this.originalName,
    this.width,
    this.height,
    this.duration,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) =>
      MediaAttachment(
        id: json['id'].toString(),
        kind: json['kind']?.toString() ?? 'file',
        mime: json['mime']?.toString() ?? 'application/octet-stream',
        size: (json['size'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'ready',
        originalName: json['original_name']?.toString(),
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        duration: (json['duration'] as num?)?.toDouble(),
      );

  final String id;
  final String kind;
  final String mime;
  final int size;
  final String status;
  final String? originalName;
  final int? width;
  final int? height;
  final double? duration;
}

class ChatSticker {
  const ChatSticker({
    required this.id,
    required this.mediaId,
    required this.position,
    this.emoji,
  });

  factory ChatSticker.fromJson(Map<String, dynamic> json) => ChatSticker(
    id: json['id'].toString(),
    mediaId: json['media_id'].toString(),
    emoji: json['emoji']?.toString(),
    position: (json['position'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String mediaId;
  final String? emoji;
  final int position;
}

class ChatStickerPack {
  const ChatStickerPack({
    required this.id,
    required this.handle,
    required this.title,
    required this.kind,
    required this.stickers,
    required this.isOfficial,
  });

  factory ChatStickerPack.fromJson(Map<String, dynamic> json) =>
      ChatStickerPack(
        id: json['id'].toString(),
        handle: json['handle']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'static',
        isOfficial: json['is_official'] == true,
        stickers: (json['stickers'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => ChatSticker.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );

  final String id;
  final String handle;
  final String title;
  final String kind;
  final bool isOfficial;
  final List<ChatSticker> stickers;
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    required this.title,
    required this.ownerId,
    required this.memberCount,
    required this.lastSequence,
    required this.lastReadSequence,
    required this.updatedAt,
    this.handle,
    this.avatarId,
    this.description,
    this.visibility = 'private',
    this.myRole,
    this.lastMessageBody,
    this.lastMessageAt,
    this.isProfessorChannel = false,
    this.underReview = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final type = ConversationType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => ConversationType.dm,
    );
    final fallbackTitle = switch (type) {
      ConversationType.dm => json['handle']?.toString() ?? 'Direct message',
      ConversationType.group => 'Group',
      ConversationType.channel => 'Channel',
    };
    return ChatConversation(
      id: json['id'].toString(),
      type: type,
      title: json['title']?.toString() ?? fallbackTitle,
      handle: json['handle']?.toString(),
      avatarId: json['avatar_id'] as String?,
      lastMessageBody: json['last_message_body'] as String?,
      lastMessageAt: _serverTime(json['last_message_at']),
      description: json['description']?.toString(),
      visibility: json['visibility']?.toString() ?? 'private',
      ownerId: json['owner_id'].toString(),
      myRole: json['my_role']?.toString(),
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      lastSequence: (json['last_seq'] as num?)?.toInt() ?? 0,
      lastReadSequence: (json['last_read_seq'] as num?)?.toInt() ?? 0,
      isProfessorChannel: json['is_professor_channel'] == true,
      underReview: json['under_review'] == true,
      updatedAt:
          _serverTime(json['updated_at'] ?? json['created_at']) ??
          DateTime.now(),
    );
  }

  final String id;
  final ConversationType type;
  final String title;
  final String? handle;
  final String? avatarId;
  final String? description;
  final String visibility;
  final String ownerId;
  final String? myRole;
  final int memberCount;
  final int lastSequence;
  final int lastReadSequence;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
  final bool isProfessorChannel;
  final bool underReview;
  final DateTime updatedAt;

  int get unreadCount => (lastSequence - lastReadSequence).clamp(0, 999);

  ChatConversation copyWith({DateTime? updatedAt}) => ChatConversation(
    id: id,
    type: type,
    title: title,
    ownerId: ownerId,
    memberCount: memberCount,
    lastSequence: lastSequence,
    lastReadSequence: lastReadSequence,
    updatedAt: updatedAt ?? this.updatedAt,
    handle: handle,
    avatarId: avatarId,
    description: description,
    visibility: visibility,
    myRole: myRole,
    lastMessageBody: lastMessageBody,
    lastMessageAt: lastMessageAt,
    isProfessorChannel: isProfessorChannel,
    underReview: underReview,
  );
}

class ChatPoll {
  const ChatPoll({
    required this.question,
    required this.options,
    required this.voteCounts,
    this.multipleChoice = false,
    this.closedAt,
  });

  factory ChatPoll.fromJson(Map<String, dynamic> json) => ChatPoll(
    question: json['question']?.toString() ?? '',
    options: (json['options'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    voteCounts: (json['vote_counts'] as List<dynamic>? ?? const [])
        .map((item) => (item as num?)?.toInt() ?? 0)
        .toList(growable: false),
    multipleChoice: json['multiple_choice'] == true,
    closedAt: DateTime.tryParse(json['closed_at']?.toString() ?? ''),
  );

  final String question;
  final List<String> options;
  final List<int> voteCounts;
  final bool multipleChoice;
  final DateTime? closedAt;

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'vote_counts': voteCounts,
    'multiple_choice': multipleChoice,
    'closed_at': closedAt?.toIso8601String(),
  };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.createdAt,
    required this.delivery,
    this.sequence,
    this.clientMessageId,
    this.body,
    this.replyToId,
    this.entities = const [],
    this.forwardFrom,
    this.attachmentIds = const [],
    this.reactions = const {},
    this.poll,
    this.silent = false,
    this.editedAt,
    this.deletedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'].toString(),
    conversationId: json['conversation_id'].toString(),
    sequence: (json['seq'] as num?)?.toInt(),
    senderId: json['sender_id'].toString(),
    clientMessageId: json['client_msg_id']?.toString(),
    type: json['type']?.toString() ?? 'text',
    body: json['body']?.toString(),
    replyToId: json['reply_to_id']?.toString(),
    entities: (json['entities'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false),
    forwardFrom: json['forward_from'] is Map
        ? Map<String, dynamic>.from(json['forward_from'] as Map)
        : null,
    attachmentIds: (json['attachment_ids'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    reactions: (json['reactions'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
    ),
    poll: json['poll'] is Map
        ? ChatPoll.fromJson(Map<String, dynamic>.from(json['poll'] as Map))
        : null,
    silent: json['silent'] == true,
    editedAt: DateTime.tryParse(json['edited_at']?.toString() ?? ''),
    deletedAt: DateTime.tryParse(json['deleted_at']?.toString() ?? ''),
    createdAt: _serverTime(json['created_at']) ?? DateTime.now(),
    delivery: MessageDelivery.sent,
  );

  final String id;
  final String conversationId;
  final int? sequence;
  final String senderId;
  final String? clientMessageId;
  final String type;
  final String? body;
  final String? replyToId;
  final List<Map<String, dynamic>> entities;
  final Map<String, dynamic>? forwardFrom;
  final List<String> attachmentIds;
  final Map<String, int> reactions;
  final ChatPoll? poll;
  final bool silent;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final MessageDelivery delivery;

  bool isMine(String? accountId) => senderId == accountId;

  ChatMessage copyWith({
    String? body,
    Map<String, int>? reactions,
    ChatPoll? poll,
    DateTime? editedAt,
    DateTime? deletedAt,
    MessageDelivery? delivery,
  }) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    type: type,
    createdAt: createdAt,
    delivery: delivery ?? this.delivery,
    sequence: sequence,
    clientMessageId: clientMessageId,
    body: body ?? this.body,
    replyToId: replyToId,
    entities: entities,
    forwardFrom: forwardFrom,
    attachmentIds: attachmentIds,
    reactions: reactions ?? this.reactions,
    poll: poll ?? this.poll,
    silent: silent,
    editedAt: editedAt ?? this.editedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}

DateTime? _serverTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(
    RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(raw) ? raw : '${raw}Z',
  )?.toLocal();
}
