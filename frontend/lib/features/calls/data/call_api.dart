import 'package:dio/dio.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';

abstract interface class CallGateway {
  Future<CallSession> createCall({
    required String conversationId,
    required String clientCallId,
    required CallKind kind,
  });

  Future<List<CallSession>> history({int limit = 50});
  Future<CallSession> getCall(String callId);
  Future<CallSession> accept(String callId);
  Future<CallSession> decline(String callId);
  Future<CallSession> end(String callId);
  Future<CallJoinToken> tokenFor(String callId);
}

class CallApi implements CallGateway {
  CallApi(this._client);

  final ApiClient _client;

  @override
  Future<CallSession> createCall({
    required String conversationId,
    required String clientCallId,
    required CallKind kind,
  }) async {
    final response = await _client.post(
      '/calls',
      data: {
        'conversation_id': conversationId,
        'client_call_id': clientCallId,
        'kind': kind.name,
      },
    );
    return CallSession.fromJson(response.data!);
  }

  @override
  Future<List<CallSession>> history({int limit = 50}) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/calls',
        queryParameters: {'limit': limit.clamp(1, 100)},
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CallSession.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  @override
  Future<CallSession> getCall(String callId) async {
    final response = await _client.get('/calls/$callId');
    return CallSession.fromJson(response.data!);
  }

  @override
  Future<CallSession> accept(String callId) =>
      _transition('/calls/$callId/accept');

  @override
  Future<CallSession> decline(String callId) =>
      _transition('/calls/$callId/decline');

  @override
  Future<CallSession> end(String callId) => _transition('/calls/$callId/end');

  @override
  Future<CallJoinToken> tokenFor(String callId) async {
    final response = await _client.post(
      '/calls/token',
      data: {'call_session_id': callId},
    );
    return CallJoinToken.fromJson(response.data!);
  }

  Future<CallSession> _transition(String path) async {
    final response = await _client.post(path);
    return CallSession.fromJson(response.data!);
  }
}

ApiException _apiException(DioException error) {
  final body = error.response?.data;
  final errorBody = body is Map ? body['error'] : null;
  if (errorBody is Map) {
    return ApiException(
      errorBody['code']?.toString() ?? 'request_failed',
      errorBody['detail']?.toString() ?? 'Request failed',
      statusCode: error.response?.statusCode,
    );
  }
  return ApiException(
    'network_error',
    error.message ?? 'Network request failed',
    statusCode: error.response?.statusCode,
  );
}
