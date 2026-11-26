import 'package:dio/dio.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';

class ReportsApi {
  const ReportsApi(this._client);

  final ApiClient _client;

  Future<ReportRecord> submitReport({
    required ReportTargetContext target,
    required String reason,
    String? note,
  }) async {
    final response = await _client.post(
      '/reports',
      data: target.toJson(reason: reason, note: note),
    );
    return ReportRecord.fromJson(response.data!);
  }

  Future<List<ReportRecord>> listMyReports() => _getReportList('/reports/mine');

  Future<ConversationReviewState> getReviewState(String conversationId) async {
    final response = await _client.get(
      '/conversations/$conversationId/review-state',
    );
    return ConversationReviewState.fromJson(response.data!);
  }

  Future<List<ReportRecord>> listModerationQueue() =>
      _getReportList('/moderation/reports');

  Future<ReportRecord> claimReport(String reportId) async {
    final response = await _client.post('/moderation/reports/$reportId/claim');
    return ReportRecord.fromJson(response.data!);
  }

  Future<List<ReportEvidenceMessage>> listEvidence(String reportId) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(
        '/moderation/reports/$reportId/messages',
      );
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReportEvidenceMessage.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<ReportRecord> resolveReport({
    required String reportId,
    required ResolutionOutcome outcome,
    String? note,
  }) async {
    if (outcome == ResolutionOutcome.unknown) {
      throw ArgumentError.value(outcome, 'outcome');
    }
    final response = await _client.post(
      '/moderation/reports/$reportId/resolve',
      data: {'outcome': outcome.wireValue, 'note': ?note},
    );
    return ReportRecord.fromJson(response.data!);
  }

  Future<List<ReportRecord>> _getReportList(String path) async {
    try {
      final response = await _client.dio.get<List<dynamic>>(path);
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReportRecord.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  ApiException _apiException(DioException error) {
    final body = error.response?.data;
    if (body is Map && body['error'] is Map) {
      final errorBody = body['error'] as Map;
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
}
