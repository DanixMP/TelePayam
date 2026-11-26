import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_edit_screen.dart';
import 'package:university_messenger/features/communities/presentation/community_invites_screen.dart';
import 'package:university_messenger/features/communities/presentation/community_members_screen.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';
import 'package:university_messenger/features/reports/reports.dart';

class CommunityInfoScreen extends ConsumerStatefulWidget {
  const CommunityInfoScreen({
    required this.conversationId,
    this.initialConversation,
    this.onOpenConversation,
    super.key,
  });

  final String conversationId;
  final CommunityConversation? initialConversation;
  final ValueChanged<String>? onOpenConversation;

  @override
  ConsumerState<CommunityInfoScreen> createState() =>
      _CommunityInfoScreenState();
}

class _CommunityInfoScreenState extends ConsumerState<CommunityInfoScreen> {
  CommunityConversation? _conversation;
  Object? _error;
  var _loading = false;
  var _mutating = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.initialConversation;
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversation = await ref
          .read(communityApiProvider)
          .getConversation(widget.conversationId);
      if (mounted) setState(() => _conversation = conversation);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() => _mutating = true);
    try {
      final conversation = await ref
          .read(communityApiProvider)
          .join(widget.conversationId);
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (!mounted) return;
      setState(() => _conversation = conversation);
      showCommunityMessage(context, 'Joined ${conversation.title}.');
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _leave() async {
    final conversation = _conversation!;
    final confirmed = await confirmCommunityAction(
      context,
      title: 'Leave ${conversation.title}?',
      body: 'You will need to join again to see new messages.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _mutating = true);
    try {
      await ref.read(communityApiProvider).leave(conversation.id);
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _delete() async {
    final conversation = _conversation!;
    final confirmed = await confirmCommunityAction(
      context,
      title: 'Delete ${conversation.title}?',
      body: 'This permanently deletes the community and its conversation.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _mutating = true);
    try {
      await ref.read(communityApiProvider).delete(conversation.id);
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<CommunityConversation>(
      MaterialPageRoute<CommunityConversation>(
        builder: (_) => CommunityEditScreen(conversation: _conversation!),
      ),
    );
    if (updated != null && mounted) setState(() => _conversation = updated);
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community info'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: conversation == null
          ? _buildMissingContent()
          : CommunityContent(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        20,
                        16,
                        36,
                      ),
                      children: [
                        _CommunityHeader(conversation: conversation),
                        if (conversation.underReview) ...[
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: const ListTile(
                              leading: Icon(Icons.policy_rounded),
                              title: Text('Conversation under review'),
                              subtitle: Text(
                                'Some actions may be limited while a report is reviewed.',
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _primaryAction(conversation),
                        const SizedBox(height: 24),
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.people_outline_rounded,
                                ),
                                title: const Text('Members'),
                                trailing: Text('${conversation.memberCount}'),
                                onTap: conversation.isMember
                                    ? () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              CommunityMembersScreen(
                                                conversation: conversation,
                                              ),
                                        ),
                                      )
                                    : null,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: Icon(
                                  conversation.visibility ==
                                          CommunityVisibility.public
                                      ? Icons.public_rounded
                                      : Icons.lock_outline_rounded,
                                ),
                                title: const Text('Visibility'),
                                trailing: Text(
                                  conversation.visibility ==
                                          CommunityVisibility.public
                                      ? 'Public'
                                      : 'Private',
                                ),
                              ),
                              if (conversation.handle != null) ...[
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(
                                    Icons.alternate_email_rounded,
                                  ),
                                  title: const Text('Handle'),
                                  trailing: Text('@${conversation.handle}'),
                                ),
                              ],
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.calendar_today_rounded,
                                ),
                                title: const Text('Created'),
                                trailing: Text(
                                  MaterialLocalizations.of(
                                    context,
                                  ).formatMediumDate(
                                    conversation.createdAt.toLocal(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (conversation.canManage) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Manage',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: const Text('Metadata and settings'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: _openEdit,
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.link_rounded),
                                  title: const Text('Invite links'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CommunityInvitesScreen(
                                        conversationId: conversation.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (conversation.isMember) ...[
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SubmitReportScreen(
                                  target: ReportTargetContext(
                                    type:
                                        conversation.type == CommunityType.group
                                        ? ReportTargetType.group
                                        : ReportTargetType.channel,
                                    targetId: conversation.id,
                                    conversationId: conversation.id,
                                    label: conversation.title,
                                  ),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Report community'),
                          ),
                          const SizedBox(height: 10),
                          if (conversation.isOwner)
                            OutlinedButton.icon(
                              onPressed: _mutating ? null : _delete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete community'),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _mutating ? null : _leave,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Leave community'),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (_loading || _mutating)
                    const Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMissingContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return CommunityStateMessage(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load community',
      body: communityErrorText(_error ?? Exception()),
      actionLabel: 'Try again',
      onAction: _load,
    );
  }

  Widget _primaryAction(CommunityConversation conversation) {
    if (!conversation.isMember) {
      final accountRole = ref.watch(authControllerProvider).state.account?.role;
      final canJoin =
          conversation.type == CommunityType.channel ||
          accountRole == UserRole.student;
      return FilledButton.icon(
        onPressed: canJoin && !_mutating ? _join : null,
        icon: const Icon(Icons.login_rounded),
        label: Text(canJoin ? 'Join community' : 'Unable to join'),
      );
    }
    final open = widget.onOpenConversation;
    if (open == null) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.forum_outlined),
        label: const Text('Conversation route not connected'),
      );
    }
    return FilledButton.icon(
      onPressed: () => open(conversation.id),
      icon: const Icon(Icons.forum_rounded),
      label: const Text('Open conversation'),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.conversation});

  final CommunityConversation conversation;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CommunityAvatar(conversation: conversation, radius: 42),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              conversation.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (conversation.isProfessorChannel) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified_rounded, size: 22),
          ],
        ],
      ),
      if (conversation.handle != null) ...[
        const SizedBox(height: 4),
        Text(
          '@${conversation.handle}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
      if (conversation.description?.isNotEmpty == true) ...[
        const SizedBox(height: 12),
        Text(
          conversation.description!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            avatar: Icon(
              conversation.type == CommunityType.group
                  ? Icons.groups_rounded
                  : Icons.campaign_rounded,
              size: 18,
            ),
            label: Text(
              conversation.type == CommunityType.group ? 'Group' : 'Channel',
            ),
          ),
          if (conversation.isProfessorChannel)
            const Chip(
              avatar: Icon(Icons.school_rounded, size: 18),
              label: Text('Professor'),
            ),
        ],
      ),
    ],
  );
}
