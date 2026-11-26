import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:university_messenger/core/network/realtime_client.dart';
import 'package:university_messenger/core/storage/app_database.dart';
import 'package:university_messenger/features/chats/data/chat_api.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/features/chats/domain/chat_repository.dart';

class LocalFirstChatRepository implements ChatRepository {
  LocalFirstChatRepository({
    required AppDatabase database,
    required String? Function() accountId,
    ChatApi? api,
    RealtimeClient? realtime,
    bool demoMode = false,
  }) : _database = database,
       _accountId = accountId,
       _api = api,
       _realtime = realtime,
       _demoMode = demoMode;

  final AppDatabase _database;
  final String? Function() _accountId;
  final ChatApi? _api;
  final RealtimeClient? _realtime;
  final bool _demoMode;
  final _typing = StreamController<Map<String, Set<String>>>.broadcast();
  final Map<String, Set<String>> _typingUsers = {};
  final Map<String, Timer> _typingExpiry = {};
  final Map<String, int> _messageLimits = {};
  final Map<String, void Function()> _messageWindowRefresh = {};
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  var _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (_demoMode) {
      await _seedDemoData();
      _initialized = true;
      return;
    }
    try {
      _realtimeSubscription = _realtime?.events.listen(_handleRealtimeEvent);
      await _realtime?.connect();
      await refreshConversations();
      await _flushOutbox();
      _initialized = true;
    } catch (_) {
      await _realtimeSubscription?.cancel();
      _realtimeSubscription = null;
      rethrow;
    }
  }

  @override
  Stream<List<ChatConversation>> watchConversations({String query = ''}) {
    final normalized = query.trim().toLowerCase();
    return (_database.select(
      _database.conversations,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch().asyncMap((
      rows,
    ) async {
      if (normalized.isEmpty) return rows.map(_conversationFromRow).toList();
      final matchingMessages = await (_database.select(
        _database.messages,
      )..where((row) => row.body.lower().like('%$normalized%'))).get();
      final matchingIds = matchingMessages
          .map((message) => message.conversationId)
          .toSet();
      return rows
          .where(
            (row) =>
                (row.title ?? '').toLowerCase().contains(normalized) ||
                (row.handle ?? '').toLowerCase().contains(normalized) ||
                matchingIds.contains(row.id),
          )
          .map(_conversationFromRow)
          .toList();
    });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    StreamSubscription<List<Message>>? subscription;
    late final StreamController<List<ChatMessage>> controller;

    Future<void> subscribeToWindow() async {
      await subscription?.cancel();
      final limit = _messageLimits.putIfAbsent(conversationId, () => 100);
      subscription =
          (_database.select(_database.messages)
                ..where((row) => row.conversationId.equals(conversationId))
                ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
                ..limit(limit))
              .watch()
              .listen(
                (rows) =>
                    controller.add(rows.reversed.map(_messageFromRow).toList()),
                onError: controller.addError,
              );
    }

    controller = StreamController<List<ChatMessage>>(
      onListen: () {
        _messageWindowRefresh[conversationId] = () {
          unawaited(subscribeToWindow());
        };
        unawaited(subscribeToWindow());
      },
      onCancel: () async {
        _messageWindowRefresh.remove(conversationId);
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<Set<String>> watchTypingUsers(String conversationId) => _typing.stream
      .map((state) => state[conversationId] ?? const <String>{})
      .startWith(_typingUsers[conversationId] ?? const <String>{});

  @override
  Future<void> refreshConversations() async {
    final api = _api;
    if (api == null) return;
    final conversations = await api.listConversations();
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.conversations,
        conversations.map(_conversationCompanion).toList(),
      );
    });
  }

  @override
  Future<String> openDm(String userId) async {
    final api = _api;
    if (api == null) {
      throw StateError('Connect to the messenger server to start a chat.');
    }
    final item = await api.openDm(userId);
    await _database
        .into(_database.conversations)
        .insertOnConflictUpdate(_conversationCompanion(item));
    return item.id;
  }

  @override
  Future<void> loadRecentMessages(String conversationId) async {
    final api = _api;
    if (api == null) return;
    final conversation = await (_database.select(
      _database.conversations,
    )..where((row) => row.id.equals(conversationId))).getSingleOrNull();
    final messages = await api.listMessages(
      conversationId,
      beforeSequence: (conversation?.lastSequence ?? 0) + 1,
    );
    await _storeMessages(messages);
  }

  @override
  Future<void> loadOlderMessages(String conversationId) async {
    final api = _api;
    if (api == null) {
      _expandMessageWindow(conversationId);
      return;
    }
    final oldest =
        await (_database.select(_database.messages)
              ..where(
                (row) =>
                    row.conversationId.equals(conversationId) &
                    row.sequence.isNotNull(),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.sequence)])
              ..limit(1))
            .getSingleOrNull();
    if (oldest?.sequence == null || oldest!.sequence! <= 1) return;
    final messages = await api.listMessages(
      conversationId,
      beforeSequence: oldest.sequence,
    );
    await _storeMessages(messages);
    if (messages.isNotEmpty) _expandMessageWindow(conversationId);
  }

  void _expandMessageWindow(String conversationId) {
    _messageLimits.update(
      conversationId,
      (value) => value + 50,
      ifAbsent: () => 150,
    );
    _messageWindowRefresh[conversationId]?.call();
  }

  @override
  Future<void> sendText(String conversationId, String body) =>
      sendMessage(conversationId, body: body);

  @override
  Future<void> sendMessage(
    String conversationId, {
    String type = 'text',
    String? body,
    String? replyToId,
    List<String> attachmentIds = const [],
    ChatPoll? poll,
    Map<String, dynamic>? forwardFrom,
    bool silent = false,
  }) async {
    final trimmed = body?.trim();
    if ((trimmed == null || trimmed.isEmpty) &&
        attachmentIds.isEmpty &&
        poll == null) {
      return;
    }
    final clientId = _newClientMessageId();
    final now = DateTime.now();
    final payload = {
      'conversation_id': conversationId,
      'client_msg_id': clientId,
      'type': type,
      'body': trimmed,
      'reply_to_id': replyToId,
      'attachment_ids': attachmentIds,
      'poll': poll?.toJson(),
      'forward_from': forwardFrom,
      'silent': silent,
    };
    await _database.transaction(() async {
      await _database
          .into(_database.messages)
          .insert(
            MessagesCompanion.insert(
              id: 'local:$clientId',
              conversationId: conversationId,
              senderId: _accountId() ?? 'local-user',
              clientMessageId: Value(clientId),
              type: Value(type),
              body: Value(trimmed),
              replyToId: Value(replyToId),
              attachmentIds: Value(jsonEncode(attachmentIds)),
              poll: Value(poll == null ? null : jsonEncode(poll.toJson())),
              forwardFrom: Value(
                forwardFrom == null ? null : jsonEncode(forwardFrom),
              ),
              silent: Value(silent),
              status: MessageDelivery.sending.name,
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
      await _database
          .into(_database.outbox)
          .insert(
            OutboxCompanion.insert(
              clientMessageId: clientId,
              conversationId: conversationId,
              payload: jsonEncode(payload),
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
      await _updateConversationPreview(
        conversationId,
        trimmed ?? _previewForType(type),
        now,
      );
    });
    if (_demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      await _markDemoSent(clientId);
    } else {
      await _flushOutbox(clientMessageId: clientId);
    }
  }

  @override
  Future<MediaAttachment> uploadFile({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final api = _api;
    if (api == null) {
      return MediaAttachment(
        id: 'demo-media-${_newClientMessageId()}',
        kind: 'file',
        mime: 'application/octet-stream',
        size: 0,
        status: 'ready',
        originalName: fileName,
      );
    }
    return api.uploadFile(
      path: path,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> editMessage(String messageId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    if (_demoMode) {
      await (_database.update(
        _database.messages,
      )..where((row) => row.id.equals(messageId))).write(
        MessagesCompanion(
          body: Value(trimmed),
          editedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return;
    }
    final updated = await _api!.editMessage(messageId, trimmed);
    await _storeMessages([updated]);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    if (!_demoMode) await _api!.deleteMessage(messageId);
    await (_database.update(
      _database.messages,
    )..where((row) => row.id.equals(messageId))).write(
      MessagesCompanion(
        body: const Value(null),
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> addReaction(String messageId, String emoji) async {
    if (_demoMode) {
      final message = await (_database.select(
        _database.messages,
      )..where((row) => row.id.equals(messageId))).getSingle();
      final reactions = Map<String, int>.from(
        jsonDecode(message.reactionCounts) as Map,
      );
      reactions.update(emoji, (count) => count + 1, ifAbsent: () => 1);
      await (_database.update(
        _database.messages,
      )..where((row) => row.id.equals(messageId))).write(
        MessagesCompanion(reactionCounts: Value(jsonEncode(reactions))),
      );
      return;
    }
    await _storeMessages([await _api!.addReaction(messageId, emoji)]);
  }

  @override
  Future<void> removeReaction(String messageId, String emoji) async {
    if (_demoMode) return;
    await _storeMessages([await _api!.removeReaction(messageId, emoji)]);
  }

  @override
  Future<void> votePoll(String messageId, List<int> optionIndexes) async {
    if (_demoMode) return;
    await _storeMessages([await _api!.votePoll(messageId, optionIndexes)]);
  }

  @override
  Future<void> setPinned(String messageId, bool pinned) async {
    if (!_demoMode) await _api!.setPinned(messageId, pinned);
  }

  @override
  Future<List<ChatMessage>> listPinned(String conversationId) async {
    if (_demoMode) return const [];
    return _api!.listPinned(conversationId);
  }

  @override
  Future<List<ChatStickerPack>> listStickerPacks() async {
    if (_demoMode) return const [];
    return _api!.listStickerPacks();
  }

  @override
  Future<List<ChatSticker>> listFavoriteStickers() async {
    if (_demoMode) return const [];
    return _api!.listFavoriteStickers();
  }

  @override
  Future<List<ChatSticker>> listRecentStickers() async {
    if (_demoMode) return const [];
    return _api!.listRecentStickers();
  }

  @override
  Future<void> markStickerRecent(String stickerId) async {
    if (!_demoMode) await _api!.markStickerRecent(stickerId);
  }

  @override
  Future<List<String>> listSavedGifs() async {
    if (_demoMode) return const [];
    return _api!.listSavedGifs();
  }

  @override
  Future<void> retryMessage(String clientMessageId) async {
    await (_database.update(_database.messages)
          ..where((row) => row.clientMessageId.equals(clientMessageId)))
        .write(const MessagesCompanion(status: Value('sending')));
    await _flushOutbox(clientMessageId: clientMessageId);
  }

  Future<void> _flushOutbox({String? clientMessageId}) async {
    final api = _api;
    if (api == null) return;
    final query = _database.select(_database.outbox);
    if (clientMessageId != null) {
      query.where((row) => row.clientMessageId.equals(clientMessageId));
    }
    final queued = await query.get();
    for (final item in queued) {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      try {
        final pollJson = payload['poll'];
        final message = await api.sendMessage(
          conversationId: item.conversationId,
          clientMessageId: item.clientMessageId,
          type: payload['type']?.toString() ?? 'text',
          body: payload['body']?.toString(),
          replyToId: payload['reply_to_id']?.toString(),
          attachmentIds:
              (payload['attachment_ids'] as List<dynamic>? ?? const [])
                  .map((id) => id.toString())
                  .toList(),
          poll: pollJson is Map
              ? ChatPoll.fromJson(Map<String, dynamic>.from(pollJson))
              : null,
          forwardFrom: payload['forward_from'] is Map
              ? Map<String, dynamic>.from(payload['forward_from'] as Map)
              : null,
          silent: payload['silent'] == true,
        );
        await _replaceOptimisticMessage(item.clientMessageId, message);
      } catch (error) {
        await (_database.update(
              _database.outbox,
            )..where((row) => row.clientMessageId.equals(item.clientMessageId)))
            .write(
              OutboxCompanion(
                attempts: Value(item.attempts + 1),
                lastError: Value(error.toString()),
              ),
            );
        await (_database.update(
              _database.messages,
            )..where((row) => row.clientMessageId.equals(item.clientMessageId)))
            .write(const MessagesCompanion(status: Value('failed')));
      }
    }
  }

  @override
  Future<void> markRead(String conversationId, int sequence) async {
    final current = await (_database.select(
      _database.conversations,
    )..where((row) => row.id.equals(conversationId))).getSingleOrNull();
    if (current != null && current.lastReadSequence >= sequence) return;
    await (_database.update(_database.conversations)
          ..where((row) => row.id.equals(conversationId)))
        .write(ConversationsCompanion(lastReadSequence: Value(sequence)));
    if (_demoMode) return;
    _realtime?.sendRead(conversationId, sequence);
    try {
      await _api?.markRead(conversationId, sequence);
    } catch (_) {
      // The local marker remains monotonic and will be sent again on next open.
    }
  }

  @override
  void setTyping(String conversationId, bool typing) {
    if (!_demoMode) _realtime?.sendTyping(conversationId, typing);
  }

  Future<void> _handleRealtimeEvent(RealtimeEvent event) async {
    if (event.type == 'connected') {
      final conversations = await _database
          .select(_database.conversations)
          .get();
      _realtime?.sync({
        for (final item in conversations) item.id: item.lastSequence,
      });
      await refreshConversations();
      await _flushOutbox();
      return;
    }
    if (event.type == 'msg.new' && event.data is Map) {
      final message = ChatMessage.fromJson(
        Map<String, dynamic>.from(event.data! as Map),
      );
      if (_api != null &&
          await (_database.select(_database.conversations)
                    ..where((row) => row.id.equals(message.conversationId)))
                  .getSingleOrNull() ==
              null) {
        final chat = await _api.conversation(message.conversationId);
        await _database
            .into(_database.conversations)
            .insertOnConflictUpdate(_conversationCompanion(chat));
      }
      await _storeMessages([message]);
      return;
    }
    if ((event.type == 'msg.edited' ||
            event.type == 'msg.reactions' ||
            event.type == 'poll.updated') &&
        event.data is Map) {
      await _storeMessages([
        ChatMessage.fromJson(Map<String, dynamic>.from(event.data! as Map)),
      ]);
      return;
    }
    if (event.type == 'msg.deleted' && event.data is Map) {
      final data = Map<String, dynamic>.from(event.data! as Map);
      final id = data['id']?.toString();
      if (id != null) {
        if (data['conversation_id'] != null) {
          await _storeMessages([ChatMessage.fromJson(data)]);
        } else {
          await (_database.update(
            _database.messages,
          )..where((row) => row.id.equals(id))).write(
            MessagesCompanion(
              body: const Value(null),
              deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
        }
      }
      return;
    }
    if (event.type == 'sync.result' && event.data is List) {
      await _storeMessages(
        (event.data! as List)
            .cast<Map>()
            .map(
              (json) => ChatMessage.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList(),
      );
      return;
    }
    if (event.type == 'read.update' && event.data is Map) {
      final data = Map<String, dynamic>.from(event.data! as Map);
      if (data['user'] == _accountId()) {
        await (_database.update(
          _database.conversations,
        )..where((row) => row.id.equals(data['conv'].toString()))).write(
          ConversationsCompanion(
            lastReadSequence: Value((data['seq'] as num).toInt()),
          ),
        );
      }
      return;
    }
    if (event.type == 'typing' && event.data is Map) {
      final data = Map<String, dynamic>.from(event.data! as Map);
      final conversationId = data['conv'].toString();
      final userId = data['user'].toString();
      if (userId == _accountId()) return;
      final users = _typingUsers.putIfAbsent(conversationId, () => <String>{});
      if (data['action'] == 'stopped') {
        users.remove(userId);
      } else {
        users.add(userId);
        final key = '$conversationId:$userId';
        _typingExpiry[key]?.cancel();
        _typingExpiry[key] = Timer(const Duration(seconds: 6), () {
          users.remove(userId);
          _typing.add(Map.of(_typingUsers));
        });
      }
      _typing.add(Map.of(_typingUsers));
    }
  }

  Future<void> _storeMessages(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.messages,
        messages.map(_messageCompanion).toList(),
      );
    });
    for (final message in messages) {
      await _updateConversationPreview(
        message.conversationId,
        message.deletedAt == null
            ? message.body ?? _previewForType(message.type)
            : 'Message deleted',
        message.createdAt,
        sequence: message.sequence,
      );
    }
  }

  Future<void> _replaceOptimisticMessage(
    String clientMessageId,
    ChatMessage message,
  ) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.messages,
      )..where((row) => row.id.equals('local:$clientMessageId'))).go();
      await _database
          .into(_database.messages)
          .insertOnConflictUpdate(_messageCompanion(message));
      await (_database.delete(
        _database.outbox,
      )..where((row) => row.clientMessageId.equals(clientMessageId))).go();
      await _updateConversationPreview(
        message.conversationId,
        message.body ?? _previewForType(message.type),
        message.createdAt,
        sequence: message.sequence,
      );
    });
  }

  Future<void> _markDemoSent(String clientMessageId) async {
    final local = await (_database.select(
      _database.messages,
    )..where((row) => row.clientMessageId.equals(clientMessageId))).getSingle();
    final conversation = await (_database.select(
      _database.conversations,
    )..where((row) => row.id.equals(local.conversationId))).getSingle();
    await (_database.update(
      _database.messages,
    )..where((row) => row.id.equals(local.id))).write(
      MessagesCompanion(
        sequence: Value(conversation.lastSequence + 1),
        status: const Value('sent'),
      ),
    );
    await (_database.delete(
      _database.outbox,
    )..where((row) => row.clientMessageId.equals(clientMessageId))).go();
    await (_database.update(
      _database.conversations,
    )..where((row) => row.id.equals(local.conversationId))).write(
      ConversationsCompanion(
        lastSequence: Value(conversation.lastSequence + 1),
      ),
    );
  }

  Future<void> _updateConversationPreview(
    String conversationId,
    String? body,
    DateTime date, {
    int? sequence,
  }) async {
    final current = await (_database.select(
      _database.conversations,
    )..where((row) => row.id.equals(conversationId))).getSingleOrNull();
    if (current == null) return;
    if (sequence != null && sequence < current.lastSequence) return;
    if (current.lastMessageAt != null &&
        date.millisecondsSinceEpoch < current.lastMessageAt!) {
      return;
    }
    await (_database.update(
      _database.conversations,
    )..where((row) => row.id.equals(conversationId))).write(
      ConversationsCompanion(
        lastMessageBody: Value(body),
        lastMessageAt: Value(date.millisecondsSinceEpoch),
        updatedAt: Value(date.millisecondsSinceEpoch),
        lastSequence: sequence == null ? const Value.absent() : Value(sequence),
      ),
    );
  }

  ConversationsCompanion _conversationCompanion(ChatConversation item) =>
      ConversationsCompanion.insert(
        id: item.id,
        type: item.type.name,
        title: Value(item.title),
        handle: Value(item.handle),
        avatarId: Value(item.avatarId),
        lastMessageBody: Value(item.lastMessageBody),
        lastMessageAt: Value(item.lastMessageAt?.millisecondsSinceEpoch),
        description: Value(item.description),
        visibility: Value(item.visibility),
        ownerId: item.ownerId,
        myRole: Value(item.myRole),
        memberCount: Value(item.memberCount),
        lastSequence: Value(item.lastSequence),
        lastReadSequence: Value(item.lastReadSequence),
        isProfessorChannel: Value(item.isProfessorChannel),
        underReview: Value(item.underReview),
        updatedAt: item.updatedAt.millisecondsSinceEpoch,
      );

  ChatConversation _conversationFromRow(Conversation row) => ChatConversation(
    id: row.id,
    type: ConversationType.values.firstWhere(
      (type) => type.name == row.type,
      orElse: () => ConversationType.dm,
    ),
    title: row.title ?? row.handle ?? 'Conversation',
    handle: row.handle,
    avatarId: row.avatarId,
    description: row.description,
    visibility: row.visibility,
    ownerId: row.ownerId,
    myRole: row.myRole,
    memberCount: row.memberCount,
    lastSequence: row.lastSequence,
    lastReadSequence: row.lastReadSequence,
    lastMessageBody: row.lastMessageBody,
    lastMessageAt: row.lastMessageAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.lastMessageAt!),
    isProfessorChannel: row.isProfessorChannel,
    underReview: row.underReview,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  MessagesCompanion _messageCompanion(ChatMessage item) =>
      MessagesCompanion.insert(
        id: item.id,
        conversationId: item.conversationId,
        senderId: item.senderId,
        sequence: Value(item.sequence),
        clientMessageId: Value(item.clientMessageId),
        type: Value(item.type),
        body: Value(item.body),
        status: item.delivery.name,
        replyToId: Value(item.replyToId),
        entities: Value(jsonEncode(item.entities)),
        forwardFrom: Value(
          item.forwardFrom == null ? null : jsonEncode(item.forwardFrom),
        ),
        attachmentIds: Value(jsonEncode(item.attachmentIds)),
        reactionCounts: Value(jsonEncode(item.reactions)),
        poll: Value(item.poll == null ? null : jsonEncode(item.poll!.toJson())),
        silent: Value(item.silent),
        editedAt: Value(item.editedAt?.millisecondsSinceEpoch),
        deletedAt: Value(item.deletedAt?.millisecondsSinceEpoch),
        createdAt: item.createdAt.millisecondsSinceEpoch,
      );

  ChatMessage _messageFromRow(Message row) => ChatMessage(
    id: row.id,
    conversationId: row.conversationId,
    sequence: row.sequence,
    senderId: row.senderId,
    clientMessageId: row.clientMessageId,
    type: row.type,
    body: row.body,
    replyToId: row.replyToId,
    entities: (jsonDecode(row.entities) as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
    forwardFrom: row.forwardFrom == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(row.forwardFrom!) as Map),
    attachmentIds: (jsonDecode(row.attachmentIds) as List)
        .map((item) => item.toString())
        .toList(),
    reactions: Map<String, dynamic>.from(
      jsonDecode(row.reactionCounts) as Map,
    ).map((key, value) => MapEntry(key, (value as num).toInt())),
    poll: row.poll == null
        ? null
        : ChatPoll.fromJson(
            Map<String, dynamic>.from(jsonDecode(row.poll!) as Map),
          ),
    silent: row.silent,
    editedAt: row.editedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.editedAt!),
    deletedAt: row.deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    delivery: MessageDelivery.values.firstWhere(
      (status) => status.name == row.status,
      orElse: () => MessageDelivery.sent,
    ),
  );

  Future<void> _seedDemoData() async {
    if (await _database
        .select(_database.conversations)
        .get()
        .then((rows) => rows.isNotEmpty)) {
      return;
    }
    final now = DateTime.now();
    final conversations = [
      ChatConversation(
        id: 'demo-study',
        type: ConversationType.group,
        title: 'Study Group · Algorithms',
        ownerId: 'student-2',
        memberCount: 18,
        lastSequence: 3,
        lastReadSequence: 2,
        lastMessageBody: 'I uploaded the practice set.',
        lastMessageAt: now.subtract(const Duration(minutes: 8)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
      ),
      ChatConversation(
        id: 'demo-professor',
        type: ConversationType.channel,
        title: 'Professor Rahimi · Data Structures',
        ownerId: 'professor-1',
        memberCount: 246,
        lastSequence: 2,
        lastReadSequence: 2,
        lastMessageBody: 'Office hours moved to 14:30.',
        lastMessageAt: now.subtract(const Duration(hours: 1)),
        isProfessorChannel: true,
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      ChatConversation(
        id: 'demo-sara',
        type: ConversationType.dm,
        title: 'Sara Ahmadi',
        handle: 'sara.ahmadi',
        ownerId: 'demo-user',
        memberCount: 2,
        lastSequence: 2,
        lastReadSequence: 2,
        lastMessageBody: 'See you at the library.',
        lastMessageAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    await _database.batch((batch) {
      batch.insertAll(
        _database.conversations,
        conversations.map(_conversationCompanion).toList(),
      );
    });
    await _storeMessages([
      ChatMessage(
        id: 'study-1',
        conversationId: 'demo-study',
        sequence: 1,
        senderId: 'student-2',
        type: 'text',
        body: 'Does anyone want to review dynamic programming today?',
        createdAt: now.subtract(const Duration(minutes: 23)),
        delivery: MessageDelivery.sent,
      ),
      ChatMessage(
        id: 'study-2',
        conversationId: 'demo-study',
        sequence: 2,
        senderId: _accountId() ?? 'demo-user',
        type: 'text',
        body: 'Yes, after the 2 PM lecture works for me.',
        createdAt: now.subtract(const Duration(minutes: 16)),
        delivery: MessageDelivery.sent,
      ),
      ChatMessage(
        id: 'study-3',
        conversationId: 'demo-study',
        sequence: 3,
        senderId: 'student-3',
        type: 'text',
        body: 'I uploaded the practice set.',
        createdAt: now.subtract(const Duration(minutes: 8)),
        delivery: MessageDelivery.sent,
      ),
      ChatMessage(
        id: 'prof-1',
        conversationId: 'demo-professor',
        sequence: 1,
        senderId: 'professor-1',
        type: 'text',
        body: 'The week six slides are now available.',
        createdAt: now.subtract(const Duration(hours: 3)),
        delivery: MessageDelivery.sent,
      ),
      ChatMessage(
        id: 'prof-2',
        conversationId: 'demo-professor',
        sequence: 2,
        senderId: 'professor-1',
        type: 'text',
        body: 'Office hours moved to 14:30.',
        createdAt: now.subtract(const Duration(hours: 1)),
        delivery: MessageDelivery.sent,
      ),
    ]);
  }

  String _newClientMessageId() {
    final random = Random.secure();
    final suffix = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  String _previewForType(String type) => switch (type) {
    'poll' => 'Poll',
    'image' => 'Photo',
    'video' => 'Video',
    'voice' || 'audio' => 'Voice message',
    'sticker' => 'Sticker',
    _ => 'Attachment',
  };

  @override
  Future<void> dispose() async {
    await _realtimeSubscription?.cancel();
    for (final timer in _typingExpiry.values) {
      timer.cancel();
    }
    await _typing.close();
  }
}

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
