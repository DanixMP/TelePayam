import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.code, this.detail, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final body = error.response?.data;
    final envelope = body is Map ? body['error'] : null;
    final status = error.response?.statusCode;
    return ApiException(
      envelope is Map
          ? envelope['code']?.toString() ?? 'request_failed'
          : switch (status) {
              null => 'network_error',
              401 => 'session_expired',
              403 => 'forbidden',
              422 => 'validation_error',
              _ => 'request_failed',
            },
      (envelope is Map ? envelope['detail']?.toString() : null) ??
          error.message ??
          'Request failed',
      statusCode: status,
    );
  }

  final String code;
  final String detail;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code, $detail)';
}
