import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/data/demo_auth_repository.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/auth/presentation/auth_controller.dart';

void main() {
  test('student moves from OTP through approval to active', () async {
    final controller = AuthController(
      repository: DemoAuthRepository(),
      tokenStore: MemoryTokenStore(),
      accountCache: MemoryAccountCache(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.stage, AuthFlowStage.signedOut);

    expect(await controller.requestOtp('+989121234567'), isTrue);
    expect(controller.state.stage, AuthFlowStage.codeRequested);
    expect(await controller.verifyOtp('123456'), isTrue);
    expect(controller.state.account?.role, UserRole.student);
    expect(controller.state.account?.status, AccountStatus.pendingProfile);

    controller.stageStudentProfile(
      const StudentProfileDraft(
        firstName: 'Sara',
        lastName: 'Ahmadi',
        nationalId: '1234567891',
        degree: 'BSc',
        department: 'Engineering',
        universityId: '40110001',
      ),
    );
    expect(await controller.submitStudentProfile(), isTrue);
    expect(controller.state.account?.status, AccountStatus.pendingApproval);

    await controller.refreshStatus();
    expect(controller.state.account?.status, AccountStatus.pendingApproval);
    await controller.refreshStatus();
    expect(controller.state.account?.status, AccountStatus.active);
  });

  test(
    'professor invite activates immediately after profile completion',
    () async {
      final controller = AuthController(
        repository: DemoAuthRepository(),
        tokenStore: MemoryTokenStore(),
        accountCache: MemoryAccountCache(),
      );
      await Future<void>.delayed(Duration.zero);
      await controller.requestOtp('+989121234599');
      await controller.verifyOtp('123456');
      expect(controller.state.account?.role, UserRole.professor);

      controller.stageProfessorProfile(
        const ProfessorProfileDraft(
          firstName: 'Mina',
          lastName: 'Karimi',
          department: 'Physics',
          title: 'Professor',
        ),
      );
      expect(await controller.submitProfessorProfile(), isTrue);
      expect(controller.state.account?.status, AccountStatus.active);
    },
  );

  test('successful OTP is accepted when the optional account cache fails', () async {
    final tokens = MemoryTokenStore();
    final controller = AuthController(
      repository: DemoAuthRepository(),
      tokenStore: tokens,
      accountCache: _FailingAccountCache(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(await controller.requestOtp('+989121234567'), isTrue);
    expect(await controller.verifyOtp('123456'), isTrue);
    expect(controller.state.stage, AuthFlowStage.authenticated);
    expect(controller.state.errorCode, isNull);
    expect(controller.state.account?.status, AccountStatus.pendingProfile);
    expect(await tokens.read(), isNotNull);
  });
}

class _FailingAccountCache implements AccountCache {
  @override
  Future<void> clear() async {}

  @override
  Future<void> clearSessionData() async {}

  @override
  Future<Account?> read() async => null;

  @override
  Future<void> write(Account account) => throw StateError('cache unavailable');
}
