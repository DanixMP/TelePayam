import 'package:university_messenger/features/chats/domain/chat_models.dart';

abstract interface class ChatRepository {
  Stream<List<ChatConversation>> watchConversations({
    String query = '',
    Iterable<String?> Function(ChatConversation)? conversationSearchText,
    String? Function(ChatMessage)? messageSearchText,
  });
  Stream<List<ChatMessage>> watchMessages(String conversationId);
  Stream<Set<String>> watchTypingUsers(String conversationId);

  Future<void> initialize();
  Future<void> refreshConversations();
  Future<String> openDm(String userId);
  Future<void> loadRecentMessages(String conversationId);
  Future<void> loadOlderMessages(String conversationId);
  Future<void> sendText(String conversationId, String body);
  Future<void> sendMessage(
    String conversationId, {
    String type,
    String? body,
    String? replyToId,
    List<String> attachmentIds,
    ChatPoll? poll,
    Map<String, dynamic>? forwardFrom,
    bool silent,
  });
  Future<MediaAttachment> uploadFile({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  });
  Future<void> editMessage(String messageId, String body);
  Future<void> deleteMessage(String messageId);
  Future<void> addReaction(String messageId, String emoji);
  Future<void> removeReaction(String messageId, String emoji);
  Future<void> votePoll(String messageId, List<int> optionIndexes);
  Future<void> setPinned(String messageId, bool pinned);
  Future<List<ChatMessage>> listPinned(String conversationId);
  Future<List<ChatStickerPack>> listStickerPacks();
  Future<List<ChatSticker>> listFavoriteStickers();
  Future<List<ChatSticker>> listRecentStickers();
  Future<void> markStickerRecent(String stickerId);
  Future<List<String>> listSavedGifs();
  Future<void> retryMessage(String clientMessageId);
  Future<void> markRead(String conversationId, int sequence);
  void setTyping(String conversationId, bool typing);
  Future<void> dispose();
}
