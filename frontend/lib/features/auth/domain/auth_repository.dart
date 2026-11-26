import 'package:university_messenger/features/auth/domain/account.dart';

abstract interface class AuthRepository {
  Future<OtpChallenge> requestOtp(String phone);

  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    required String platform,
    String? deviceName,
  });

  Future<AuthSession> refresh(String refreshToken);
  Future<Account> getMe(String accessToken);
  Future<Account> submitStudentProfile(
    String accessToken,
    StudentProfileDraft draft,
  );
  Future<Account> submitProfessorProfile(
    String accessToken,
    ProfessorProfileDraft draft,
  );
  Future<void> logout(String accessToken, String refreshToken);
}
