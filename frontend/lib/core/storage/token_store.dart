import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTokens {
  const StoredTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

abstract interface class TokenStore {
  Future<StoredTokens?> read();
  Future<void> write(StoredTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'auth.session';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredTokens?> read() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null) return null;
    final values = jsonDecode(encoded) as Map<String, dynamic>;
    return StoredTokens(
      accessToken: values['access_token'].toString(),
      refreshToken: values['refresh_token'].toString(),
    );
  }

  @override
  Future<void> write(StoredTokens tokens) => _storage.write(
    key: _sessionKey,
    value: jsonEncode({
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
}

class MemoryTokenStore implements TokenStore {
  StoredTokens? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<StoredTokens?> read() async => value;

  @override
  Future<void> write(StoredTokens tokens) async => value = tokens;
}
