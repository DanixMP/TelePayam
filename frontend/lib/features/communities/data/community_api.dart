import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';

final communityApiProvider = Provider<CommunityApi>(
  (ref) => CommunityApi(ref.watch(apiClientProvider)),
);

class CommunityRequestException implements Exception {
  const CommunityRequestException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class CommunityApi {
  const CommunityApi(this._client);

  final ApiClient _client;

  Future<List<CommunityConversation>> discover({
    bool professorChannels = false,
    String? query,
  }) => _guard(() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/conversations/discover',
      queryParameters: {
        'professor_channels': professorChannels,
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );
    return (response.data ?? const <dynamic>[])
        .map(
          (item) => CommunityConversation.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  });

  Future<CommunityConversation> getConversation(String conversationId) =>
      _guard(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(
          '/conversations/$conversationId',
        );
        return CommunityConversation.fromJson(response.data!);
      });

  Future<CommunityConversation> createGroup({
    required String title,
    required String? description,
    required CommunityVisibility visibility,
    required String? handle,
    List<String> memberIds = const [],
  }) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/conversations/groups',
      data: {
        'title': title.trim(),
        'description': _nullableText(description),
        'visibility': visibility.name,
        'handle': _nullableText(handle),
        'member_ids': memberIds,
      },
    );
    return CommunityConversation.fromJson(response.data!);
  });

  Future<CommunityConversation> createChannel({
    required String title,
    required String? description,
    required CommunityVisibility visibility,
    required String? handle,
  }) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/conversations/channels',
      data: {
        'title': title.trim(),
        'description': _nullableText(description),
        'visibility': visibility.name,
        'handle': _nullableText(handle),
      },
    );
    return CommunityConversation.fromJson(response.data!);
  });

  Future<CommunityConversation> join(String conversationId) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/conversations/$conversationId/join',
    );
    return CommunityConversation.fromJson(response.data!);
  });

  Future<CommunityConversation> joinInvite(String token) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/conversations/join/${Uri.encodeComponent(token.trim())}',
    );
    return CommunityConversation.fromJson(response.data!);
  });

  Future<CommunityConversation> updateMetadata({
    required String conversationId,
    required String title,
    required String? description,
    required CommunityVisibility visibility,
    required String? handle,
  }) => _guard(() async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/conversations/$conversationId',
      data: {
        'title': title.trim(),
        'description': _nullableText(description),
        'visibility': visibility.name,
        'handle': _nullableText(handle),
      },
    );
    return CommunityConversation.fromJson(response.data!);
  });

  Future<CommunityConversation> updateSettings({
    required String conversationId,
    required int slowModeSeconds,
    required bool membersCanPost,
    required bool membersCanInvite,
    required bool commentsEnabled,
  }) => _guard(() async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/conversations/$conversationId/settings',
      data: {
        'slow_mode_seconds': slowModeSeconds,
        'members_can_post': membersCanPost,
        'members_can_invite': membersCanInvite,
        'comments_enabled': commentsEnabled,
      },
    );
    return CommunityConversation.fromJson(response.data!);
  });

  Future<List<CommunityMember>> listMembers(
    String conversationId,
  ) => _guard(() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/conversations/$conversationId/members',
    );
    return (response.data ?? const <dynamic>[])
        .map(
          (item) =>
              CommunityMember.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  });

  Future<void> updateMember({
    required String conversationId,
    required String memberId,
    required CommunityMemberRole role,
  }) => _guard(() async {
    await _client.dio.patch<void>(
      '/conversations/$conversationId/members/$memberId',
      data: {'role': role.name},
    );
  });

  Future<CommunityUser> resolveUser(String handle) => _guard(() async {
    final normalized = handle.trim().replaceFirst(RegExp(r'^@'), '');
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/resolve/${Uri.encodeComponent(normalized)}',
    );
    final data = response.data!;
    if (data['kind'] != 'user') {
      throw const CommunityRequestException(
        'user_not_found',
        'No user was found with that handle.',
      );
    }
    return CommunityUser.fromJson({
      'id': data['id'],
      'role': '',
      'handle': data['handle'],
      'first_name': data['title'],
    });
  });

  Future<void> addMember({
    required String conversationId,
    required String userId,
    CommunityMemberRole role = CommunityMemberRole.member,
  }) => _guard(() async {
    await _client.dio.post<void>(
      '/conversations/$conversationId/members',
      data: {'user_id': userId, 'role': role.name},
    );
  });

  Future<void> removeMember({
    required String conversationId,
    required String memberId,
  }) => _guard(() async {
    await _client.dio.delete<void>(
      '/conversations/$conversationId/members/$memberId',
    );
  });

  Future<List<CommunityInvite>> listInvites(
    String conversationId,
  ) => _guard(() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/conversations/$conversationId/invites',
    );
    return (response.data ?? const <dynamic>[])
        .map(
          (item) =>
              CommunityInvite.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  });

  Future<CommunityInvite> createInvite({
    required String conversationId,
    int? expiresInHours = 168,
    int? maxUses,
  }) => _guard(() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/conversations/$conversationId/invites',
      data: {'expires_in_hours': expiresInHours, 'max_uses': maxUses},
    );
    return CommunityInvite.fromJson(response.data!);
  });

  Future<void> revokeInvite({
    required String conversationId,
    required String inviteId,
  }) => _guard(() async {
    await _client.dio.delete<void>(
      '/conversations/$conversationId/invites/$inviteId',
    );
  });

  Future<void> leave(String conversationId) => _guard(() async {
    await _client.dio.post<void>('/conversations/$conversationId/leave');
  });

  Future<void> delete(String conversationId) => _guard(() async {
    await _client.dio.delete<void>('/conversations/$conversationId');
  });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final body = error.response?.data;
      final envelope = body is Map ? body['error'] : null;
      if (envelope is Map) {
        throw CommunityRequestException(
          envelope['code']?.toString() ?? 'request_failed',
          envelope['detail']?.toString() ?? 'Request failed',
        );
      }
      throw CommunityRequestException(
        'network_error',
        error.message ?? 'Network request failed',
      );
    }
  }
}

String? _nullableText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
