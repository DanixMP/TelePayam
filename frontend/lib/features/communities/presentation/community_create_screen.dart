import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

enum CommunityCreationKind { group, channel }

class CommunityCreateScreen extends ConsumerStatefulWidget {
  const CommunityCreateScreen({
    this.initialKind = CommunityCreationKind.channel,
    this.onCreated,
    super.key,
  });

  final CommunityCreationKind initialKind;
  final ValueChanged<CommunityConversation>? onCreated;

  @override
  ConsumerState<CommunityCreateScreen> createState() =>
      _CommunityCreateScreenState();
}

class _CommunityCreateScreenState extends ConsumerState<CommunityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _handleController = TextEditingController();
  late CommunityCreationKind _kind = widget.initialKind;
  var _visibility = CommunityVisibility.public;
  var _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(communityApiProvider);
      final conversation = _kind == CommunityCreationKind.group
          ? await api.createGroup(
              title: _titleController.text,
              description: _descriptionController.text,
              visibility: _visibility,
              handle: _handleController.text,
            )
          : await api.createChannel(
              title: _titleController.text,
              description: _descriptionController.text,
              visibility: _visibility,
              handle: _handleController.text,
            );
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (!mounted) return;
      widget.onCreated?.call(conversation);
      Navigator.pop(context, conversation);
    } catch (error) {
      if (mounted) {
        showCommunityMessage(context, communityErrorText(context, error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = ref.watch(authControllerProvider).state.account?.role;
    final canCreateChannel =
        role == UserRole.student || role == UserRole.professor;
    final canCreateGroup = role == UserRole.student;
    if (_kind == CommunityCreationKind.group && !canCreateGroup) {
      return Scaffold(
        body: SafeArea(
          child: CommunityStateMessage(
            icon: Icons.lock_outline_rounded,
            title: l10n.communityGroupsUnavailable,
            body: l10n.communityGroupsUnavailableBody,
          ),
        ),
      );
    }
    if (!canCreateChannel) {
      return Scaffold(
        body: SafeArea(
          child: CommunityStateMessage(
            icon: Icons.lock_outline_rounded,
            title: l10n.communityChannelsUnavailable,
            body: l10n.communityChannelsUnavailableBody,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _kind == CommunityCreationKind.group
              ? l10n.communityCreateStudentGroup
              : l10n.createChannel,
        ),
      ),
      body: CommunityContent(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
            children: [
              if (canCreateGroup)
                SegmentedButton<CommunityCreationKind>(
                  segments: [
                    ButtonSegment(
                      value: CommunityCreationKind.group,
                      icon: const Icon(Icons.groups_rounded),
                      label: Text(l10n.communityStudentGroup),
                    ),
                    ButtonSegment(
                      value: CommunityCreationKind.channel,
                      icon: const Icon(Icons.campaign_rounded),
                      label: Text(l10n.channel),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (selection) =>
                      setState(() => _kind = selection.first),
                ),
              if (canCreateGroup) const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                maxLength: 180,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.enterName
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.descriptionOptional,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<CommunityVisibility>(
                initialValue: _visibility,
                decoration: InputDecoration(
                  labelText: l10n.visibility,
                  prefixIcon: const Icon(Icons.visibility_rounded),
                ),
                items: [
                  DropdownMenuItem(
                    value: CommunityVisibility.public,
                    child: Text(l10n.publicVisibility),
                  ),
                  DropdownMenuItem(
                    value: CommunityVisibility.private,
                    child: Text(l10n.privateVisibility),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _visibility = value ?? _visibility),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _handleController,
                maxLength: 32,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: _visibility == CommunityVisibility.public
                      ? l10n.username
                      : l10n.handleOptional,
                  prefixText: '@',
                  helperText: _visibility == CommunityVisibility.public
                      ? l10n.communityHandleRequired
                      : null,
                ),
                validator: (value) {
                  final handle = value?.trim() ?? '';
                  if (_visibility == CommunityVisibility.public &&
                      handle.isEmpty) {
                    return l10n.communityHandleRequired;
                  }
                  return null;
                },
              ),
              if (_kind == CommunityCreationKind.channel &&
                  role == UserRole.professor) ...[
                const SizedBox(height: 4),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.verified_rounded),
                    title: Text(l10n.communityProfessorChannel),
                    subtitle: Text(l10n.communityProfessorChannelHelp),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _kind == CommunityCreationKind.group
                      ? l10n.createGroup
                      : l10n.createChannel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
