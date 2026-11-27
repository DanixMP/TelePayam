import 'package:dio/dio.dart';
import 'package:university_messenger/core/config/app_config.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/core/storage/token_store.dart';

class ApiClient {
  ApiClient({required TokenStore tokenStore, Dio? dio})
    : _tokenStore = tokenStore,
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isPublicAuthPath(options.path)) {
            final tokens = await _tokenStore.read();
            if (tokens != null) {
              options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['retried_after_refresh'] == true ||
              _isPublicAuthPath(request.path)) {
            handler.next(error);
            return;
          }
          try {
            final accessToken = await _refreshAccessToken();
            if (accessToken == null) {
              handler.next(error);
              return;
            }
            request.extra['retried_after_refresh'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';
            handler.resolve(await this.dio.fetch<dynamic>(request));
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  final Dio dio;
  final TokenStore _tokenStore;
  Future<String?>? _refreshing;

  Future<Response<Map<String, dynamic>>> get(
    String path, {
    String? accessToken,
  }) => _guard(
    () => dio.get<Map<String, dynamic>>(path, options: _options(accessToken)),
  );

  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
    String? accessToken,
  }) => _guard(
    () => dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: _options(accessToken),
    ),
  );

  Future<Response<List<dynamic>>> getList(String path) =>
      _guard(() => dio.get<List<dynamic>>(path));

  Future<void> postWithoutBody(
    String path, {
    Map<String, dynamic>? data,
    String? accessToken,
  }) async {
    await _guard<Object?>(
      () => dio.post<Object?>(path, data: data, options: _options(accessToken)),
    );
  }

  Options? _options(String? token) => token == null
      ? null
      : Options(headers: {'Authorization': 'Bearer $token'});

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  bool _isPublicAuthPath(String path) =>
      path.contains('/auth/otp/') || path.endsWith('/auth/refresh');

  Future<String?> _refreshAccessToken() {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) return activeRefresh;
    final refresh = _performRefresh();
    _refreshing = refresh;
    return refresh.whenComplete(() => _refreshing = null);
  }

  Future<String?> _performRefresh() async {
    final tokens = await _tokenStore.read();
    if (tokens == null) return null;
    try {
      final response = await Dio(dio.options).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );
      final data = response.data!;
      final replacement = StoredTokens(
        accessToken: data['access_token'].toString(),
        refreshToken: data['refresh_token'].toString(),
      );
      await _tokenStore.write(replacement);
      return replacement.accessToken;
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map && body['error'] is Map
          ? (body['error'] as Map)['code']?.toString()
          : null;
      if (code == 'invalid_refresh_token' ||
          code == 'refresh_expired' ||
          code == 'refresh_reuse_detected') {
        await _tokenStore.clear();
      }
      rethrow;
    }
  }
}
