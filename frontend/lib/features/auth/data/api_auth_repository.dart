import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/auth/domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<OtpChallenge> requestOtp(String phone) async {
    final response = await _client.post(
      '/auth/otp/request',
      data: {'phone': phone},
    );
    final data = response.data!;
    return OtpChallenge(
      retryAfter: (data['retry_after'] as num?)?.toInt() ?? 120,
      developmentCode: data['development_code']?.toString(),
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    required String platform,
    String? deviceName,
  }) async {
    final response = await _client.post(
      '/auth/otp/verify',
      data: {
        'phone': phone,
        'code': code,
        'platform': platform,
        'device_name': ?deviceName,
      },
    );
    return AuthSession.fromJson(response.data!);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _client.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthSession.fromJson(response.data!);
  }

  @override
  Future<Account> getMe(String accessToken) async {
    final response = await _client.get('/users/me', accessToken: accessToken);
    return Account.fromJson(response.data!);
  }

  @override
  Future<Account> submitStudentProfile(
    String accessToken,
    StudentProfileDraft draft,
  ) async {
    final response = await _client.post(
      '/users/me/student-profile',
      data: draft.toJson(),
      accessToken: accessToken,
    );
    return Account.fromJson(response.data!);
  }

  @override
  Future<Account> submitProfessorProfile(
    String accessToken,
    ProfessorProfileDraft draft,
  ) async {
    final response = await _client.post(
      '/users/me/professor-profile',
      data: draft.toJson(),
      accessToken: accessToken,
    );
    return Account.fromJson(response.data!);
  }

  @override
  Future<void> logout(String accessToken, String refreshToken) =>
      _client.postWithoutBody(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
        accessToken: accessToken,
      );
}
