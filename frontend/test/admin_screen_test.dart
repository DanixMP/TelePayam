import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/app/app.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/app/router.dart';
import 'package:university_messenger/app/settings_controller.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/admin/admin_api.dart';
import 'package:university_messenger/features/admin/admin_screen.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/data/demo_auth_repository.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';

class _Identity extends DemoAuthRepository {
  _Identity(this.role);
  final String role;

  @override
  Future<Account> getMe(String accessToken) async => Account.fromJson({
    'id': 'signed-in-account',
    'phone': '+989000000001',
    'role': role,
    'status': 'active',
  });
}

class _Queue implements AdminApi {
  final requests = [
    StudentRequest.fromJson({
      'id': 'registration',
      'first_name': 'Sara',
      'last_name': 'Ahmadi',
      'department': 'Engineering',
      'degree': 'MSc',
      'university_id': '40310001',
      'national_id_masked': '******5948',
    }),
  ];
  String? grantedPhone;
  int loads = 0;
  @override
  Future<List<StudentRequest>> pending() async {
    loads++;
    return List.of(requests);
  }

  @override
  Future<void> approve(String id) async =>
      requests.removeWhere((item) => item.id == id);
  @override
  Future<void> createAdmin(String phone) async {
    grantedPhone = phone;
  }
}

Future<_Queue> _openApp(WidgetTester tester, String role) async {
  final api = _Queue();
  final tokens = MemoryTokenStore()
    ..value = const StoredTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsControllerProvider.overrideWith(
          (_) => SettingsController(
            store: MemoryAppSettingsStore({SettingsController.localeKey: 'en'}),
          ),
        ),
        tokenStoreProvider.overrideWithValue(tokens),
        accountCacheProvider.overrideWithValue(MemoryAccountCache()),
        authRepositoryProvider.overrideWithValue(_Identity(role)),
        adminApiProvider.overrideWithValue(api),
        callBootstrapProvider.overrideWithValue(false),
        chatInitializationProvider.overrideWith((_) async {}),
        conversationsProvider.overrideWith((_) => Stream.value([])),
      ],
      child: const UniversityMessengerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets(
    'ordinary admin lands on review and can approve, but cannot add admins',
    (tester) async {
      await _openApp(tester, 'admin');
      expect(find.text('Admin panel'), findsOneWidget);
      expect(find.text('Add admin'), findsNothing);
      expect(find.textContaining('******5948'), findsOneWidget);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(find.text('No registrations awaiting review.'), findsOneWidget);
      await tester.tap(find.byTooltip('Chats'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin panel'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminScreen), findsOneWidget);
    },
  );

  testWidgets('super admin can provision a normalized phone', (tester) async {
    final api = await _openApp(tester, 'super_admin');
    expect(find.text('Super admin panel'), findsOneWidget);
    await tester.tap(find.text('Add admin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '09900000002');
    await tester.tap(find.text('Create admin'));
    await tester.pumpAndSettle();
    expect(api.grantedPhone, '+989900000002');
    expect(
      find.text('Admin added. They can now sign in with their SMS code.'),
      findsOneWidget,
    );
  });

  testWidgets('student deep link does not open or fetch the admin queue', (
    tester,
  ) async {
    final api = await _openApp(tester, 'student');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UniversityMessengerApp)),
    );
    container.read(routerProvider).go(AdminScreen.path);
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.byType(AdminScreen), findsNothing);
    expect(api.loads, 0);
  });
}
