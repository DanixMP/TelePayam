import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/media_thumbnail.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class ChatListPane extends ConsumerStatefulWidget {
  const ChatListPane({
    required this.onSelected,
    this.selectedConversationId,
    this.onMenu,
    super.key,
  });

  final ValueChanged<String> onSelected;
  final String? selectedConversationId;
  final VoidCallback? onMenu;

  @override
  ConsumerState<ChatListPane> createState() => _ChatListPaneState();
}

class _ChatListPaneState extends ConsumerState<ChatListPane> {
  final _searchController = TextEditingController();
  var _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(chatSearchProvider.notifier).state = '';
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final initialization = ref.watch(chatInitializationProvider);
    final account = ref.watch(authControllerProvider).state.account;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _searching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: context.l10n.searchChats,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          onPressed: _closeSearch,
                          icon: const Icon(Icons.close_rounded),
                        ),
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (value) =>
                          ref.read(chatSearchProvider.notifier).state = value,
                    )
                  : Row(
                      children: [
                        IconButton(
                          onPressed: widget.onMenu,
                          tooltip: 'Open navigation',
                          icon: ContactAvatar(
                            id: account?.avatarId,
                            fallback: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                _initials(account?.displayName ?? 'U'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            context.l10n.chats,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _searching = true),
                          tooltip: context.l10n.searchChats,
                          icon: const Icon(Icons.search_rounded),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'logout') {
                              ref.read(authControllerProvider).logout();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'logout',
                              child: Text(context.l10n.logout),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          if (_searching && account?.role.canChat == true)
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text(context.l10n.findById),
              onTap: () => context.push(
                Uri(
                  path: '/home/find',
                  queryParameters: {'q': _searchController.text},
                ).toString(),
              ),
            ),
          if (initialization.hasError)
            MaterialBanner(
              content: Text(context.l10n.syncError),
              leading: const Icon(Icons.cloud_off_rounded),
              actions: [
                TextButton(
                  onPressed: () => ref.invalidate(chatInitializationProvider),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          Expanded(
            child: conversations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ListNotice(
                icon: Icons.cloud_off_rounded,
                title: context.l10n.syncError,
              ),
              data: (items) {
                if (items.isEmpty) {
                  final searching = ref
                      .watch(chatSearchProvider)
                      .trim()
                      .isNotEmpty;
                  return _ListNotice(
                    icon: searching
                        ? Icons.search_off_rounded
                        : Icons.chat_bubble_outline_rounded,
                    title: searching
                        ? context.l10n.noSearchResults
                        : context.l10n.noChats,
                    body: searching ? null : context.l10n.noChatsBody,
                  );
                }
                return RefreshIndicator(
                  onRefresh: ref
                      .read(chatRepositoryProvider)
                      .refreshConversations,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ConversationTile(
                        conversation: item,
                        selected: widget.selectedConversationId == item.id,
                        onTap: () => widget.onSelected(item.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      minVerticalPadding: 8,
      leading: ContactAvatar(
        id: conversation.avatarId,
        radius: 27,
        fallback: CircleAvatar(
          radius: 27,
          backgroundColor: _avatarColor(conversation.id, scheme),
          child: Icon(switch (conversation.type) {
            ConversationType.channel => Icons.campaign_rounded,
            ConversationType.group => Icons.group_rounded,
            ConversationType.dm => Icons.person_rounded,
          }, color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (conversation.isProfessorChannel) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified_rounded, size: 17, color: scheme.primary),
          ],
        ],
      ),
      subtitle: Text(
        conversation.lastMessageBody ?? _typeLabel(context, conversation.type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageAt != null)
              Text(
                _relativeTime(context, conversation.lastMessageAt!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: conversation.unreadCount > 0
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            if (conversation.unreadCount > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ListNotice extends StatelessWidget {
  const _ListNotice({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  return parts
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}

Color _avatarColor(String id, ColorScheme scheme) {
  final palette = [
    scheme.primary,
    const Color(0xFF6A5ACD),
    const Color(0xFF16885A),
    const Color(0xFFB45F06),
  ];
  return palette[id.hashCode.abs() % palette.length];
}

String _typeLabel(BuildContext context, ConversationType type) =>
    switch (type) {
      ConversationType.channel => context.l10n.channel,
      ConversationType.group => context.l10n.group,
      ConversationType.dm => context.l10n.directMessage,
    };

String _relativeTime(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  if (now.difference(local).inMinutes < 1) return context.l10n.justNow;
  if (DateUtils.isSameDay(now, local)) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  if (DateUtils.isSameDay(now.subtract(const Duration(days: 1)), local)) {
    return context.l10n.yesterday;
  }
  return MaterialLocalizations.of(context).formatShortDate(local);
}
