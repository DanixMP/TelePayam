import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/admin/admin_screen.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/calls/calls_feature.dart';
import 'package:university_messenger/features/chats/presentation/chat_list_pane.dart';
import 'package:university_messenger/features/chats/presentation/chat_screen.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({this.selectedConversationId, super.key});

  final String? selectedConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(chatInitializationProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    if (!isWide && selectedConversationId != null) {
      return ChatScreen(conversationId: selectedConversationId!);
    }

    final role = ref.watch(authControllerProvider).state.account?.role;
    return Scaffold(
      drawer: _HomeDrawer(role: role),
      floatingActionButton:
          role == UserRole.student && selectedConversationId == null
          ? FloatingActionButton(
              onPressed: () =>
                  context.push('/home/communities/create?kind=group'),
              tooltip: 'Create group',
              child: const Icon(Icons.add_comment_outlined),
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: isWide ? 390 : width,
              child: Builder(
                builder: (paneContext) => ChatListPane(
                  selectedConversationId: selectedConversationId,
                  onMenu: () => Scaffold.of(paneContext).openDrawer(),
                  onSelected: (id) => isWide
                      ? context.go('/home/chat/$id')
                      : context.push('/home/chat/$id'),
                ),
              ),
            ),
            if (isWide) ...[
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: selectedConversationId == null
                    ? _EmptySelection(
                        hasSyncError: initialization.hasError,
                        onRetry: () =>
                            ref.invalidate(chatInitializationProvider),
                      )
                    : ChatScreen(
                        conversationId: selectedConversationId!,
                        embedded: true,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    void open(String location) {
      Navigator.pop(context);
      context.push(location);
    }

    return NavigationDrawer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
          child: Text(
            context.l10n.appTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline_rounded),
          title: Text(context.l10n.chats),
          onTap: () {
            Navigator.pop(context);
            context.go('/home');
          },
        ),
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(context.l10n.myProfile),
          onTap: () => open('/home/profile'),
        ),
        if (role?.canChat == true)
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(context.l10n.findById),
            onTap: () => open('/home/find'),
          ),
        ListTile(
          leading: const Icon(Icons.explore_outlined),
          title: const Text('Discover communities'),
          onTap: () => open('/home/communities'),
        ),
        if (role == UserRole.student || role == UserRole.professor)
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: Text(
              role == UserRole.student
                  ? 'Create group or channel'
                  : 'Create channel',
            ),
            onTap: () => open('/home/communities/create'),
          ),
        if (role == UserRole.student || role == UserRole.staff)
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('University services'),
            onTap: () => open('/home/services'),
          ),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('My reports'),
          onTap: () => open('/home/reports'),
        ),
        if (role?.isAdmin == true)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: Text(context.l10n.adminPanel),
            onTap: () => open(AdminScreen.path),
          ),
        if (role == UserRole.moderator)
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Moderation queue'),
            onTap: () => open('/home/moderation'),
          ),
        ListTile(
          leading: const Icon(Icons.call_outlined),
          title: const Text('Call history'),
          onTap: () => open(CallRoutes.history),
        ),
      ],
    );
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection({required this.hasSyncError, required this.onRetry});

  final bool hasSyncError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSyncError ? Icons.cloud_off_rounded : Icons.forum_outlined,
                size: 62,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                hasSyncError
                    ? context.l10n.syncError
                    : context.l10n.selectConversation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (hasSyncError) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
