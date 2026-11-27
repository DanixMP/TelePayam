import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/core/utils/validators.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

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
      if (mounted) {
        showCommunityMessage(context, communityErrorText(context, error));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showToken(String token) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.communityInviteCreated),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.communityCopyInviteHelp),
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
                showCommunityMessage(
                  context,
                  context.l10n.communityInviteCopied,
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(context.l10n.copy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.done),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(CommunityInvite invite) async {
    final l10n = context.l10n;
    final confirmed = await confirmCommunityAction(
      context,
      title: l10n.communityRevokeInviteTitle,
      body: l10n.communityRevokeInviteBody,
      confirmLabel: l10n.communityRevokeInvite,
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
      showCommunityMessage(context, context.l10n.communityInviteRevoked);
      await _load();
    } catch (error) {
      if (mounted) {
        showCommunityMessage(context, communityErrorText(context, error));
      }
    } finally {
      if (mounted) setState(() => _revoking.remove(invite.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.communityInviteLinks),
      actions: [
        IconButton(
          tooltip: context.l10n.communityCreateInvite,
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
      label: Text(context.l10n.communityCreateInvite),
    ),
  );

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading && _invites == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _invites == null) {
      return CommunityStateMessage(
        icon: Icons.cloud_off_rounded,
        title: l10n.communityLoadInvitesError,
        body: communityErrorText(context, _error),
        actionLabel: l10n.tryAgain,
        onAction: _load,
      );
    }
    final invites = _invites ?? const <CommunityInvite>[];
    if (invites.isEmpty) {
      return CommunityStateMessage(
        icon: Icons.link_off_rounded,
        title: l10n.communityNoInvites,
        body: l10n.communityNoInvitesBody,
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
              title: Text(_inviteStatus(context, invite)),
              subtitle: Text(_inviteDetails(context, invite)),
              isThreeLine: true,
              trailing: active
                  ? revoking
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: l10n.communityRevokeInvite,
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
  bool _usesInvalid = false;

  @override
  void dispose() {
    _usesController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _usesController.text.trim();
    final uses = text.isEmpty ? null : int.tryParse(asciiDigits(text));
    if (uses != null && (uses < 1 || uses > 10000) ||
        text.isNotEmpty && uses == null) {
      setState(() => _usesInvalid = true);
      return;
    }
    Navigator.pop(
      context,
      _InviteOptions(expiresInHours: _expiresInHours, maxUses: uses),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.communityCreateInvite),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _expiresInHours,
          decoration: InputDecoration(
            labelText: context.l10n.communityExpiresAfter,
          ),
          items: [
            DropdownMenuItem(
              value: 24,
              child: Text(context.l10n.communityExpiryOneDay),
            ),
            DropdownMenuItem(
              value: 168,
              child: Text(context.l10n.communityExpiryOneWeek),
            ),
            DropdownMenuItem(
              value: 720,
              child: Text(context.l10n.communityExpiryThirtyDays),
            ),
            DropdownMenuItem(
              value: null,
              child: Text(context.l10n.communityNeverExpires),
            ),
          ],
          onChanged: (value) => setState(() => _expiresInHours = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usesController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.communityMaxUses,
            errorText: _usesInvalid
                ? context.l10n.communityMaxUsesInvalid
                : null,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(onPressed: _submit, child: Text(context.l10n.create)),
    ],
  );
}

String _inviteStatus(BuildContext context, CommunityInvite invite) {
  final l10n = context.l10n;
  if (invite.isRevoked) return l10n.communityRevokedInvite;
  if (invite.isExpired) return l10n.communityExpiredInvite;
  if (invite.isExhausted) return l10n.communityUsedInvite;
  return l10n.communityActiveInvite;
}

String _inviteDetails(BuildContext context, CommunityInvite invite) {
  final l10n = context.l10n;
  final maxUses = invite.maxUses;
  final expiresAt = invite.expiresAt;
  final uses = maxUses == null
      ? l10n.communityInviteUses(invite.uses)
      : l10n.communityInviteUsesOf(invite.uses, maxUses);
  final expiry = expiresAt == null
      ? l10n.communityNeverExpires
      : l10n.communityInviteExpires(
          MaterialLocalizations.of(
            context,
          ).formatMediumDate(expiresAt.toLocal()),
        );
  return '$uses\n$expiry';
}
