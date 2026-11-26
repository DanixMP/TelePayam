import 'package:dio/dio.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';

class ServicesApi {
  const ServicesApi(this._client);

  final ApiClient _client;

  Future<List<ServiceType>> catalog() => _guard(() async {
    final response = await _client.dio.get<List<dynamic>>('/services/catalog');
    return _models(response.data, ServiceType.fromJson);
  });

  Future<List<ServiceRequest>> requests() => _guard(() async {
    final response = await _client.dio.get<List<dynamic>>('/services/requests');
    return _models(response.data, ServiceRequest.fromJson);
  });

  Future<ServiceRequest> createRequest({
    required String serviceTypeId,
    required Map<String, dynamic> data,
    required Map<String, String> documents,
  }) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/services/requests',
      data: {
        'service_type_id': serviceTypeId,
        'data': data,
        'documents': documents,
      },
    );
    return ServiceRequest.fromJson(response.data!);
  });

  Future<ServiceRequestDetail> requestDetail(String requestId) =>
      _guard(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(
          '/services/requests/$requestId',
        );
        return ServiceRequestDetail.fromJson(response.data!);
      });

  Future<ServiceRequest> claim(String requestId) => _requestAction(
    '/services/requests/$requestId/claim',
    ServiceRequest.fromJson,
  );

  Future<ServiceRequest> cancel(String requestId) => _requestAction(
    '/services/requests/$requestId/cancel',
    ServiceRequest.fromJson,
  );

  Future<ServiceRequest> changeStatus(
    String requestId,
    ServiceRequestStatus status, {
    String? note,
  }) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/services/requests/$requestId/status',
      data: {'status': status.wireValue, 'note': note},
    );
    return ServiceRequest.fromJson(response.data!);
  });

  Future<ServiceRequestDocument> associateResult(
    String requestId,
    String mediaId,
  ) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/services/requests/$requestId/result',
      data: {'media_id': mediaId},
    );
    return ServiceRequestDocument.fromJson(response.data!);
  });

  Future<List<TicketMessage>> messages(String requestId) => _guard(() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/services/requests/$requestId/messages',
    );
    return _models(response.data, TicketMessage.fromJson);
  });

  Future<TicketMessage> sendMessage(
    String requestId, {
    required String body,
    String? attachmentId,
  }) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/services/requests/$requestId/messages',
      data: {'body': body, 'attachment_id': attachmentId},
    );
    return TicketMessage.fromJson(response.data!);
  });

  Future<T> _requestAction<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(path);
    return parse(response.data!);
  });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map && body['error'] is Map) {
        final errorBody = body['error'] as Map;
        throw ApiException(
          errorBody['code']?.toString() ?? 'request_failed',
          errorBody['detail']?.toString() ?? 'Request failed',
          statusCode: error.response?.statusCode,
        );
      }
      throw ApiException(
        'network_error',
        error.message ?? 'Network request failed',
        statusCode: error.response?.statusCode,
      );
    }
  }
}

List<T> _models<T>(
  List<dynamic>? values,
  T Function(Map<String, dynamic>) parse,
) => (values ?? const [])
    .whereType<Map>()
    .map((value) => parse(value.cast<String, dynamic>()))
    .toList();
