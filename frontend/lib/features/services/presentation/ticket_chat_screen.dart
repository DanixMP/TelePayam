import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/authenticated_media.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';
import 'package:university_messenger/features/services/presentation/service_strings.dart';
import 'package:university_messenger/features/services/presentation/service_widgets.dart';
import 'package:university_messenger/features/services/services_providers.dart';

class TicketChatScreen extends ConsumerStatefulWidget {
  const TicketChatScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  String? _attachmentId;
  var _sending = false;
  var _lastMessageCount = 0;

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final body = _message.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(servicesApiProvider)
          .sendMessage(
            widget.requestId,
            body: body,
            attachmentId: _attachmentId,
          );
      _message.clear();
      setState(() => _attachmentId = null);
      ref.invalidate(ticketMessagesProvider(widget.requestId));
      await ref.read(ticketMessagesProvider(widget.requestId).future);
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(serviceErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _chooseAttachment() async {
    final file = await openFile();
    if (file == null) return;
    setState(() => _sending = true);
    try {
      final media = await ref.read(mediaClientProvider).upload(file);
      if (mounted) setState(() => _attachmentId = media.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(serviceErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(serviceRealtimeSyncProvider);
    final messages = ref.watch(ticketMessagesProvider(widget.requestId));
    final accountId = ref.watch(authControllerProvider).state.account?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text(ServiceStrings.ticketChat),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(ticketMessagesProvider(widget.requestId)),
            tooltip: ServiceStrings.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: messages.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ServiceErrorState(
                    title: ServiceStrings.loadMessagesError,
                    error: error,
                    onRetry: () => ref.invalidate(
                      ticketMessagesProvider(widget.requestId),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const ServiceEmptyState(
                        icon: Icons.forum_outlined,
                        title: ServiceStrings.noMessages,
                        body: ServiceStrings.noMessagesBody,
                      );
                    }
                    if (_lastMessageCount != items.length) {
                      _lastMessageCount = items.length;
                      _scrollToBottom();
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(
                        ticketMessagesProvider(widget.requestId).future,
                      ),
                      child: ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          14,
                          18,
                          14,
                          18,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final previous = index == 0 ? null : items[index - 1];
                          final showDate =
                              previous == null ||
                              !DateUtils.isSameDay(
                                previous.createdAt,
                                item.createdAt,
                              );
                          return Column(
                            children: [
                              if (showDate)
                                _DateLabel(date: item.createdAt.toLocal()),
                              _TicketBubble(
                                message: item,
                                mine: item.senderId == accountId,
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_attachmentId != null)
              Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.attach_file_rounded),
                  title: const Text(ServiceStrings.attachedMedia),
                  subtitle: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(_attachmentId!),
                  ),
                  trailing: IconButton(
                    onPressed: () => setState(() => _attachmentId = null),
                    tooltip: ServiceStrings.removeAttachment,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            _TicketComposer(
              controller: _message,
              sending: _sending,
              onAttach: _chooseAttachment,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      MaterialLocalizations.of(context).formatMediumDate(date),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _TicketBubble extends StatelessWidget {
  const _TicketBubble({required this.message, required this.mine});

  final TicketMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tailOnLeft = mine ? rtl : !rtl;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: math.min(560, MediaQuery.sizeOf(context).width * 0.76),
        ),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsetsDirectional.fromSTEB(13, 10, 10, 7),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(tailOnLeft ? 4 : 16),
            bottomRight: Radius.circular(tailOnLeft ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: _textDirection(message.body),
              child: Text(message.body),
            ),
            if (message.attachmentId != null) ...[
              const SizedBox(height: 8),
              AuthenticatedMediaTile(
                mediaId: message.attachmentId!,
                compact: true,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(message.createdAt.toLocal()),
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketComposer extends StatelessWidget {
  const _TicketComposer({
    required this.controller,
    required this.sending,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: sending ? null : onAttach,
              tooltip: ServiceStrings.addAttachment,
              icon: const Icon(Icons.attach_file_rounded),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 6,
                maxLength: 10000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: ServiceStrings.messageHint,
                  counterText: '',
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              tooltip: ServiceStrings.send,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AttachmentDialog extends StatefulWidget {
  const _AttachmentDialog();

  @override
  State<_AttachmentDialog> createState() => _AttachmentDialogState();
}

class _AttachmentDialogState extends State<_AttachmentDialog> {
  final _key = GlobalKey<FormState>();
  final _mediaId = TextEditingController();

  @override
  void dispose() {
    _mediaId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(ServiceStrings.addAttachment),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(ServiceStrings.attachmentHelp),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _mediaId,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: ServiceStrings.attachmentMediaId,
                ),
                validator: (value) =>
                    isUuid(value ?? '') ? null : ServiceStrings.invalidMediaId,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(ServiceStrings.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (_key.currentState?.validate() != true) return;
          Navigator.pop(context, _mediaId.text.trim());
        },
        child: const Text(ServiceStrings.addAttachment),
      ),
    ],
  );
}

TextDirection _textDirection(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value)
    ? TextDirection.rtl
    : TextDirection.ltr;
