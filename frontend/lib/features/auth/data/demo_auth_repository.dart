import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/auth/domain/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  Account? _account;
  var _statusChecks = 0;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 550));

  @override
  Future<OtpChallenge> requestOtp(String phone) async {
    await _wait();
    return const OtpChallenge(retryAfter: 30, developmentCode: '123456');
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    required String platform,
    String? deviceName,
  }) async {
    await _wait();
    if (code != '123456') {
      throw const ApiException('otp_invalid', 'Incorrect demo code');
    }
    final role = phone.endsWith('99') ? UserRole.professor : UserRole.student;
    _account = Account(
      id: 'demo-user',
      phone: phone,
      role: role,
      status: AccountStatus.pendingProfile,
      createdAt: DateTime.now(),
    );
    return AuthSession(
      accessToken: 'demo-access',
      refreshToken: 'demo-refresh',
      expiresIn: 900,
      account: _account!,
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    await _wait();
    if (_account == null && refreshToken.startsWith('demo-refresh')) {
      _restoreActiveAccount();
    }
    if (_account == null) {
      throw const ApiException('invalid_refresh_token', 'Session not found');
    }
    return AuthSession(
      accessToken: 'demo-access-refreshed',
      refreshToken: 'demo-refresh-refreshed',
      expiresIn: 900,
      account: _account!,
    );
  }

  @override
  Future<Account> getMe(String accessToken) async {
    await _wait();
    if (_account == null && accessToken.startsWith('demo-access')) {
      _restoreActiveAccount();
    }
    final account = _account;
    if (account == null) {
      throw const ApiException('invalid_access_token', 'Session not found');
    }
    if (account.status == AccountStatus.pendingApproval &&
        ++_statusChecks >= 2) {
      _account = account.copyWith(status: AccountStatus.active);
    }
    return _account!;
  }

  @override
  Future<Account> submitStudentProfile(
    String accessToken,
    StudentProfileDraft draft,
  ) async {
    await _wait();
    _account = _account!.copyWith(
      firstName: draft.firstName,
      lastName: draft.lastName,
      status: AccountStatus.pendingApproval,
    );
    return _account!;
  }

  @override
  Future<Account> submitProfessorProfile(
    String accessToken,
    ProfessorProfileDraft draft,
  ) async {
    await _wait();
    _account = _account!.copyWith(
      firstName: draft.firstName,
      lastName: draft.lastName,
      status: AccountStatus.active,
    );
    return _account!;
  }

  @override
  Future<void> logout(String accessToken, String refreshToken) async {
    await _wait();
    _account = null;
    _statusChecks = 0;
  }

  void _restoreActiveAccount() {
    _account = Account(
      id: 'demo-user',
      phone: '+989121234567',
      role: UserRole.student,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
      firstName: 'Mehdi',
      lastName: 'Pourafsar',
    );
  }
}
