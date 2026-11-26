import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/authenticated_media.dart';
import 'package:university_messenger/core/media/media_thumbnail.dart';
import 'package:university_messenger/features/calls/calls_feature.dart';
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
    _messageController.clear();
    _typingTimer?.cancel();
    _typingSent = false;
    ref.read(chatRepositoryProvider).setTyping(widget.conversationId, false);
    if (editing != null) {
      await ref.read(chatRepositoryProvider).editMessage(editing.id, body);
    } else {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            widget.conversationId,
            body: body,
            replyToId: replyingTo?.id,
          );
    }
    if (mounted) {
      setState(() {
        _editing = null;
        _replyingTo = null;
      });
    }
    _scrollToBottom();
  }

  Future<void> _pickAttachment() async {
    final chat = widget.conversationId;
    final files = await openFiles();
    if (!mounted || files.isEmpty || chat != widget.conversationId) return;
    if (files.length > 10) {
      _notice('Choose up to 10 attachments per message.');
      return;
    }
    final caption = _messageController.text.trim();
    final reply = _replyingTo?.id;
    setState(() => _uploading = true);
    try {
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
        _notice(
          error is FormatException
              ? error.message
              : 'Upload failed. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _createPoll() async {
    final question = TextEditingController();
    final first = TextEditingController();
    final second = TextEditingController();
    final poll = await showDialog<ChatPoll>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: question,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: first,
              decoration: const InputDecoration(labelText: 'Option 1'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: second,
              decoration: const InputDecoration(labelText: 'Option 2'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final options = [first.text.trim(), second.text.trim()];
              if (question.text.trim().isEmpty ||
                  options.any((e) => e.isEmpty)) {
                return;
              }
              Navigator.pop(
                context,
                ChatPoll(
                  question: question.text.trim(),
                  options: options,
                  voteCounts: const [0, 0],
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    question.dispose();
    first.dispose();
    second.dispose();
    if (poll == null) return;
    await ref
        .read(chatRepositoryProvider)
        .sendMessage(widget.conversationId, type: 'poll', poll: poll);
    _scrollToBottom();
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
                return const SizedBox(
                  height: 280,
                  child: Center(
                    child: Text('Could not load stickers and GIFs.'),
                  ),
                );
              }
              final data = snapshot.data!;
              final favorites = data[0] as List<ChatSticker>;
              final recents = data[1] as List<ChatSticker>;
              final packs = data[2] as List<ChatStickerPack>;
              final gifs = data[3] as List<String>;
              final stickers = {
                for (final s in [
                  ...favorites,
                  ...recents,
                  ...packs.expand((p) => p.stickers),
                ])
                  s.id: s,
              }.values.toList();
              return DefaultTabController(
                length: 3,
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.56,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(
                            icon: Icon(Icons.emoji_emotions_outlined),
                            text: 'Emoji',
                          ),
                          Tab(
                            icon: Icon(Icons.auto_awesome_outlined),
                            text: 'Stickers',
                          ),
                          Tab(icon: Icon(Icons.gif_box_outlined), text: 'GIFs'),
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
                                  label: const Text('Add a sticker'),
                                  onPressed: () => Navigator.pop(context, (
                                    type: 'new-sticker',
                                    mediaId: '',
                                    stickerId: null,
                                  )),
                                ),
                                Expanded(
                                  child: _StickerGrid(
                                    stickers: stickers,
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
                                  label: const Text('Add a GIF'),
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
              label: gif ? 'GIF' : 'Sticker',
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
    } catch (_) {
      if (mounted) _notice('Could not send this sticker or GIF. Try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _forwardMessage(ChatMessage message) async {
    final repo = ref.read(chatRepositoryProvider);
    final conversations = await repo.watchConversations().first;
    if (!mounted) return;
    final target = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Forward to'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'saved'),
            child: const ListTile(
              leading: Icon(Icons.bookmark_outline),
              title: Text('Saved messages'),
            ),
          ),
          ...conversations
              .where(
                (item) =>
                    item.id != widget.conversationId &&
                    (item.type != ConversationType.channel ||
                        ['owner', 'admin'].contains(item.myRole)),
              )
              .map(
                (item) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, item.id),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    title: Text(item.title),
                  ),
                ),
              ),
        ],
      ),
    );
    if (target == null || !mounted) return;
    try {
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
            content: const Text('Forward added to chat'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => context.go('/home/chat/$id'),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) _notice('Could not forward this message. Try again.');
    }
  }

  Future<void> _showPinnedMessages() async {
    final messages = await ref
        .read(chatRepositoryProvider)
        .listPinned(widget.conversationId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: messages.isEmpty
            ? const SizedBox(
                height: 180,
                child: Center(child: Text('No pinned messages')),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: messages.length,
                itemBuilder: (_, index) => ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(
                    messages[index].body ?? messages[index].type,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _showMessageActions(ChatMessage message, bool mine) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (message.type == 'sticker' && message.attachmentIds.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Favorite sticker'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref
                        .read(apiClientProvider)
                        .dio
                        .put<void>(
                          '/stickers/media/${message.attachmentIds.first}/favorite',
                        );
                    if (mounted) _notice('Sticker added to favorites.');
                  } catch (_) {
                    if (mounted) _notice('Could not favorite this sticker.');
                  }
                },
              ),
            if (message.type == 'animation' && message.attachmentIds.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.gif_box_outlined),
                title: const Text('Save GIF'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref
                        .read(apiClientProvider)
                        .dio
                        .put<void>('/gifs/${message.attachmentIds.first}');
                    if (mounted) _notice('GIF saved to your library.');
                  } catch (_) {
                    if (mounted) _notice('Could not save this GIF.');
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _replyingTo = message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('React'),
              trailing: Wrap(
                children: ['👍', '❤️', '👏']
                    .map(
                      (emoji) => IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          ref
                              .read(chatRepositoryProvider)
                              .addReaction(message.id, emoji);
                        },
                        icon: Text(emoji),
                      ),
                    )
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(sheetContext);
                _forwardMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Pin message'),
              onTap: () {
                Navigator.pop(sheetContext);
                ref.read(chatRepositoryProvider).setPinned(message.id, true);
              },
            ),
            if (mine && message.type == 'text')
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _editing = message;
                    _replyingTo = null;
                    _messageController.text = message.body ?? '';
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
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(chatRepositoryProvider).deleteMessage(message.id);
                },
              ),
            if (!mine)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
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
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
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

    final content = Column(
      children: [
        _ChatHeader(
          conversation: conversation,
          showBack: !widget.embedded,
          onBack: () => context.canPop() ? context.pop() : context.go('/home'),
          typing: typing?.isNotEmpty == true,
          onAudioCall: conversation?.type == ConversationType.dm
              ? () => context.push(
                  CallRoutes.outgoingLocation(
                    conversationId: widget.conversationId,
                    kind: CallKind.audio,
                    peerName: conversation?.title,
                  ),
                )
              : null,
          onVideoCall: conversation?.type == ConversationType.dm
              ? () => context.push(
                  CallRoutes.outgoingLocation(
                    conversationId: widget.conversationId,
                    kind: CallKind.video,
                    peerName: conversation?.title,
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
                  onLoadEarlier: () => ref
                      .read(chatRepositoryProvider)
                      .loadOlderMessages(widget.conversationId),
                  onRetry: ref.read(chatRepositoryProvider).retryMessage,
                  onLongPress: _showMessageActions,
                  onVote: (messageId, option) => ref
                      .read(chatRepositoryProvider)
                      .votePoll(messageId, [option]),
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
    final title = conversation?.title ?? context.l10n.chats;
    final subtitle = typing
        ? context.l10n.typing
        : conversation?.type == ConversationType.dm
        ? context.l10n.directMessage
        : context.l10n.membersCount(conversation?.memberCount ?? 0);
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
              icon: const Icon(Icons.arrow_back_rounded),
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
                Text(
                  subtitle,
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
              tooltip: 'Audio call',
              icon: const Icon(Icons.call_outlined),
            ),
          if (onVideoCall != null)
            IconButton(
              onPressed: onVideoCall,
              tooltip: 'Video call',
              icon: const Icon(Icons.videocam_outlined),
            ),
          if (onInfo != null)
            IconButton(
              onPressed: onInfo,
              tooltip: 'Conversation info',
              icon: const Icon(Icons.info_outline_rounded),
            ),
          IconButton(
            onPressed: onPinned,
            tooltip: 'Pinned messages',
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
        label: failed ? context.l10n.messageFailed : null,
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
                      message.forwardFrom?['name'] == null
                          ? 'Forwarded message'
                          : 'Forwarded from ${message.forwardFrom!["name"]}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                    ),
                  ),
                if (message.deletedAt != null)
                  Text(
                    'Message deleted',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (message.poll != null)
                  _PollContent(poll: message.poll!, onVote: onVote)
                else ...[
                  if (message.body?.isNotEmpty == true)
                    Directionality(
                      textDirection: _textDirection(message.body ?? ''),
                      child: Text(
                        message.body!,
                        style: TextStyle(
                          color: failed ? scheme.onErrorContainer : null,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (message.attachmentIds.isNotEmpty) ...[
                    if (message.body?.isNotEmpty == true)
                      const SizedBox(height: 8),
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
                            child: Text('${entry.key} ${entry.value}'),
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
                        context.l10n.messageFailed,
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
                          '· ${context.l10n.edited}',
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
      cached?.deletedAt != null
          ? 'Message deleted'
          : cached?.body ?? cached?.type ?? 'View original message',
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
                  'Original message',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  original.deletedAt != null
                      ? 'Message deleted'
                      : original.body ??
                            original.poll?.question ??
                            original.type,
                ),
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
            const SnackBar(content: Text('Original message is unavailable.')),
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
                      '${index < poll.voteCounts.length ? poll.voteCounts[index] : 0}',
                    ),
                  ],
                ),
              ),
            ),
          Text('$total votes', style: Theme.of(context).textTheme.labelSmall),
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
    label: type == 'file'
        ? 'Document'
        : type[0].toUpperCase() + type.substring(1),
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
  const _StickerGrid({required this.stickers, required this.onSelected});

  final List<ChatSticker> stickers;
  final ValueChanged<ChatSticker> onSelected;

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) {
      return const Center(child: Text('No installed stickers'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: stickers.length,
      itemBuilder: (_, index) {
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
                label: sticker.emoji ?? 'Sticker',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GifGrid extends StatelessWidget {
  const _GifGrid({required this.mediaIds, required this.onSelected});

  final List<String> mediaIds;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (mediaIds.isEmpty) {
      return const Center(child: Text('No saved GIFs'));
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
            child: MediaThumbnail(mediaIds[index], label: 'GIF'),
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
                            ? 'Editing message'
                            : contextMessage!.body ?? 'Attachment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onCancelContext,
                      tooltip: 'Cancel',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    enabled: !busy && !editing,
                    tooltip: 'Attach',
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onSelected: (value) {
                      if (value == 'file') onAttach();
                      if (value == 'poll') onPoll();
                      if (value == 'stickers') onStickers();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'file',
                        child: ListTile(
                          leading: Icon(Icons.attach_file_rounded),
                          title: Text('Photo, video or file'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'poll',
                        child: ListTile(
                          leading: Icon(Icons.poll_outlined),
                          title: Text('Poll'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'stickers',
                        child: ListTile(
                          leading: Icon(Icons.emoji_emotions_outlined),
                          title: Text('Emoji, stickers and GIFs'),
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
