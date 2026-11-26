import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/core/storage/token_store.dart';
import 'package:university_messenger/features/auth/data/account_cache.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/auth/domain/auth_repository.dart';

enum AuthFlowStage { booting, signedOut, codeRequested, authenticated }

class AuthState {
  const AuthState({
    this.stage = AuthFlowStage.booting,
    this.isBusy = false,
    this.phone,
    this.retryAfter = 0,
    this.developmentCode,
    this.account,
    this.errorCode,
    this.studentDraft,
    this.professorDraft,
    this.lastChecked,
  });

  final AuthFlowStage stage;
  final bool isBusy;
  final String? phone;
  final int retryAfter;
  final String? developmentCode;
  final Account? account;
  final String? errorCode;
  final StudentProfileDraft? studentDraft;
  final ProfessorProfileDraft? professorDraft;
  final DateTime? lastChecked;

  AuthState copyWith({
    AuthFlowStage? stage,
    bool? isBusy,
    String? phone,
    int? retryAfter,
    String? developmentCode,
    bool clearDevelopmentCode = false,
    Account? account,
    bool clearAccount = false,
    String? errorCode,
    bool clearError = false,
    StudentProfileDraft? studentDraft,
    bool clearStudentDraft = false,
    ProfessorProfileDraft? professorDraft,
    bool clearProfessorDraft = false,
    DateTime? lastChecked,
  }) => AuthState(
    stage: stage ?? this.stage,
    isBusy: isBusy ?? this.isBusy,
    phone: phone ?? this.phone,
    retryAfter: retryAfter ?? this.retryAfter,
    developmentCode: clearDevelopmentCode
        ? null
        : developmentCode ?? this.developmentCode,
    account: clearAccount ? null : account ?? this.account,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    studentDraft: clearStudentDraft ? null : studentDraft ?? this.studentDraft,
    professorDraft: clearProfessorDraft
        ? null
        : professorDraft ?? this.professorDraft,
    lastChecked: lastChecked ?? this.lastChecked,
  );
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required TokenStore tokenStore,
    required AccountCache accountCache,
  }) : _repository = repository,
       _tokenStore = tokenStore,
       _accountCache = accountCache {
    unawaited(_bootstrap());
  }

  final AuthRepository _repository;
  final TokenStore _tokenStore;
  final AccountCache _accountCache;
  StoredTokens? _tokens;
  AuthState _state = const AuthState();

  AuthState get state => _state;

  void _setState(AuthState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    _setState(_state.copyWith(stage: AuthFlowStage.booting, clearError: true));
    try {
      _tokens = await _tokenStore.read();
      if (_tokens == null) {
        _setState(const AuthState(stage: AuthFlowStage.signedOut));
        return;
      }
      try {
        final account = await _repository.getMe(_tokens!.accessToken);
        await _cacheAccount(account);
        _setState(
          AuthState(stage: AuthFlowStage.authenticated, account: account),
        );
      } on ApiException catch (error) {
        if (error.code == 'network_error') {
          final cachedAccount = await _accountCache.read();
          _setState(
            cachedAccount == null
                ? const AuthState(
                    stage: AuthFlowStage.booting,
                    errorCode: 'network_error',
                  )
                : AuthState(
                    stage: AuthFlowStage.authenticated,
                    account: cachedAccount,
                    errorCode: 'network_error',
                  ),
          );
          return;
        }
        if (error.statusCode != 401 && error.code != 'invalid_access_token') {
          rethrow;
        }
        final session = await _repository.refresh(_tokens!.refreshToken);
        await _acceptSession(session);
      }
    } on ApiException catch (error) {
      if (error.code == 'network_error') {
        _setState(
          const AuthState(
            stage: AuthFlowStage.booting,
            errorCode: 'network_error',
          ),
        );
        return;
      }
      await _tokenStore.clear();
      await _accountCache.clear();
      _tokens = null;
      _setState(
        const AuthState(
          stage: AuthFlowStage.signedOut,
          errorCode: 'session_expired',
        ),
      );
    } catch (_) {
      _setState(
        const AuthState(
          stage: AuthFlowStage.booting,
          errorCode: 'network_error',
        ),
      );
    }
  }

  Future<void> retryBootstrap() => _bootstrap();

  Future<bool> requestOtp(String phone) async {
    _setState(_state.copyWith(isBusy: true, clearError: true));
    try {
      final challenge = await _repository.requestOtp(phone);
      _setState(
        _state.copyWith(
          stage: AuthFlowStage.codeRequested,
          isBusy: false,
          phone: phone,
          retryAfter: challenge.retryAfter,
          developmentCode: challenge.developmentCode,
          clearError: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      _setState(_state.copyWith(isBusy: false, errorCode: error.code));
      return false;
    } catch (_) {
      _setState(_state.copyWith(isBusy: false, errorCode: 'network_error'));
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final phone = _state.phone;
    if (phone == null) return false;
    _setState(_state.copyWith(isBusy: true, clearError: true));
    try {
      final session = await _repository.verifyOtp(
        phone: phone,
        code: code,
        platform: defaultTargetPlatform.name,
        deviceName: defaultTargetPlatform.name,
      );
      await _acceptSession(session);
      return true;
    } on ApiException catch (error) {
      _setState(_state.copyWith(isBusy: false, errorCode: error.code));
      return false;
    } catch (_) {
      _setState(_state.copyWith(isBusy: false, errorCode: 'network_error'));
      return false;
    }
  }

  Future<void> _acceptSession(AuthSession session) async {
    _tokens = StoredTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _tokenStore.write(_tokens!);
    await _cacheAccount(session.account);
    _setState(
      _state.copyWith(
        stage: AuthFlowStage.authenticated,
        isBusy: false,
        account: session.account,
        clearError: true,
      ),
    );
  }

  void stageStudentProfile(StudentProfileDraft draft) {
    _setState(_state.copyWith(studentDraft: draft, clearError: true));
  }

  void stageProfessorProfile(ProfessorProfileDraft draft) {
    _setState(_state.copyWith(professorDraft: draft, clearError: true));
  }

  Future<bool> submitStudentProfile() => _submitProfile(
    () => _repository.submitStudentProfile(
      _tokens!.accessToken,
      _state.studentDraft!,
    ),
  );

  Future<bool> submitProfessorProfile() => _submitProfile(
    () => _repository.submitProfessorProfile(
      _tokens!.accessToken,
      _state.professorDraft!,
    ),
  );

  Future<bool> _submitProfile(Future<Account> Function() request) async {
    _setState(_state.copyWith(isBusy: true, clearError: true));
    try {
      final account = await request();
      await _cacheAccount(account);
      _setState(
        _state.copyWith(
          account: account,
          isBusy: false,
          clearStudentDraft: true,
          clearProfessorDraft: true,
          clearError: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      _setState(_state.copyWith(isBusy: false, errorCode: error.code));
      return false;
    } catch (_) {
      _setState(_state.copyWith(isBusy: false, errorCode: 'network_error'));
      return false;
    }
  }

  Future<bool> refreshStatus() async {
    if (_tokens == null) return false;
    _setState(_state.copyWith(isBusy: true, clearError: true));
    try {
      final account = await _repository.getMe(_tokens!.accessToken);
      await _cacheAccount(account);
      _setState(
        _state.copyWith(
          account: account,
          isBusy: false,
          lastChecked: DateTime.now(),
          clearError: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      _setState(_state.copyWith(isBusy: false, errorCode: error.code));
      return false;
    } catch (_) {
      _setState(_state.copyWith(isBusy: false, errorCode: 'network_error'));
      return false;
    }
  }

  Future<void> _cacheAccount(Account account) async {
    try {
      await _accountCache.write(account);
    } catch (error, stackTrace) {
      // The cache enables offline startup, but it must never invalidate a
      // session that the server has already authenticated successfully.
      debugPrint('Account cache write failed: $error\n$stackTrace');
    }
  }

  void restartPhoneEntry() {
    _setState(const AuthState(stage: AuthFlowStage.signedOut));
  }

  void clearError() => _setState(_state.copyWith(clearError: true));

  Future<void> logout() async {
    final tokens = _tokens;
    _setState(_state.copyWith(isBusy: true, clearError: true));
    if (tokens != null) {
      try {
        await _repository.logout(tokens.accessToken, tokens.refreshToken);
      } catch (_) {
        // Local logout must still complete when the session is already invalid.
      }
    }
    await _tokenStore.clear();
    await _accountCache.clearSessionData();
    _tokens = null;
    _setState(const AuthState(stage: AuthFlowStage.signedOut));
  }
}
