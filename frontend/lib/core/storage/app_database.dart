import 'package:drift/drift.dart';
import 'package:university_messenger/core/storage/database_connection.dart';

part 'app_database.g.dart';

class CachedUsers extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get handle => text().nullable()();
  TextColumn get phone => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  TextColumn get avatarId => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get correctionNote => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get avatarId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get title => text().nullable()();
  BoolColumn get isSavedMessages =>
      boolean().withDefault(const Constant(false))();
  TextColumn get handle => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get ownerId => text()();
  TextColumn get myRole => text().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get lastSequence => integer().withDefault(const Constant(0))();
  IntColumn get lastReadSequence => integer().withDefault(const Constant(0))();
  TextColumn get lastMessageBody => text().nullable()();
  TextColumn get lastMessageType => text().nullable()();
  IntColumn get lastMessageAt => integer().nullable()();
  IntColumn get lastMessageEditedAt => integer().nullable()();
  BoolColumn get isProfessorChannel =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get underReview => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get conversationId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();

  @override
  Set<Column<Object>> get primaryKey => {conversationId, userId};
}

@TableIndex(
  name: 'messages_conversation_sequence',
  columns: {#conversationId, #sequence},
)
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  IntColumn get sequence => integer().nullable()();
  TextColumn get senderId => text()();
  TextColumn get clientMessageId => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get body => text().nullable()();
  TextColumn get status => text()();
  TextColumn get replyToId => text().nullable()();
  TextColumn get entities => text().withDefault(const Constant('[]'))();
  TextColumn get forwardFrom => text().nullable()();
  TextColumn get attachmentIds => text().withDefault(const Constant('[]'))();
  TextColumn get reactionCounts => text().withDefault(const Constant('{}'))();
  TextColumn get poll => text().nullable()();
  BoolColumn get silent => boolean().withDefault(const Constant(false))();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MessageMedia extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get kind => text()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get localPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reactions extends Table {
  TextColumn get messageId => text()();
  TextColumn get userId => text()();
  TextColumn get emoji => text()();

  @override
  Set<Column<Object>> get primaryKey => {messageId, userId, emoji};
}

class Drafts extends Table {
  TextColumn get conversationId => text()();
  TextColumn get body => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {conversationId};
}

class Outbox extends Table {
  TextColumn get clientMessageId => text()();
  TextColumn get conversationId => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {clientMessageId};
}

class StickerPacks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get installed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Stickers extends Table {
  TextColumn get id => text()();
  TextColumn get packId => text()();
  TextColumn get emoji => text().nullable()();
  TextColumn get localPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SavedGifs extends Table {
  TextColumn get id => text()();
  TextColumn get remoteUrl => text()();
  IntColumn get savedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ServiceRequests extends Table {
  TextColumn get id => text()();
  TextColumn get serviceType => text()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SyncCursors extends Table {
  TextColumn get scope => text()();
  IntColumn get sequence => integer()();

  @override
  Set<Column<Object>> get primaryKey => {scope};
}

@DriftDatabase(
  tables: [
    CachedUsers,
    Conversations,
    Members,
    Messages,
    MessageMedia,
    Reactions,
    Drafts,
    Outbox,
    StickerPacks,
    Stickers,
    SavedGifs,
    ServiceRequests,
    AppSettings,
    SyncCursors,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppDatabase());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Phase 1 had no chat UI, so replacing its empty chat tables is safer
        // than carrying an incompatible optimistic-message primary key forward.
        await migrator.deleteTable('outbox');
        await migrator.deleteTable('messages');
        await migrator.deleteTable('conversations');
        await migrator.createTable(conversations);
        await migrator.createTable(messages);
        await migrator.createTable(outbox);
      }
      if (from == 2) {
        await migrator.addColumn(conversations, conversations.description);
        await migrator.addColumn(conversations, conversations.visibility);
        await migrator.addColumn(conversations, conversations.underReview);
        await migrator.addColumn(messages, messages.entities);
        await migrator.addColumn(messages, messages.forwardFrom);
        await migrator.addColumn(messages, messages.attachmentIds);
        await migrator.addColumn(messages, messages.reactionCounts);
        await migrator.addColumn(messages, messages.poll);
        await migrator.addColumn(messages, messages.silent);
      }
      if (from >= 2 && from < 4) {
        await migrator.addColumn(conversations, conversations.avatarId);
      }
      if (from >= 2 && from < 5) {
        await transaction(() async {
          await migrator.addColumn(
            conversations,
            conversations.isSavedMessages,
          );
          await migrator.addColumn(
            conversations,
            conversations.lastMessageType,
          );
          await migrator.addColumn(
            conversations,
            conversations.lastMessageEditedAt,
          );
          await customStatement('''
            UPDATE conversations SET is_saved_messages = 1
            WHERE type = 'dm' AND member_count = 1 AND title = 'Saved messages'
          ''');
          // Pending messages used to overwrite the stored preview. The inbox now
          // shows them separately, so recover the last confirmed preview first.
          await customStatement('''
            UPDATE conversations AS c SET (last_message_body, last_message_at) = (
              SELECT m.body, m.created_at FROM messages AS m
              WHERE m.conversation_id = c.id AND m.sequence = c.last_sequence
            ) WHERE EXISTS (
              SELECT 1 FROM messages AS p WHERE p.conversation_id = c.id
                AND p.sequence IS NULL AND p.client_message_id IS NOT NULL
                AND p.created_at = c.last_message_at
            )
          ''');
          // Older previews mixed message bodies with generated labels. Only use
          // the matching cached message to tell which kind of text was stored.
          await customStatement('''
            UPDATE conversations AS c SET (last_message_type, last_message_edited_at) = (
              SELECT CASE
                WHEN m.deleted_at IS NOT NULL THEN 'deleted'
                WHEN m.edited_at IS NULL AND (
                  (c.id = 'demo-study' AND m.id = 'study-3') OR
                  (c.id = 'demo-professor' AND m.id = 'prof-2')
                ) THEN 'demo:' || m.id
                WHEN m.body IS NULL OR m.body = '' THEN m.type
              END, m.edited_at
              FROM messages AS m
              WHERE m.conversation_id = c.id AND m.created_at = c.last_message_at
                AND m.sequence = c.last_sequence
            ) WHERE c.last_message_at IS NOT NULL
          ''');
          await customStatement('''
            UPDATE conversations AS c SET last_message_body = (
              SELECT m.body FROM messages AS m
              WHERE m.conversation_id = c.id AND m.created_at = c.last_message_at
                AND m.sequence = c.last_sequence
            ) WHERE c.last_message_edited_at IS NOT NULL
                AND c.last_message_type IS NOT 'deleted'
          ''');
          await customStatement('''
            UPDATE conversations SET last_message_type = 'demo:sara-preview'
            WHERE id = 'demo-sara' AND last_sequence = 2
              AND last_message_body = 'See you at the library.'
          ''');
        });
      }
    },
  );
}
