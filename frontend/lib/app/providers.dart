import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/settings_controller.dart';
import 'package:university_messenger/core/config/app_config.dart';
import 'package:university_messenger/core/media/media_client.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/core/network/realtime_client.dart';
import 'package:university_messenger/core/storage/app_database.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/data/api_auth_repository.dart';
import 'package:university_messenger/features/auth/data/demo_auth_repository.dart';
import 'package:university_messenger/features/auth/domain/auth_repository.dart';
import 'package:university_messenger/features/auth/presentation/auth_controller.dart';
import 'package:university_messenger/features/chats/data/chat_api.dart';
import 'package:university_messenger/features/chats/data/local_first_chat_repository.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/features/chats/domain/chat_repository.dart';

final settingsControllerProvider = ChangeNotifierProvider<SettingsController>(
  (ref) => SettingsController(store: SecureAppSettingsStore()),
);

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);

final mediaClientProvider = Provider<MediaClient>(
  (ref) => MediaClient(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.demoMode) return DemoAuthRepository();
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    accountCache: ref.watch(accountCacheProvider),
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final accountCacheProvider = Provider<AccountCache>(
  (ref) => DriftAccountCache(ref.watch(appDatabaseProvider)),
);

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  ref.watch(authControllerProvider.select((auth) => auth.state.account?.id));
  final client = RealtimeClient(ref.watch(tokenStoreProvider));
  ref.onDispose(client.dispose);
  return client;
});

final chatRepositoryProvider = Provider.autoDispose<ChatRepository>((ref) {
  ref.watch(authControllerProvider.select((auth) => auth.state.account?.id));
  final repository = LocalFirstChatRepository(
    database: ref.watch(appDatabaseProvider),
    accountId: () => ref.read(authControllerProvider).state.account?.id,
    api: AppConfig.demoMode ? null : ChatApi(ref.watch(apiClientProvider)),
    realtime: AppConfig.demoMode ? null : ref.watch(realtimeClientProvider),
    demoMode: AppConfig.demoMode,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final chatInitializationProvider = FutureProvider.autoDispose<void>(
  (ref) => ref.watch(chatRepositoryProvider).initialize(),
);

final chatSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final conversationsProvider =
    StreamProvider.autoDispose<List<ChatConversation>>((ref) {
      final query = ref.watch(chatSearchProvider);
      return ref.watch(chatRepositoryProvider).watchConversations(query: query);
    });

final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, conversationId) =>
          ref.watch(chatRepositoryProvider).watchMessages(conversationId),
    );

final typingUsersProvider = StreamProvider.autoDispose
    .family<Set<String>, String>(
      (ref, conversationId) =>
          ref.watch(chatRepositoryProvider).watchTypingUsers(conversationId),
    );
