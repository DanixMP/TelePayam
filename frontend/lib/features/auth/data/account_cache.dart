import 'package:drift/drift.dart';
import 'package:university_messenger/core/storage/app_database.dart';
import 'package:university_messenger/features/auth/domain/account.dart';

abstract interface class AccountCache {
  Future<Account?> read();
  Future<void> write(Account account);
  Future<void> clear();
  Future<void> clearSessionData();
}

class DriftAccountCache implements AccountCache {
  DriftAccountCache(this._database);

  final AppDatabase _database;

  @override
  Future<Account?> read() async {
    final value = await _database
        .select(_database.cachedUsers)
        .getSingleOrNull();
    if (value == null) return null;
    return Account(
      id: value.id,
      phone: value.phone,
      role: UserRole.fromJson(value.role),
      status: AccountStatus.fromJson(value.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(value.updatedAt),
      firstName: value.firstName,
      lastName: value.lastName,
      handle: value.handle,
      avatarId: value.avatarId,
      bio: value.bio,
      correctionNote: value.correctionNote,
    );
  }

  @override
  Future<void> write(Account account) => _database
      .into(_database.cachedUsers)
      .insertOnConflictUpdate(
        CachedUsersCompanion.insert(
          id: account.id,
          phone: account.phone,
          role: account.role.wireValue,
          status: account.status.wireValue,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          firstName: Value(account.firstName),
          lastName: Value(account.lastName),
          handle: Value(account.handle),
          avatarId: Value(account.avatarId),
          bio: Value(account.bio),
          correctionNote: Value(account.correctionNote),
        ),
      );

  @override
  Future<void> clear() => _database.delete(_database.cachedUsers).go();

  @override
  Future<void> clearSessionData() => _database.transaction(() async {
    await _database.delete(_database.outbox).go();
    await _database.delete(_database.reactions).go();
    await _database.delete(_database.messageMedia).go();
    await _database.delete(_database.messages).go();
    await _database.delete(_database.members).go();
    await _database.delete(_database.conversations).go();
    await _database.delete(_database.drafts).go();
    await _database.delete(_database.stickers).go();
    await _database.delete(_database.stickerPacks).go();
    await _database.delete(_database.savedGifs).go();
    await _database.delete(_database.serviceRequests).go();
    await _database.delete(_database.syncCursors).go();
    await _database.delete(_database.cachedUsers).go();
  });
}

class MemoryAccountCache implements AccountCache {
  Account? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<void> clearSessionData() async => value = null;

  @override
  Future<Account?> read() async => value;

  @override
  Future<void> write(Account account) async => value = account;
}
