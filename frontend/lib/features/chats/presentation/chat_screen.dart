import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/authenticated_media.dart';
import 'package:university_messenger/core/media/media_thumbnail.dart';
import 'package:university_messenger/features/calls/calls_feature.dart';
import 'package:university_messenger/features/chats/chat_strings.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/features/reports/reports.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.conversationId,
    this.embedded = false,
    super.key,
  });

  final String conversationId;
  final bool embedded;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  var _typingSent = false;
  var _didInitialScroll = false;
  String? _lastVisibleMessageId;
  int _lastMarkedRead = 0;
  var _historyLoading = false;
  var _historyRun = 0;
  var _historyError = false;
  var _uploading = false;
  ChatMessage? _replyingTo;
  ChatMessage? _editing;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecent());
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId == widget.conversationId) return;
    _didInitialScroll = false;
    _lastVisibleMessageId = null;
    _lastMarkedRead = 0;
    _historyError = false;
    _replyingTo = null;
    _editing = null;
    _messageController.clear();
    unawaited(_loadRecent());
  }

  Future<void> _loadRecent() async {
    final run = ++_historyRun;
    setState(() {
      _historyLoading = true;
      _historyError = false;
    });
    try {
      await ref
          .read(chatRepositoryProvider)
          .loadRecentMessages(widget.conversationId);
    } catch (_) {
      if (mounted && run == _historyRun) setState(() => _historyError = true);
    } finally {
      if (mounted && run == _historyRun) {
        setState(() => _historyLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_typingSent) {
      ref.read(chatRepositoryProvider).setTyping(widget.conversationId, false);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final repository = ref.read(chatRepositoryProvider);
    if (value.trim().isNotEmpty && !_typingSent) {
      _typingSent = true;
      repository.setTyping(widget.conversationId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_typingSent) {
        _typingSent = false;
        repository.setTyping(widget.conversationId, false);
      }
    });
  }

  Future<void> _send() async {
    final body = _messageController.text;
    if (body.trim().isEmpty) return;
    final editing = _editing;
    final replyingTo = _replyingTo;
    _typingTimer?.cancel();
    _typingSent = false;
    ref.read(chatRepositoryProvider).setTyping(widget.conversationId, false);
    final chat = widget.conversationId;
    if (editing == null) _messageController.clear();
    await _runChatAction(() async {
      final repository = ref.read(chatRepositoryProvider);
      if (editing != null) {
        await repository.editMessage(editing.id, body);
      } else {
        await repository.sendMessage(
          chat,
          body: body,
          replyToId: replyingTo?.id,
        );
      }
      if (!mounted || chat != widget.conversationId) return;
      if (editing != null && _messageController.text == body) {
        _messageController.clear();
      }
      setState(() {
        if (_editing == editing) _editing = null;
        if (_replyingTo == replyingTo) _replyingTo = null;
      });
      _scrollToBottom();
    });
  }

  Future<void> _pickAttachment() async {
    final chat = widget.conversationId;
    setState(() => _uploading = true);
    try {
      final files = await openFiles();
      if (!mounted || files.isEmpty || chat != widget.conversationId) return;
      if (files.length > 10) {
        _notice(context.l10n.chatAttachmentLimit);
        return;
      }
      final caption = _messageController.text.trim();
      final reply = _replyingTo?.id;
      final client = ref.read(mediaClientProvider);
      final ids = <String>[];
      String type = 'album';
      for (final file in files) {
        final media = await client.upload(file);
        if (!mounted || chat != widget.conversationId) return;
        ids.add(media.id);
        if (files.length == 1) {
          type = switch (media.kind) {
            'gif' => 'animation',
            'document' => 'file',
            _ => media.kind,
          };
        }
      }
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chat,
            type: type,
            body: caption.isEmpty ? null : caption,
            attachmentIds: ids,
            replyToId: reply,
          );
      if (mounted && widget.conversationId == chat) {
        if (_messageController.text.trim() == caption) {
          _messageController.clear();
        }
        setState(() => _replyingTo = null);
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        final l10n = context.l10n;
        _notice(localizedMediaError(l10n, error, l10n.chatUploadFailed));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _runChatAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        _notice(localizedApiError(context.l10n, apiErrorCode(error)));
      }
    }
  }

  Future<void> _createPoll() async {
    final chat = widget.conversationId;
    final form = GlobalKey<FormState>();
    final values = List.filled(3, '');
    final poll = await showDialog<ChatPoll>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          scrollable: true,
          title: Text(l10n.chatCreatePoll),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < values.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  TextFormField(
                    autofocus: index == 0,
                    decoration: InputDecoration(
                      labelText: index == 0
                          ? l10n.chatPollQuestion
                          : l10n.chatPollOption(index),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? l10n.requiredField
                        : null,
                    onSaved: (value) => values[index] = value!.trim(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                form.currentState!.save();
                Navigator.pop(
                  context,
                  ChatPoll(
                    question: values.first,
                    options: values.sublist(1),
                    voteCounts: const [0, 0],
                  ),
                );
              },
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );
    if (poll == null || !mounted || chat != widget.conversationId) return;
    await _runChatAction(() async {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(chat, type: 'poll', poll: poll);
      if (mounted && chat == widget.conversationId) _scrollToBottom();
    });
  }

  Future<void> _showStickerPanel() async {
    final repository = ref.read(chatRepositoryProvider);
    final chat = widget.conversationId;
    final library = Future.wait<Object>([
      repository.listFavoriteStickers(),
      repository.listRecentStickers(),
      repository.listStickerPacks(),
      repository.listSavedGifs(),
    ]);
    final selection =
        await showModalBottomSheet<
          ({String type, String mediaId, String? stickerId})
        >(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => FutureBuilder(
            future: library,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 280,
                  child: Center(child: Text(context.l10n.chatStickerLoadError)),
                );
              }
              final l10n = context.l10n;
              final data = snapshot.data!;
              final favorites = data[0] as List<ChatSticker>;
              final recents = data[1] as List<ChatSticker>;
              final packs = data[2] as List<ChatStickerPack>;
              final gifs = data[3] as List<String>;
              return DefaultTabController(
                length: 3,
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.56,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            text: l10n.chatEmoji,
                          ),
                          Tab(
                            icon: const Icon(Icons.auto_awesome_outlined),
                            text: l10n.chatStickers,
                          ),
                          Tab(
                            icon: const Icon(Icons.gif_box_outlined),
                            text: l10n.chatGifs,
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _EmojiGrid(
                              onSelected: (emoji) {
                                _messageController.text += emoji;
                                _messageController.selection =
                                    TextSelection.collapsed(
                                      offset: _messageController.text.length,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                            Column(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: Text(l10n.chatAddSticker),
                                  onPressed: () => Navigator.pop(context, (
                                    type: 'new-sticker',
                                    mediaId: '',
                                    stickerId: null,
                                  )),
                                ),
                                Expanded(
                                  child: _StickerGrid(
                                    favorites: favorites,
                                    recents: recents,
                                    packs: packs,
                                    onSelected: (sticker) =>
                                        Navigator.pop(context, (
                                          type: 'sticker',
                                          mediaId: sticker.mediaId,
                                          stickerId: sticker.id,
                                        )),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.chatAddGif),
                                  onPressed: () => Navigator.pop(context, (
                                    type: 'new-gif',
                                    mediaId: '',
                                    stickerId: null,
                                  )),
                                ),
                                Expanded(
                                  child: _GifGrid(
                                    mediaIds: gifs,
                                    onSelected: (mediaId) =>
                                        Navigator.pop(context, (
                                          type: 'animation',
                                          mediaId: mediaId,
                                          stickerId: null,
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
    if (selection == null || !mounted || chat != widget.conversationId) return;
    var (type: type, mediaId: mediaId, stickerId: stickerId) = selection;
    setState(() => _uploading = true);
    try {
      if (type.startsWith('new-')) {
        final gif = type == 'new-gif';
        final file = await openFile(
          acceptedTypeGroups: [
            XTypeGroup(
              label: gif ? context.l10n.gif : context.l10n.sticker,
              extensions: gif ? ['gif'] : ['png', 'webp', 'jpg', 'jpeg'],
              mimeTypes: gif
                  ? ['image/gif']
                  : ['image/png', 'image/webp', 'image/jpeg'],
              uniformTypeIdentifiers: gif
                  ? ['com.compuserve.gif']
                  : ['public.image'],
            ),
          ],
        );
        if (file == null || !mounted || chat != widget.conversationId) return;
        final api = ref.read(apiClientProvider);
        final media = await ref.read(mediaClientProvider).upload(file);
        mediaId = media.id;
        type = gif ? 'animation' : 'sticker';
        if (gif) {
          await api.dio.put<void>('/gifs/$mediaId');
        } else {
          stickerId =
              (await api.post(
                    '/stickers/custom',
                    data: {'media_id': mediaId},
                  )).data!['id']
                  as String;
        }
      }
      if (!mounted || chat != widget.conversationId) return;
      await repository.sendMessage(
        chat,
        type: type,
        attachmentIds: [mediaId],
        replyToId: _replyingTo?.id,
      );
      if (stickerId != null) await repository.markStickerRecent(stickerId);
      if (mounted && chat == widget.conversationId) {
        setState(() => _replyingTo = null);
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        final l10n = context.l10n;
        _notice(localizedMediaError(l10n, error, l10n.chatSendStickerError));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _forwardMessage(ChatMessage message) async {
    final repo = ref.read(chatRepositoryProvider);
    try {
      final conversations = await repo.watchConversations().first;
      if (!mounted) return;
      final target = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(context.l10n.chatForwardTo),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'saved'),
              child: ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: Text(context.l10n.savedMessages),
              ),
            ),
            for (final item in conversations)
              if (!item.isSavedMessages &&
                  item.id != message.conversationId &&
                  (item.type != ConversationType.channel ||
                      ['owner', 'admin'].contains(item.myRole)))
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, item.id),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    title: Text(chatTitle(context.l10n, item)),
                  ),
                ),
          ],
        ),
      );
      if (target == null || !mounted) return;
      final id = target == 'saved'
          ? await repo.openDm(
              ref.read(authControllerProvider).state.account!.id,
            )
          : target;
      await repo.sendMessage(
        id,
        type: message.type,
        body: message.body,
        poll: message.poll,
        attachmentIds: message.attachmentIds,
        forwardFrom: {'message_id': message.id},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.chatForwardAdded),
            action: SnackBarAction(
              label: context.l10n.open,
              onPressed: () => context.go('/home/chat/$id'),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final l10n = context.l10n;
        final code = apiErrorCode(error);
        _notice(
          code == null || code == 'request_failed'
              ? l10n.chatForwardFailed
              : localizedApiError(l10n, code),
        );
      }
    }
  }

  Future<void> _showPinnedMessages() => _runChatAction(() async {
    final chat = widget.conversationId;
    final messages = await ref.read(chatRepositoryProvider).listPinned(chat);
    if (!mounted || chat != widget.conversationId) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: messages.isEmpty
            ? SizedBox(
                height: 180,
                child: Center(child: Text(context.l10n.chatNoPinned)),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: messages.length,
                itemBuilder: (_, index) => ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(
                    chatMessagePreview(context.l10n, messages[index]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      ),
    );
  });

  Future<void> _showMessageActions(ChatMessage message, bool mine) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.type == 'sticker' &&
                    message.attachmentIds.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(l10n.chatFavoriteSticker),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await ref
                            .read(apiClientProvider)
                            .dio
                            .put<void>(
                              '/stickers/media/${message.attachmentIds.first}/favorite',
                            );
                        if (mounted) _notice(context.l10n.chatStickerFavorited);
                      } catch (_) {
                        if (mounted) _notice(context.l10n.chatFavoriteFailed);
                      }
                    },
                  ),
                if (message.type == 'animation' &&
                    message.attachmentIds.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.gif_box_outlined),
                    title: Text(l10n.chatSaveGif),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await ref
                            .read(apiClientProvider)
                            .dio
                            .put<void>('/gifs/${message.attachmentIds.first}');
                        if (mounted) _notice(context.l10n.chatGifSaved);
                      } catch (_) {
                        if (mounted) _notice(context.l10n.chatGifSaveFailed);
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: Text(l10n.chatReply),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _replyingTo = message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_reaction_outlined),
                  title: Text(l10n.chatReact),
                  trailing: Wrap(
                    children: ['👍', '❤️', '👏']
                        .map(
                          (emoji) => IconButton(
                            tooltip: l10n.chatReactWith(emoji),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _runChatAction(
                                () => ref
                                    .read(chatRepositoryProvider)
                                    .addReaction(message.id, emoji),
                              );
                            },
                            icon: Text(emoji),
                          ),
                        )
                        .toList(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.forward_rounded),
                  title: Text(l10n.chatForward),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _forwardMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(l10n.chatPinMessage),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _runChatAction(
                      () => ref
                          .read(chatRepositoryProvider)
                          .setPinned(message.id, true),
                    );
                  },
                ),
                if (mine && message.type == 'text')
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.edit),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _editing = message;
                        _replyingTo = null;
                        _messageController.text =
                            chatMessageBody(l10n, message) ?? '';
                      });
                    },
                  ),
                if (mine)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.delete,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _runChatAction(
                        () => ref
                            .read(chatRepositoryProvider)
                            .deleteMessage(message.id),
                      );
                    },
                  ),
                if (!mine)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(l10n.reportSubmitTitle),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SubmitReportScreen(
                            target: ReportTargetContext.message(
                              messageId: message.id,
                              conversationId: message.conversationId,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations =
        ref.watch(conversationsProvider).valueOrNull ?? const [];
    final conversation = conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final typing = ref
        .watch(typingUsersProvider(widget.conversationId))
        .valueOrNull;
    final peerName =
        conversation == null ||
            conversation.isSavedMessages ||
            conversation.title.isEmpty
        ? null
        : chatTitle(context.l10n, conversation);

    final content = Column(
      children: [
        _ChatHeader(
          conversation: conversation,
          showBack: !widget.embedded,
          onBack: () => context.canPop() ? context.pop() : context.go('/home'),
          typing: typing?.isNotEmpty == true,
          onAudioCall:
              conversation?.type == ConversationType.dm &&
                  conversation?.isSavedMessages == false
              ? () => context.push(
                  CallRoutes.outgoingLocation(
                    conversationId: widget.conversationId,
                    kind: CallKind.audio,
                    peerName: peerName,
                  ),
                )
              : null,
          onVideoCall:
              conversation?.type == ConversationType.dm &&
                  conversation?.isSavedMessages == false
              ? () => context.push(
                  CallRoutes.outgoingLocation(
                    conversationId: widget.conversationId,
                    kind: CallKind.video,
                    peerName: peerName,
                  ),
                )
              : null,
          onInfo: conversation?.type == ConversationType.dm
              ? null
              : () =>
                    context.push('/home/communities/${widget.conversationId}'),
          onPinned: _showPinnedMessages,
        ),
        ReviewStateBanner(conversationId: widget.conversationId),
        if (_historyError)
          MaterialBanner(
            content: Text(context.l10n.genericError),
            leading: const Icon(Icons.cloud_off_rounded),
            actions: [
              TextButton(
                onPressed: _loadRecent,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        if (_historyLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(context.l10n.genericError)),
              data: (items) {
                final lastId = items.lastOrNull?.id;
                if (_didInitialScroll &&
                    lastId != null &&
                    lastId != _lastVisibleMessageId &&
                    _scrollController.hasClients &&
                    _scrollController.position.extentAfter < 96) {
                  _scrollToBottom();
                }
                _lastVisibleMessageId = lastId;
                if (!_didInitialScroll && items.isNotEmpty) {
                  _didInitialScroll = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });
                }
                final latestSequence = items
                    .map((item) => item.sequence ?? 0)
                    .fold(0, (a, b) => a > b ? a : b);
                if (latestSequence > _lastMarkedRead) {
                  _lastMarkedRead = latestSequence;
                  unawaited(
                    ref
                        .read(chatRepositoryProvider)
                        .markRead(widget.conversationId, latestSequence),
                  );
                }
                return _MessageList(
                  messages: items,
                  controller: _scrollController,
                  accountId: ref.read(authControllerProvider).state.account?.id,
                  onLoadEarlier: () => _runChatAction(
                    () => ref
                        .read(chatRepositoryProvider)
                        .loadOlderMessages(widget.conversationId),
                  ),
                  onRetry: ref.read(chatRepositoryProvider).retryMessage,
                  onLongPress: _showMessageActions,
                  onVote: (messageId, option) => _runChatAction(
                    () => ref.read(chatRepositoryProvider).votePoll(messageId, [
                      option,
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
        _Composer(
          controller: _messageController,
          onChanged: _onChanged,
          onSend: _send,
          onAttach: _pickAttachment,
          onPoll: _createPoll,
          onStickers: _showStickerPanel,
          busy: _uploading,
          contextMessage: _editing ?? _replyingTo,
          editing: _editing != null,
          onCancelContext: () => setState(() {
            _editing = null;
            _replyingTo = null;
            _messageController.clear();
          }),
        ),
      ],
    );
    return widget.embedded
        ? Material(color: Theme.of(context).colorScheme.surface, child: content)
        : Scaffold(body: SafeArea(child: content));
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.conversation,
    required this.showBack,
    required this.onBack,
    required this.typing,
    this.onAudioCall,
    this.onVideoCall,
    this.onInfo,
    this.onPinned,
  });

  final ChatConversation? conversation;
  final bool showBack;
  final VoidCallback onBack;
  final bool typing;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onInfo;
  final VoidCallback? onPinned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chat = conversation;
    final title = chat == null ? l10n.chats : chatTitle(l10n, chat);
    final subtitle = typing
        ? l10n.typing
        : chat?.type == ConversationType.dm
        ? l10n.directMessage
        : chat == null
        ? null
        : l10n.membersCount(chat.memberCount);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              tooltip: l10n.back,
              icon: const BackButtonIcon(),
            ),
          ContactAvatar(
            id: conversation?.avatarId,
            fallback: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                conversation?.type == ConversationType.group
                    ? Icons.group_rounded
                    : conversation?.type == ConversationType.channel
                    ? Icons.campaign_rounded
                    : Icons.person_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: typing
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onAudioCall != null)
            IconButton(
              onPressed: onAudioCall,
              tooltip: l10n.callAudioCall,
              icon: const Icon(Icons.call_outlined),
            ),
          if (onVideoCall != null)
            IconButton(
              onPressed: onVideoCall,
              tooltip: l10n.callVideoCall,
              icon: const Icon(Icons.videocam_outlined),
            ),
          if (onInfo != null)
            IconButton(
              onPressed: onInfo,
              tooltip: l10n.chatConversationInfo,
              icon: const Icon(Icons.info_outline_rounded),
            ),
          IconButton(
            onPressed: onPinned,
            tooltip: l10n.chatPinnedMessages,
            icon: const Icon(Icons.push_pin_outlined),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.controller,
    required this.accountId,
    required this.onLoadEarlier,
    required this.onRetry,
    required this.onLongPress,
    required this.onVote,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final String? accountId;
  final Future<void> Function() onLoadEarlier;
  final Future<void> Function(String) onRetry;
  final Future<void> Function(ChatMessage, bool) onLongPress;
  final Future<void> Function(String, int) onVote;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(child: Text(context.l10n.noChatsBody));
    }
    final byId = {for (final message in messages) message.id: message};
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Center(
            child: TextButton(
              onPressed: onLoadEarlier,
              child: Text(context.l10n.loadEarlier),
            ),
          );
        }
        final message = messages[index - 1];
        final previous = index > 1 ? messages[index - 2] : null;
        final showDate =
            previous == null ||
            !DateUtils.isSameDay(previous.createdAt, message.createdAt);
        return Column(
          children: [
            if (showDate) _DateSeparator(date: message.createdAt),
            _MessageBubble(
              message: message,
              reply: byId[message.replyToId],
              mine: message.isMine(accountId),
              onLongPress: () =>
                  onLongPress(message, message.isMine(accountId)),
              onVote: (index) => onVote(message.id, index),
              onRetry: message.clientMessageId == null
                  ? null
                  : () => onRetry(message.clientMessageId!),
            ),
          ],
        );
      },
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = DateUtils.isSameDay(now, date)
        ? context.l10n.today
        : DateUtils.isSameDay(now.subtract(const Duration(days: 1)), date)
        ? context.l10n.yesterday
        : MaterialLocalizations.of(context).formatShortDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.reply,
    required this.mine,
    required this.onLongPress,
    required this.onVote,
    this.onRetry,
  });

  final ChatMessage message;
  final ChatMessage? reply;
  final bool mine;
  final VoidCallback onLongPress;
  final ValueChanged<int> onVote;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final body = chatMessageBody(l10n, message);
    final forwardedBy = message.forwardFrom?['name']?.toString();
    final failed = message.delivery == MessageDelivery.failed;
    final actions =
        message.deletedAt == null && message.delivery == MessageDelivery.sent
        ? onLongPress
        : null;
    final bubbleColor = mine ? scheme.primaryContainer : scheme.surface;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tailOnLeft = mine ? rtl : !rtl;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(tailOnLeft ? 4 : 16),
      bottomRight: Radius.circular(tailOnLeft ? 16 : 4),
    );
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Semantics(
        container: true,
        button: failed || actions != null,
        label: failed ? l10n.messageFailed : null,
        child: GestureDetector(
          onTap: failed ? onRetry : actions,
          onLongPress: actions,
          onSecondaryTap: actions,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width.clamp(280, 760) * 0.72,
            ),
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.fromLTRB(13, 9, 10, 7),
            decoration: BoxDecoration(
              color: failed ? scheme.errorContainer : bubbleColor,
              borderRadius: radius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.replyToId != null && message.deletedAt == null)
                  _ReplyQuote(message.replyToId!, reply),
                if (message.forwardFrom != null && message.deletedAt == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      forwardedBy == null || forwardedBy.isEmpty
                          ? l10n.chatForwardedMessage
                          : l10n.chatForwardedFrom('\u2068$forwardedBy\u2069'),
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                    ),
                  ),
                if (message.deletedAt != null)
                  Text(
                    l10n.messageDeleted,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (message.poll != null)
                  _PollContent(poll: message.poll!, onVote: onVote)
                else ...[
                  if (body != null && body.isNotEmpty)
                    Directionality(
                      textDirection: _textDirection(body),
                      child: Text(
                        body,
                        style: TextStyle(
                          color: failed ? scheme.onErrorContainer : null,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (message.attachmentIds.isNotEmpty) ...[
                    if (body?.isNotEmpty == true) const SizedBox(height: 8),
                    ...message.attachmentIds.map(
                      (id) =>
                          _AttachmentContent(type: message.type, mediaId: id),
                    ),
                  ],
                ],
                if (message.reactions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: message.reactions.entries
                        .map(
                          (entry) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.key} ${MaterialLocalizations.of(context).formatDecimal(entry.value)}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (failed)
                      Text(
                        l10n.messageFailed,
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontSize: 11,
                        ),
                      )
                    else ...[
                      Text(
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay.fromDateTime(message.createdAt.toLocal()),
                          alwaysUse24HourFormat:
                              MediaQuery.alwaysUse24HourFormatOf(context),
                        ),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      if (message.editedAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${l10n.edited}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (mine) ...[
                        const SizedBox(width: 5),
                        Icon(
                          message.delivery == MessageDelivery.sending
                              ? Icons.schedule_rounded
                              : Icons.done_rounded,
                          semanticLabel:
                              message.delivery == MessageDelivery.sending
                              ? l10n.messageSending
                              : l10n.chatMessageSent,
                          size: 15,
                          color: scheme.primary,
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyQuote extends ConsumerWidget {
  const _ReplyQuote(this.id, this.cached);
  final String id;
  final ChatMessage? cached;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    icon: const Icon(Icons.reply, size: 16),
    label: Text(
      cached == null
          ? context.l10n.chatViewOriginal
          : chatMessagePreview(context.l10n, cached!),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    onPressed: () async {
      try {
        final original =
            cached ??
            ChatMessage.fromJson(
              (await ref.read(apiClientProvider).get('/messages/$id')).data!,
            );
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  context.l10n.chatOriginalMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(chatMessagePreview(context.l10n, original)),
                if (original.deletedAt == null)
                  for (final media in original.attachmentIds)
                    AuthenticatedMediaTile(mediaId: media),
              ],
            ),
          ),
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.chatOriginalUnavailable)),
          );
        }
      }
    },
  );
}

class _PollContent extends StatelessWidget {
  const _PollContent({required this.poll, required this.onVote});

  final ChatPoll poll;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final total = poll.voteCounts.fold<int>(0, (sum, count) => sum + count);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            poll.question,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < poll.options.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton(
                onPressed: poll.closedAt == null ? () => onVote(index) : null,
                child: Row(
                  children: [
                    Expanded(child: Text(poll.options[index])),
                    Text(
                      MaterialLocalizations.of(context).formatDecimal(
                        index < poll.voteCounts.length
                            ? poll.voteCounts[index]
                            : 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            context.l10n.chatPollVotes(total),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _AttachmentContent extends StatelessWidget {
  const _AttachmentContent({required this.type, required this.mediaId});

  final String type;
  final String mediaId;

  @override
  Widget build(BuildContext context) => AuthenticatedMediaTile(
    mediaId: mediaId,
    label: localizedMessageType(context.l10n, type),
    compact: type == 'sticker',
  );
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _emoji = [
    '😀',
    '😂',
    '🥰',
    '😎',
    '🤔',
    '👏',
    '👍',
    '❤️',
    '🎉',
    '📚',
    '✅',
    '🙏',
  ];

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemCount: _emoji.length,
    itemBuilder: (_, index) => InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onSelected(_emoji[index]),
      child: Center(
        child: Text(_emoji[index], style: const TextStyle(fontSize: 28)),
      ),
    ),
  );
}

class _StickerGrid extends StatelessWidget {
  const _StickerGrid({
    required this.favorites,
    required this.recents,
    required this.packs,
    required this.onSelected,
  });

  final List<ChatSticker> favorites;
  final List<ChatSticker> recents;
  final List<ChatStickerPack> packs;
  final ValueChanged<ChatSticker> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seen = <String>{};
    final sections = <Widget>[];
    for (final (title, items) in [
      (l10n.chatStickerFavorites, favorites),
      (l10n.chatStickerRecents, recents),
      for (final pack in packs) (stickerPackTitle(l10n, pack), pack.stickers),
    ]) {
      final stickers = items.where((sticker) => seen.add(sticker.id)).toList();
      if (stickers.isEmpty) continue;
      sections.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
        ),
      );
      sections.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelected(sticker),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: MediaThumbnail(
                      sticker.mediaId,
                      fit: BoxFit.contain,
                      label: sticker.emoji ?? l10n.sticker,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return sections.isEmpty
        ? Center(child: Text(l10n.chatNoStickers))
        : CustomScrollView(slivers: sections);
  }
}

class _GifGrid extends StatelessWidget {
  const _GifGrid({required this.mediaIds, required this.onSelected});

  final List<String> mediaIds;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (mediaIds.isEmpty) {
      return Center(child: Text(context.l10n.chatNoGifs));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: mediaIds.length,
      itemBuilder: (_, index) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onSelected(mediaIds[index]),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: MediaThumbnail(mediaIds[index], label: context.l10n.gif),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.onPoll,
    required this.onStickers,
    required this.busy,
    required this.contextMessage,
    required this.editing,
    required this.onCancelContext,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onPoll;
  final VoidCallback onStickers;
  final bool busy;
  final ChatMessage? contextMessage;
  final bool editing;
  final VoidCallback onCancelContext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contextMessage != null)
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Icon(
                      editing ? Icons.edit_outlined : Icons.reply_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        editing
                            ? l10n.chatEditingMessage
                            : chatMessagePreview(l10n, contextMessage!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onCancelContext,
                      tooltip: l10n.cancel,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    enabled: !busy && !editing,
                    tooltip: l10n.attach,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onSelected: (value) {
                      if (value == 'file') onAttach();
                      if (value == 'poll') onPoll();
                      if (value == 'stickers') onStickers();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'file',
                        child: ListTile(
                          leading: const Icon(Icons.attach_file_rounded),
                          title: Text(l10n.chatMediaPicker),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'poll',
                        child: ListTile(
                          leading: const Icon(Icons.poll_outlined),
                          title: Text(l10n.poll),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'stickers',
                        child: ListTile(
                          leading: const Icon(Icons.emoji_emotions_outlined),
                          title: Text(l10n.chatStickerPicker),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: context.l10n.messageHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: busy ? null : onSend,
                    tooltip: context.l10n.sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextDirection _textDirection(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value)
    ? TextDirection.rtl
    : TextDirection.ltr;
