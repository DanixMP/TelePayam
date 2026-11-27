import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/app/app.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/app/settings_controller.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/data/demo_auth_repository.dart';

void main() {
  testWidgets('welcome settings apply and restore language and appearance', (
    tester,
  ) async {
    final store = MemoryAppSettingsStore({SettingsController.localeKey: 'en'});
    Future<void> openApp() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsControllerProvider.overrideWith(
              (_) => SettingsController(store: store),
            ),
            authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
            tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
            accountCacheProvider.overrideWithValue(MemoryAccountCache()),
          ],
          child: const UniversityMessengerApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openApp();
    expect(find.text('University Messenger'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Persian'));
    await tester.pumpAndSettle();
    expect(find.text('ظاهر'), findsOneWidget);
    await tester.tap(find.text('تیره'));
    await tester.pumpAndSettle();
    final appearance = tester.element(find.text('ظاهر'));
    expect(Directionality.of(appearance), TextDirection.rtl);
    expect(Theme.of(appearance).brightness, Brightness.dark);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('پیام‌رسان دانشگاه'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await openApp();
    final title = tester.element(find.text('پیام‌رسان دانشگاه'));
    expect(Directionality.of(title), TextDirection.rtl);
    expect(Theme.of(title).brightness, Brightness.dark);
  });
}
