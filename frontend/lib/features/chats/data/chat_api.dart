import 'package:dio/dio.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';

class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  Future<List<ChatConversation>> listConversations() async {
    final response = await _client.dio.get<List<dynamic>>('/conversations');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChatConversation.fromJson)
        .toList();
  }

  Future<ChatConversation> openDm(String userId) async =>
      ChatConversation.fromJson(
        (await _client.post(
          '/conversations/dm',
          data: {'user_id': userId},
        )).data!,
      );

  Future<ChatConversation> conversation(String id) async =>
      ChatConversation.fromJson(
        (await _client.get('/conversations/$id')).data!,
      );

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int? beforeSequence,
    int? afterSequence,
    int limit = 50,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        'before_seq': ?beforeSequence,
        'after_seq': ?afterSequence,
      },
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> sendText({
    required String conversationId,
    required String clientMessageId,
    required String body,
  }) => sendMessage(
    conversationId: conversationId,
    clientMessageId: clientMessageId,
    body: body,
  );

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String clientMessageId,
    String type = 'text',
    String? body,
    String? replyToId,
    List<String> attachmentIds = const [],
    ChatPoll? poll,
    Map<String, dynamic>? forwardFrom,
    bool silent = false,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      data: {
        'client_msg_id': clientMessageId,
        'type': type,
        'body': body,
        'reply_to_id': replyToId,
        'forward_from': forwardFrom,
        'attachment_ids': attachmentIds,
        'silent': silent,
        if (poll != null)
          'poll': {
            'question': poll.question,
            'options': poll.options,
            'multiple_choice': poll.multipleChoice,
          },
      },
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<ChatMessage> editMessage(String messageId, String body) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/messages/$messageId',
      data: {'body': body, 'entities': <Map<String, dynamic>>[]},
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<void> deleteMessage(String messageId) =>
      _client.dio.delete<void>('/messages/$messageId');

  Future<ChatMessage> addReaction(String messageId, String emoji) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<ChatMessage> removeReaction(String messageId, String emoji) async {
    final response = await _client.dio.delete<Map<String, dynamic>>(
      '/messages/$messageId/reactions/$emoji',
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<ChatMessage> votePoll(
    String messageId,
    List<int> optionIndexes,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/messages/$messageId/poll-vote',
      data: {'option_indexes': optionIndexes},
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<void> setPinned(String messageId, bool pinned) => pinned
      ? _client.dio.put<void>('/messages/$messageId/pin')
      : _client.dio.delete<void>('/messages/$messageId/pin');

  Future<List<ChatMessage>> listPinned(String conversationId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/conversations/$conversationId/pinned',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<MediaAttachment> uploadFile({
    required String path,
    required String fileName,
    ProgressCallback? onProgress,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/media',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      }),
      onSendProgress: onProgress,
    );
    return MediaAttachment.fromJson(response.data!);
  }

  Future<MediaAttachment> getMediaMetadata(String mediaId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/media/$mediaId/metadata',
    );
    return MediaAttachment.fromJson(response.data!);
  }

  Future<List<ChatStickerPack>> listStickerPacks() async {
    final response = await _client.dio.get<List<dynamic>>('/stickers/packs');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChatStickerPack.fromJson)
        .toList();
  }

  Future<List<ChatSticker>> listFavoriteStickers() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/stickers/favorites',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChatSticker.fromJson)
        .toList();
  }

  Future<List<ChatSticker>> listRecentStickers() async {
    final response = await _client.dio.get<List<dynamic>>('/stickers/recents');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChatSticker.fromJson)
        .toList();
  }

  Future<void> markStickerRecent(String stickerId) =>
      _client.dio.put<void>('/stickers/$stickerId/recent');

  Future<List<String>> listSavedGifs() async {
    final lists = await Future.wait([
      _client.getList('/gifs'),
      _client.getList('/gifs/featured'),
    ]);
    return {for (final list in lists) ...list.data!.cast<String>()}.toList();
  }

  Future<void> markRead(String conversationId, int sequence) =>
      _client.dio.put<void>(
        '/conversations/$conversationId/read',
        data: {'seq': sequence},
      );
}
