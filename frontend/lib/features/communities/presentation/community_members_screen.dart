import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class CommunityMembersScreen extends ConsumerStatefulWidget {
  const CommunityMembersScreen({required this.conversation, super.key});

  final CommunityConversation conversation;

  @override
  ConsumerState<CommunityMembersScreen> createState() =>
      _CommunityMembersScreenState();
}

enum _MemberAction { promote, demote, ban, remove }

class _CommunityMembersScreenState
    extends ConsumerState<CommunityMembersScreen> {
  List<CommunityMember>? _members;
  Object? _error;
  var _loading = true;
  final Set<String> _mutating = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await ref
          .read(communityApiProvider)
          .listMembers(widget.conversation.id);
      if (mounted) setState(() => _members = members);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_MemberAction> _actionsFor(CommunityMember member) {
    final accountId = ref.read(authControllerProvider).state.account?.id;
    final actorRole = widget.conversation.myRole;
    if (!widget.conversation.canManage ||
        member.user.id == accountId ||
        member.role == CommunityMemberRole.owner ||
        (actorRole != CommunityMemberRole.owner &&
            member.role == CommunityMemberRole.admin)) {
      return const [];
    }
    return [
      if (actorRole == CommunityMemberRole.owner &&
          member.role != CommunityMemberRole.admin)
        _MemberAction.promote,
      if (member.role == CommunityMemberRole.admin) _MemberAction.demote,
      _MemberAction.ban,
      _MemberAction.remove,
    ];
  }

  Future<void> _perform(CommunityMember member, _MemberAction action) async {
    if (action == _MemberAction.ban || action == _MemberAction.remove) {
      final l10n = context.l10n;
      final banning = action == _MemberAction.ban;
      final name = member.user.displayName;
      final confirmed = await confirmCommunityAction(
        context,
        title: banning
            ? l10n.communityBanMemberTitle(name)
            : l10n.communityRemoveMemberTitle(name),
        body: banning
            ? l10n.communityBanMemberBody
            : l10n.communityRemoveMemberBody,
        confirmLabel: banning ? l10n.ban : l10n.remove,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _mutating.add(member.user.id));
    try {
      final api = ref.read(communityApiProvider);
      if (action == _MemberAction.remove) {
        await api.removeMember(
          conversationId: widget.conversation.id,
          memberId: member.user.id,
        );
      } else {
        final role = switch (action) {
          _MemberAction.promote => CommunityMemberRole.admin,
          _MemberAction.demote =>
            widget.conversation.type == CommunityType.channel
                ? CommunityMemberRole.subscriber
                : CommunityMemberRole.member,
          _MemberAction.ban => CommunityMemberRole.banned,
          _MemberAction.remove => throw StateError('Handled above'),
        };
        await api.updateMember(
          conversationId: widget.conversation.id,
          memberId: member.user.id,
          role: role,
        );
      }
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (!mounted) return;
      final l10n = context.l10n;
      showCommunityMessage(context, switch (action) {
        _MemberAction.promote => l10n.communityMemberPromoted,
        _MemberAction.demote => l10n.communityMemberDemoted,
        _MemberAction.ban => l10n.communityMemberBanned,
        _MemberAction.remove => l10n.communityMemberRemoved,
      });
      await _load();
    } catch (error) {
      if (mounted) {
        showCommunityMessage(context, communityErrorText(context, error));
      }
    } finally {
      if (mounted) setState(() => _mutating.remove(member.user.id));
    }
  }

  Future<void> _addMember() async {
    final controller = TextEditingController();
    final handle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.communityAddMember),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: context.l10n.username,
            prefixText: '@',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || handle == null || handle.isEmpty) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(communityApiProvider);
      final user = await api.resolveUser(handle);
      await api.addMember(
        conversationId: widget.conversation.id,
        userId: user.id,
        role: CommunityMemberRole.member,
      );
      await _load();
      if (mounted) {
        showCommunityMessage(
          context,
          context.l10n.communityMemberAdded(user.displayName),
        );
      }
    } catch (error) {
      if (mounted) {
        showCommunityMessage(context, communityErrorText(context, error));
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.members),
      actions: [
        if (widget.conversation.canManage)
          IconButton(
            tooltip: context.l10n.communityAddMember,
            onPressed: _loading ? null : _addMember,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        IconButton(
          tooltip: context.l10n.refresh,
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: CommunityContent(child: _buildBody()),
  );

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading && _members == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _members == null) {
      return CommunityStateMessage(
        icon: Icons.cloud_off_rounded,
        title: l10n.communityLoadMembersError,
        body: communityErrorText(context, _error),
        actionLabel: l10n.tryAgain,
        onAction: _load,
      );
    }
    final members = _members ?? const <CommunityMember>[];
    if (members.isEmpty) {
      return CommunityStateMessage(
        icon: Icons.group_off_outlined,
        title: l10n.communityNoMembers,
        body: l10n.communityNoMembersBody,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 24),
        itemCount: members.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final member = members[index];
          final actions = _actionsFor(member);
          final mutating = _mutating.contains(member.user.id);
          return ListTile(
            minTileHeight: 72,
            leading: CircleAvatar(
              child: Text(
                member.user.displayName.characters.first.toUpperCase(),
              ),
            ),
            title: Text(
              member.user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_roleLabel(l10n, member.role)),
            trailing: mutating
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : actions.isEmpty
                ? null
                : PopupMenuButton<_MemberAction>(
                    tooltip: l10n.communityManageMember,
                    onSelected: (action) => _perform(member, action),
                    itemBuilder: (context) => actions
                        .map(
                          (action) => PopupMenuItem(
                            value: action,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(_actionIcon(action)),
                              title: Text(_actionLabel(context.l10n, action)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          );
        },
      ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, CommunityMemberRole role) =>
    switch (role) {
      CommunityMemberRole.owner => l10n.communityOwnerRole,
      CommunityMemberRole.admin => l10n.communityAdminRole,
      CommunityMemberRole.member => l10n.communityMemberRole,
      CommunityMemberRole.subscriber => l10n.communitySubscriberRole,
      CommunityMemberRole.banned => l10n.communityBannedRole,
    };

String _actionLabel(AppLocalizations l10n, _MemberAction action) =>
    switch (action) {
      _MemberAction.promote => l10n.communityPromoteMember,
      _MemberAction.demote => l10n.communityDemoteMember,
      _MemberAction.ban => l10n.communityBanMember,
      _MemberAction.remove => l10n.communityRemoveMember,
    };

IconData _actionIcon(_MemberAction action) => switch (action) {
  _MemberAction.promote => Icons.admin_panel_settings_outlined,
  _MemberAction.demote => Icons.person_outline_rounded,
  _MemberAction.ban => Icons.block_rounded,
  _MemberAction.remove => Icons.person_remove_outlined,
};
