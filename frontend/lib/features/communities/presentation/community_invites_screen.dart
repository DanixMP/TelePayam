import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';

class CommunityInvitesScreen extends ConsumerStatefulWidget {
  const CommunityInvitesScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<CommunityInvitesScreen> createState() =>
      _CommunityInvitesScreenState();
}

class _CommunityInvitesScreenState
    extends ConsumerState<CommunityInvitesScreen> {
  List<CommunityInvite>? _invites;
  Object? _error;
  var _loading = true;
  var _creating = false;
  final Set<String> _revoking = {};

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
      final invites = await ref
          .read(communityApiProvider)
          .listInvites(widget.conversationId);
      if (mounted) setState(() => _invites = invites);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final options = await showDialog<_InviteOptions>(
      context: context,
      builder: (_) => const _CreateInviteDialog(),
    );
    if (options == null || !mounted) return;
    setState(() => _creating = true);
    try {
      final invite = await ref
          .read(communityApiProvider)
          .createInvite(
            conversationId: widget.conversationId,
            expiresInHours: options.expiresInHours,
            maxUses: options.maxUses,
          );
      if (!mounted) return;
      await _showToken(invite.token!);
      await _load();
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showToken(String token) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Invite link created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this token now. It will not be shown again.'),
            const SizedBox(height: 16),
            SelectableText(
              token,
              style: Theme.of(context).textTheme.bodyLarge,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (context.mounted) {
                showCommunityMessage(context, 'Invite token copied.');
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(CommunityInvite invite) async {
    final confirmed = await confirmCommunityAction(
      context,
      title: 'Revoke invite?',
      body: 'This invite will stop working immediately.',
      confirmLabel: 'Revoke',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _revoking.add(invite.id));
    try {
      await ref
          .read(communityApiProvider)
          .revokeInvite(
            conversationId: widget.conversationId,
            inviteId: invite.id,
          );
      if (!mounted) return;
      showCommunityMessage(context, 'Invite revoked.');
      await _load();
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _revoking.remove(invite.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Invite links'),
      actions: [
        IconButton(
          tooltip: 'Create invite',
          onPressed: _creating ? null : _create,
          icon: const Icon(Icons.add_link_rounded),
        ),
      ],
      bottom: _loading
          ? const PreferredSize(
              preferredSize: Size.fromHeight(2),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : null,
    ),
    body: CommunityContent(child: _buildBody()),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _creating ? null : _create,
      icon: _creating
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_link_rounded),
      label: const Text('Create invite'),
    ),
  );

  Widget _buildBody() {
    if (_loading && _invites == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _invites == null) {
      return CommunityStateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load invites',
        body: communityErrorText(_error!),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    final invites = _invites ?? const <CommunityInvite>[];
    if (invites.isEmpty) {
      return const CommunityStateMessage(
        icon: Icons.link_off_rounded,
        title: 'No invite links',
        body: 'Create a limited invite for this community.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 96),
        itemCount: invites.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final invite = invites[index];
          final active =
              !invite.isRevoked && !invite.isExpired && !invite.isExhausted;
          final revoking = _revoking.contains(invite.id);
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  active ? Icons.link_rounded : Icons.link_off_rounded,
                ),
              ),
              title: Text(active ? 'Active invite' : _inactiveLabel(invite)),
              subtitle: Text(_inviteDetails(context, invite)),
              isThreeLine: true,
              trailing: active
                  ? revoking
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: 'Revoke invite',
                            onPressed: () => _revoke(invite),
                            icon: const Icon(Icons.link_off_rounded),
                          )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _InviteOptions {
  const _InviteOptions({required this.expiresInHours, required this.maxUses});

  final int? expiresInHours;
  final int? maxUses;
}

class _CreateInviteDialog extends StatefulWidget {
  const _CreateInviteDialog();

  @override
  State<_CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<_CreateInviteDialog> {
  final _usesController = TextEditingController();
  int? _expiresInHours = 168;
  String? _usesError;

  @override
  void dispose() {
    _usesController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _usesController.text.trim();
    final uses = text.isEmpty ? null : int.tryParse(text);
    if (uses != null && (uses < 1 || uses > 10000) ||
        text.isNotEmpty && uses == null) {
      setState(() => _usesError = 'Enter a number from 1 to 10000.');
      return;
    }
    Navigator.pop(
      context,
      _InviteOptions(expiresInHours: _expiresInHours, maxUses: uses),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create invite link'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _expiresInHours,
          decoration: const InputDecoration(labelText: 'Expires after'),
          items: const [
            DropdownMenuItem(value: 24, child: Text('24 hours')),
            DropdownMenuItem(value: 168, child: Text('7 days')),
            DropdownMenuItem(value: 720, child: Text('30 days')),
            DropdownMenuItem(value: null, child: Text('Never')),
          ],
          onChanged: (value) => setState(() => _expiresInHours = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usesController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Maximum uses (optional)',
            errorText: _usesError,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Create')),
    ],
  );
}

String _inactiveLabel(CommunityInvite invite) {
  if (invite.isRevoked) return 'Revoked invite';
  if (invite.isExpired) return 'Expired invite';
  return 'Used invite';
}

String _inviteDetails(BuildContext context, CommunityInvite invite) {
  final uses = invite.maxUses == null
      ? '${invite.uses} uses'
      : '${invite.uses} of ${invite.maxUses} uses';
  final expiry = invite.expiresAt == null
      ? 'No expiry'
      : 'Expires ${MaterialLocalizations.of(context).formatMediumDate(invite.expiresAt!.toLocal())}';
  return '$uses\n$expiry';
}
