import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/app/app.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/app/settings_controller.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/data/demo_auth_repository.dart';

void main() {
  testWidgets('shows the localized welcome flow', (tester) async {
    final settings = SettingsController(
      store: MemoryAppSettingsStore({SettingsController.localeKey: 'en'}),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => settings),
          authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
          tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
          accountCacheProvider.overrideWithValue(MemoryAccountCache()),
        ],
        child: const UniversityMessengerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('University Messenger'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
