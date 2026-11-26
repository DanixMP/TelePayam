import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/core/storage/app_database.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/chats/data/local_first_chat_repository.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';

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

  test('optimistic text message is reconciled and leaves the outbox', () async {
    await repository.sendText('demo-study', 'A new local-first message');

    final messages = await repository.watchMessages('demo-study').first;
    expect(messages.last.body, 'A new local-first message');
    expect(messages.last.delivery, MessageDelivery.sent);
    expect(await database.select(database.outbox).get(), isEmpty);
  });

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
