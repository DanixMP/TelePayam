import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';

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
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authControllerProvider).state.account?.role;
    final canCreateChannel =
        role == UserRole.student || role == UserRole.professor;
    final canCreateGroup = role == UserRole.student;
    if (_kind == CommunityCreationKind.group && !canCreateGroup) {
      return const Scaffold(
        body: SafeArea(
          child: CommunityStateMessage(
            icon: Icons.lock_outline_rounded,
            title: 'Student groups are unavailable',
            body: 'Only student accounts can create student groups.',
          ),
        ),
      );
    }
    if (!canCreateChannel) {
      return const Scaffold(
        body: SafeArea(
          child: CommunityStateMessage(
            icon: Icons.lock_outline_rounded,
            title: 'Channel creation is unavailable',
            body: 'Only student and professor accounts can create channels.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _kind == CommunityCreationKind.group
              ? 'Create student group'
              : 'Create channel',
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
                  segments: const [
                    ButtonSegment(
                      value: CommunityCreationKind.group,
                      icon: Icon(Icons.groups_rounded),
                      label: Text('Student group'),
                    ),
                    ButtonSegment(
                      value: CommunityCreationKind.channel,
                      icon: Icon(Icons.campaign_rounded),
                      label: Text('Channel'),
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
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<CommunityVisibility>(
                initialValue: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  prefixIcon: Icon(Icons.visibility_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: CommunityVisibility.public,
                    child: Text('Public'),
                  ),
                  DropdownMenuItem(
                    value: CommunityVisibility.private,
                    child: Text('Private'),
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
                      ? 'Handle'
                      : 'Handle (optional)',
                  prefixText: '@',
                  helperText: _visibility == CommunityVisibility.public
                      ? 'A handle is required for public communities.'
                      : null,
                ),
                validator: (value) {
                  final handle = value?.trim() ?? '';
                  if (_visibility == CommunityVisibility.public &&
                      handle.isEmpty) {
                    return 'Enter a handle.';
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
                  child: const ListTile(
                    leading: Icon(Icons.verified_rounded),
                    title: Text('Professor channel'),
                    subtitle: Text(
                      'This channel will appear in professor channel discovery.',
                    ),
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
                      ? 'Create group'
                      : 'Create channel',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
