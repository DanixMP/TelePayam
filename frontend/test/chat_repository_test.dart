import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/core/storage/app_database.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/chats/chat_strings.dart';
import 'package:university_messenger/features/chats/data/chat_api.dart';
import 'package:university_messenger/features/chats/data/local_first_chat_repository.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/l10n/generated/app_localizations_en.dart';
import 'package:university_messenger/l10n/generated/app_localizations_fa.dart';

void main() {
  late AppDatabase database;
  late LocalFirstChatRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalFirstChatRepository(
      database: database,
      accountId: () => 'demo-user',
      demoMode: true,
    );
    await repository.initialize();
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test('seeds and searches local conversation/message data', () async {
    final conversations = await repository.watchConversations().first;
    expect(conversations, hasLength(3));

    final results = await repository
        .watchConversations(query: 'practice set')
        .first;
    expect(results.single.id, 'demo-study');
  });

  test(
    'v4 cache distinguishes generated previews from authored text',
    () async {
      final dir = await Directory.systemTemp.createTemp('messenger-cache-test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/cache.sqlite');
      final legacy = AppDatabase(NativeDatabase(file));
      final previews = {
        'image': (preview: 'Image', body: null, deletedAt: null),
        'authored': (preview: 'Image', body: 'Image', deletedAt: null),
        'deleted': (preview: 'Message deleted', body: null, deletedAt: 200),
        'unknown': (preview: 'Image', body: null, deletedAt: null),
        'pending': (
          preview: 'Image',
          body: 'Previous message',
          deletedAt: null,
        ),
      };
      try {
        await legacy.batch((batch) {
          for (final entry in previews.entries) {
            final preview = entry.value;
            batch.insert(
              legacy.conversations,
              ConversationsCompanion.insert(
                id: entry.key,
                type: 'dm',
                ownerId: 'demo-user',
                updatedAt: 100,
                lastSequence: const Value(1),
                lastMessageBody: Value(preview.preview),
                lastMessageAt: Value(entry.key == 'pending' ? 200 : 100),
              ),
            );
            if (entry.key == 'unknown') continue;
            batch.insert(
              legacy.messages,
              MessagesCompanion.insert(
                id: 'message-${entry.key}',
                conversationId: entry.key,
                senderId: 'demo-user',
                status: 'sent',
                createdAt: 100,
                sequence: const Value(1),
                type: Value(entry.key == 'image' ? 'image' : 'text'),
                body: Value(preview.body),
                deletedAt: Value(preview.deletedAt),
              ),
            );
          }
          batch.insert(
            legacy.messages,
            MessagesCompanion.insert(
              id: 'local:pending',
              conversationId: 'pending',
              senderId: 'demo-user',
              clientMessageId: const Value('pending'),
              type: const Value('image'),
              status: 'failed',
              createdAt: 200,
            ),
          );
          batch.insert(
            legacy.conversations,
            ConversationsCompanion.insert(
              id: 'saved',
              type: 'dm',
              title: const Value('Saved messages'),
              memberCount: const Value(1),
              ownerId: 'demo-user',
              updatedAt: 100,
            ),
          );
        });
        await legacy.customStatement(
          'ALTER TABLE conversations DROP COLUMN last_message_type',
        );
        await legacy.customStatement(
          'ALTER TABLE conversations DROP COLUMN last_message_edited_at',
        );
        await legacy.customStatement(
          'ALTER TABLE conversations DROP COLUMN is_saved_messages',
        );
        await legacy.customStatement('PRAGMA user_version = 4');
      } finally {
        await legacy.close();
      }

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final rows = await upgraded.select(upgraded.conversations).get();
      expect(
        {for (final row in rows) row.id: row.lastMessageType},
        {
          'image': 'image',
          'deleted': 'deleted',
          'authored': null,
          'unknown': null,
          'pending': null,
          'saved': null,
        },
      );
      expect(
        rows.singleWhere((row) => row.id == 'saved').isSavedMessages,
        isTrue,
      );
      expect(
        rows.singleWhere((row) => row.id == 'authored').lastMessageBody,
        'Image',
      );
      final pending = rows.singleWhere((row) => row.id == 'pending');
      expect(pending.lastMessageBody, 'Previous message');
      expect(pending.lastMessageAt, 100);
      expect(await upgraded.select(upgraded.messages).get(), hasLength(5));
    },
  );

  test('optimistic text message is reconciled and leaves the outbox', () async {
    await repository.sendText('demo-study', 'A new local-first message');

    final messages = await repository.watchMessages('demo-study').first;
    expect(messages.last.body, 'A new local-first message');
    expect(messages.last.delivery, MessageDelivery.sent);
    expect(await database.select(database.outbox).get(), isEmpty);
  });

  test(
    'late acknowledgements and refreshes cannot restore an older preview',
    () async {
      final api = _ControlledChatApi();
      final synced = LocalFirstChatRepository(
        database: database,
        accountId: () => 'demo-user',
        api: api,
      );
      final sends = StreamIterator(api.sends.stream);
      addTearDown(synced.dispose);
      addTearDown(api.sends.close);
      addTearDown(sends.cancel);

      Future<ChatConversation> study() async =>
          (await synced.watchConversations().first).firstWhere(
            (item) => item.id == 'demo-study',
          );
      final fa = AppLocalizationsFa();
      final snapshot = await study();
      final photo = synced.sendMessage(
        'demo-study',
        type: 'image',
        attachmentIds: ['photo'],
      );
      expect(await sends.moveNext(), isTrue);
      final acknowledgePhoto = sends.current;
      expect(chatPreview(fa, await study()), fa.photo);

      final text = synced.sendText('demo-study', 'Photo');
      expect(await sends.moveNext(), isTrue);
      expect(chatPreview(fa, await study()), 'Photo');
      final refresh = synced.refreshConversations();

      sends.current(5);
      await text;
      acknowledgePhoto(4);
      await photo;
      api.listResponse.complete([snapshot]);
      await refresh;

      final latest = await study();
      expect(latest.lastSequence, 5);
      expect(latest.lastMessageType, isNull);
      expect(chatPreview(fa, latest), 'Photo');
      expect(await database.select(database.outbox).get(), isEmpty);
    },
  );

  test(
    'a refresh at the same sequence preserves edits and the read marker',
    () async {
      final api = _ControlledChatApi();
      final synced = LocalFirstChatRepository(
        database: database,
        accountId: () => 'demo-user',
        api: api,
      );
      addTearDown(synced.dispose);

      Future<ChatConversation> study() async =>
          (await synced.watchConversations().first).firstWhere(
            (item) => item.id == 'demo-study',
          );
      final snapshot = await study();
      final fa = AppLocalizationsFa();
      final original = (await synced.watchMessages('demo-study').first).last;
      final refresh = synced.refreshConversations();
      await repository.editMessage('study-3', 'Photo');
      await repository.markRead('demo-study', snapshot.lastSequence);
      api.listResponse.complete([snapshot]);
      await refresh;

      final edited = await study();
      expect(chatPreview(fa, edited), 'Photo');
      expect(edited.unreadCount, 0);

      api.messages = [original];
      await synced.loadRecentMessages('demo-study');
      expect(
        (await synced.watchMessages('demo-study').first).last.body,
        'Photo',
      );

      final revised = ChatConversation.fromJson({
        'id': edited.id,
        'type': edited.type.name,
        'title': edited.title,
        'owner_id': edited.ownerId,
        'last_seq': edited.lastSequence,
        'last_read_seq': edited.lastReadSequence,
        'last_message_body': 'Revised on another device',
        'last_message_at': edited.lastMessageAt!.toUtc().toIso8601String(),
        'last_message_edited_at': edited.lastMessageEditedAt!
            .add(const Duration(seconds: 1))
            .toUtc()
            .toIso8601String(),
        'updated_at': edited.updatedAt.toUtc().toIso8601String(),
      });
      api.listResponse = Completer<List<ChatConversation>>()
        ..complete([revised]);
      await synced.refreshConversations();
      expect(chatPreview(fa, await study()), 'Revised on another device');

      api.listResponse = Completer<List<ChatConversation>>();
      final afterDelete = synced.refreshConversations();
      await repository.deleteMessage('study-3');
      api.listResponse.complete([edited]);
      await afterDelete;
      await synced.loadRecentMessages('demo-study');
      expect(chatPreview(fa, await study()), fa.messageDeleted);
      expect(
        (await synced.watchMessages('demo-study').first).last.deletedAt,
        isNotNull,
      );
    },
  );

  test(
    'latest generated preview follows locale before and after sending',
    () async {
      final en = AppLocalizationsEn();
      final fa = AppLocalizationsFa();
      Future<ChatConversation> study() async =>
          (await repository.watchConversations().first).firstWhere(
            (conversation) => conversation.id == 'demo-study',
          );
      expect(chatPreview(fa, await study()), fa.chatDemoStudyThree);

      final sending = repository.sendMessage(
        'demo-study',
        type: 'image',
        attachmentIds: ['local-photo'],
      );
      final optimistic = await repository.watchConversations().firstWhere(
        (chats) => chats.any((chat) => chat.lastMessageType == 'image'),
      );
      expect(chatPreview(fa, optimistic.first), fa.photo);
      await sending;
      expect(chatPreview(en, await study()), en.photo);
      expect(chatPreview(fa, await study()), fa.photo);

      await repository.sendText('demo-study', 'Photo');
      expect(chatPreview(fa, await study()), 'Photo');
      final messages = await repository.watchMessages('demo-study').first;
      await repository.editMessage(messages.last.id, 'یادداشت تازه');
      expect(chatPreview(en, await study()), 'یادداشت تازه');
      await repository.deleteMessage(messages.last.id);
      expect(chatPreview(fa, await study()), fa.messageDeleted);
    },
  );

  test(
    'localized search updates when an older translated message is edited',
    () async {
      final fa = AppLocalizationsFa();
      Stream<List<ChatConversation>> search(String query) =>
          repository.watchConversations(
            query: query,
            conversationSearchText: (chat) => [
              chatTitle(fa, chat),
              chatPreview(fa, chat),
            ],
            messageSearchText: (message) => chatMessageBody(fa, message),
          );
      expect(await search('dynamic programming').first, isEmpty);
      expect(await search('%').first, isEmpty);
      final results = StreamIterator(search('پويا'));
      addTearDown(results.cancel);
      expect(await results.moveNext(), isTrue);
      expect(results.current.single.id, 'demo-study');
      await repository.editMessage('study-1', 'نمونه ۱۰۰%');
      expect(await results.moveNext(), isTrue);
      expect(results.current, isEmpty);
      expect((await search('۱۰۰%').first).single.id, 'demo-study');
      await repository.deleteMessage('study-1');
      expect(await search('۱۰۰%').first, isEmpty);
    },
  );

  test('read marker only moves the selected conversation', () async {
    await repository.markRead('demo-study', 3);
    final conversations = await repository.watchConversations().first;
    final study = conversations.firstWhere((item) => item.id == 'demo-study');
    expect(study.lastReadSequence, 3);
    expect(study.unreadCount, 0);
  });

  test('loading older messages expands the visible database window', () async {
    final base = DateTime.now().subtract(const Duration(days: 2));
    await database.batch((batch) {
      batch.insertAll(
        database.messages,
        List.generate(
          120,
          (index) => MessagesCompanion.insert(
            id: 'window-$index',
            conversationId: 'demo-study',
            senderId: 'student-2',
            body: Value('Message $index'),
            status: 'sent',
            createdAt: base
                .add(Duration(minutes: index))
                .millisecondsSinceEpoch,
          ),
        ),
      );
    });

    expect(await repository.watchMessages('demo-study').first, hasLength(100));
    await repository.loadOlderMessages('demo-study');
    expect(await repository.watchMessages('demo-study').first, hasLength(123));
  });

  test('logout cleanup removes account-scoped chat and outbox data', () async {
    final accountCache = DriftAccountCache(database);
    await accountCache.write(
      Account(
        id: 'demo-user',
        phone: '+989121234567',
        role: UserRole.student,
        status: AccountStatus.active,
        createdAt: DateTime.now(),
      ),
    );
    await repository.sendText('demo-study', 'Clear this on logout');
    final message = (await database.select(database.messages).get()).first;
    await database
        .into(database.messageMedia)
        .insert(
          MessageMediaCompanion.insert(
            id: 'media-1',
            messageId: message.id,
            kind: 'image',
          ),
        );
    await database
        .into(database.reactions)
        .insert(
          ReactionsCompanion.insert(
            messageId: message.id,
            userId: 'demo-user',
            emoji: 'like',
          ),
        );
    await database
        .into(database.stickerPacks)
        .insert(StickerPacksCompanion.insert(id: 'pack-1', title: 'Demo'));
    await database
        .into(database.stickers)
        .insert(StickersCompanion.insert(id: 'sticker-1', packId: 'pack-1'));
    await database
        .into(database.savedGifs)
        .insert(
          SavedGifsCompanion.insert(
            id: 'gif-1',
            remoteUrl: 'https://example.test/gif.mp4',
            savedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await database
        .into(database.serviceRequests)
        .insert(
          ServiceRequestsCompanion.insert(
            id: 'request-1',
            serviceType: 'transcript',
            status: 'draft',
            payload: '{}',
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

    await accountCache.clearSessionData();

    expect(await database.select(database.cachedUsers).get(), isEmpty);
    expect(await database.select(database.conversations).get(), isEmpty);
    expect(await database.select(database.messages).get(), isEmpty);
    expect(await database.select(database.outbox).get(), isEmpty);
    expect(await database.select(database.messageMedia).get(), isEmpty);
    expect(await database.select(database.reactions).get(), isEmpty);
    expect(await database.select(database.stickers).get(), isEmpty);
    expect(await database.select(database.stickerPacks).get(), isEmpty);
    expect(await database.select(database.savedGifs).get(), isEmpty);
    expect(await database.select(database.serviceRequests).get(), isEmpty);
  });
}

class _ControlledChatApi implements ChatApi {
  final sends = StreamController<void Function(int sequence)>();
  var listResponse = Completer<List<ChatConversation>>();
  var messages = <ChatMessage>[];

  @override
  Future<List<ChatConversation>> listConversations() => listResponse.future;

  @override
  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int? beforeSequence,
    int? afterSequence,
    int limit = 50,
  }) async => messages;

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String clientMessageId,
    String type = 'text',
    String? body,
    String? replyToId,
    List<String> attachmentIds = const [],
    ChatPoll? poll,
    Map<String, dynamic>? forwardFrom,
    bool silent = false,
  }) {
    final response = Completer<ChatMessage>();
    sends.add(
      (sequence) => response.complete(
        ChatMessage(
          id: 'confirmed-$sequence',
          conversationId: conversationId,
          clientMessageId: clientMessageId,
          senderId: 'demo-user',
          type: type,
          body: body,
          attachmentIds: attachmentIds,
          sequence: sequence,
          createdAt: DateTime.now(),
          delivery: MessageDelivery.sent,
        ),
      ),
    );
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
