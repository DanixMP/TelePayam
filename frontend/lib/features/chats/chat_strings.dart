import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

String chatTitle(AppLocalizations l10n, ChatConversation chat) {
  if (chat.isSavedMessages) return l10n.savedMessages;
  return switch (chat.id) {
    'demo-study' => l10n.chatDemoStudy,
    'demo-professor' => l10n.chatDemoProfessor,
    'demo-sara' => l10n.chatDemoSara,
    _ when chat.title.isNotEmpty => chat.title,
    _ => chat.handle ?? chatTypeLabel(l10n, chat.type),
  };
}

String chatTypeLabel(AppLocalizations l10n, ConversationType type) =>
    switch (type) {
      ConversationType.dm => l10n.directMessage,
      ConversationType.group => l10n.group,
      ConversationType.channel => l10n.channel,
    };

String? chatPreview(AppLocalizations l10n, ChatConversation chat) {
  final type = chat.lastMessageType;
  if (type == null) return chat.lastMessageBody;
  if (type.startsWith('demo:')) {
    return _demoBody(l10n, type.substring(5)) ?? chat.lastMessageBody;
  }
  return localizedMessageType(l10n, type);
}

String? chatMessageBody(AppLocalizations l10n, ChatMessage message) =>
    message.editedAt == null
    ? _demoBody(l10n, message.id) ?? message.body
    : message.body;

String chatMessagePreview(AppLocalizations l10n, ChatMessage message) {
  if (message.deletedAt != null) return l10n.messageDeleted;
  final body = chatMessageBody(l10n, message);
  if (body != null && body.isNotEmpty) return body;
  final question = message.poll?.question;
  if (question != null && question.isNotEmpty) return question;
  return localizedMessageType(l10n, message.type);
}

String stickerPackTitle(AppLocalizations l10n, ChatStickerPack pack) =>
    switch (pack.titleKey) {
      'campus_notes' => l10n.chatCampusNotes,
      'my_stickers' => l10n.chatMyStickers,
      _ => pack.title,
    };

String? _demoBody(AppLocalizations l10n, String id) => switch (id) {
  'study-1' => l10n.chatDemoStudyOne,
  'study-2' => l10n.chatDemoStudyTwo,
  'study-3' => l10n.chatDemoStudyThree,
  'prof-1' => l10n.chatDemoProfessorOne,
  'prof-2' => l10n.chatDemoProfessorTwo,
  'sara-preview' => l10n.chatDemoSaraPreview,
  _ => null,
};
