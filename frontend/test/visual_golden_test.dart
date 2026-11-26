import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/app/app.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/app/settings_controller.dart';
import 'package:university_messenger/core/storage/app_database.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/data/demo_auth_repository.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/auth/presentation/auth_controller.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';
import 'package:university_messenger/features/chats/data/local_first_chat_repository.dart';

void main() {
  testWidgets('desktop chat core golden', (tester) async {
    await _setViewport(tester, const Size(1280, 720));
    final harness = await _pumpActiveApp(tester);
    expect(find.text('See you at the library.'), findsOneWidget);
    // A real-time demo seed changes bubble widths between e.g. 9:15 and 11:15.
    // Give the screenshot fixed example times while keeping the date label "Today".
    final today = DateTime.now();
    await tester.runAsync(
      () => harness.database.customStatement(
        'UPDATE messages SET created_at = ? + sequence * 60000 WHERE conversation_id = ?',
        [
          DateTime(
            today.year,
            today.month,
            today.day,
            11,
            15,
          ).millisecondsSinceEpoch,
          'demo-study',
        ],
      ),
    );
    await tester.tap(find.text('Study Group · Algorithms'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(UniversityMessengerApp),
      matchesGoldenFile('goldens/chat_desktop.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await harness.chats.dispose();
    await harness.database.close();
  });

  testWidgets('compact chat list golden', (tester) async {
    await _setViewport(tester, const Size(390, 780));
    final harness = await _pumpActiveApp(tester);
    expect(find.text('See you at the library.'), findsOneWidget);
    await expectLater(
      find.byType(UniversityMessengerApp),
      matchesGoldenFile('goldens/chat_compact.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await harness.chats.dispose();
    await harness.database.close();
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<({AppDatabase database, LocalFirstChatRepository chats})> _pumpActiveApp(
  WidgetTester tester,
) async {
  late AuthController auth;
  final tokenStore = MemoryTokenStore();
  await tester.runAsync(() async {
    auth = AuthController(
      repository: DemoAuthRepository(),
      tokenStore: tokenStore,
      accountCache: MemoryAccountCache(),
    );
    await Future<void>.delayed(Duration.zero);
    await auth.requestOtp('+989121234599');
    await auth.verifyOtp('123456');
    auth.stageProfessorProfile(
      const ProfessorProfileDraft(
        firstName: 'Mina',
        lastName: 'Karimi',
        department: 'Physics',
        title: 'Professor',
      ),
    );
    await auth.submitProfessorProfile();
  });
  final database = AppDatabase(NativeDatabase.memory());
  final chats = LocalFirstChatRepository(
    database: database,
    accountId: () => auth.state.account?.id,
    demoMode: true,
  );
  final settings = SettingsController(
    store: MemoryAppSettingsStore({SettingsController.localeKey: 'en'}),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsControllerProvider.overrideWith((ref) => settings),
        tokenStoreProvider.overrideWithValue(tokenStore),
        callBootstrapProvider.overrideWithValue(false),
        authControllerProvider.overrideWith((ref) => auth),
        appDatabaseProvider.overrideWithValue(database),
        chatRepositoryProvider.overrideWithValue(chats),
      ],
      child: const UniversityMessengerApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return (database: database, chats: chats);
}
