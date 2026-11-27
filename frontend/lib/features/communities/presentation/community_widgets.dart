import 'package:flutter/material.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class CommunityContent extends StatelessWidget {
  const CommunityContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: child,
    ),
  );
}

class CommunityStateMessage extends StatelessWidget {
  const CommunityStateMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    required this.conversation,
    this.radius = 24,
    super.key,
  });

  final CommunityConversation conversation;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: conversation.isProfessorChannel
          ? scheme.tertiaryContainer
          : scheme.primaryContainer,
      foregroundColor: conversation.isProfessorChannel
          ? scheme.onTertiaryContainer
          : scheme.onPrimaryContainer,
      child: Icon(
        conversation.isProfessorChannel
            ? Icons.school_rounded
            : conversation.type == CommunityType.group
            ? Icons.groups_rounded
            : Icons.campaign_rounded,
      ),
    );
  }
}

String communityErrorText(BuildContext context, Object? error) {
  final l10n = context.l10n;
  final code = error is CommunityRequestException ? error.code : null;
  return switch (code) {
    'invalid_handle' => l10n.communityInvalidHandle,
    'handle_taken' => l10n.communityHandleTaken,
    'handle_required' => l10n.communityHandleRequired,
    'invalid_group_member' => l10n.communityInvalidGroupMember,
    'member_banned' => l10n.communityRejoinDenied,
    'conversation_not_found' => l10n.communityMissing,
    'invite_not_found' => l10n.communityInviteInvalid,
    'user_not_found' || 'handle_not_found' => l10n.communityUserMissing,
    'already_member' => l10n.communityAlreadyMember,
    'owner_cannot_leave' => l10n.communityOwnerCannotLeave,
    'member_not_found' => l10n.communityMemberMissing,
    'invalid_member_role' => l10n.communityInvalidMemberRole,
    'conversation_not_editable' ||
    'cannot_leave_dm' => l10n.communityDmUnavailable,
    _ => localizedApiError(l10n, code),
  };
}

String communityTitle(
  BuildContext context,
  CommunityConversation conversation,
) {
  if (conversation.title.isNotEmpty) return conversation.title;
  return conversation.handle ??
      (conversation.type == CommunityType.group
          ? context.l10n.group
          : context.l10n.channel);
}

String? communityDescription(
  BuildContext context,
  CommunityConversation conversation,
) {
  final name = conversation.officialDescriptionName;
  return name == null
      ? conversation.description
      : context.l10n.communityOfficialDescription(name);
}

Future<bool> confirmCommunityAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          destructive
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                )
              : FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
        ],
      ),
    ) ??
    false;

void showCommunityMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
