import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';

class CommunityEditScreen extends ConsumerStatefulWidget {
  const CommunityEditScreen({required this.conversation, super.key});

  final CommunityConversation conversation;

  @override
  ConsumerState<CommunityEditScreen> createState() =>
      _CommunityEditScreenState();
}

class _CommunityEditScreenState extends ConsumerState<CommunityEditScreen> {
  final _metadataKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.conversation.title,
  );
  late final _descriptionController = TextEditingController(
    text: widget.conversation.description,
  );
  late final _handleController = TextEditingController(
    text: widget.conversation.handle,
  );
  late final _slowModeController = TextEditingController(
    text: _settingInt('slow_mode_seconds', 0).toString(),
  );
  late var _visibility = widget.conversation.visibility;
  late var _membersCanPost = _settingBool(
    'members_can_post',
    widget.conversation.type == CommunityType.group,
  );
  late var _membersCanInvite = _settingBool('members_can_invite', true);
  late var _commentsEnabled = _settingBool('comments_enabled', true);
  late CommunityConversation _conversation = widget.conversation;
  var _savingMetadata = false;
  var _savingSettings = false;

  bool _settingBool(String key, bool fallback) {
    final value = widget.conversation.settings[key];
    return value is bool ? value : fallback;
  }

  int _settingInt(String key, int fallback) {
    final value = widget.conversation.settings[key];
    return value is num ? value.toInt() : fallback;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _handleController.dispose();
    _slowModeController.dispose();
    super.dispose();
  }

  Future<void> _saveMetadata() async {
    if (!_metadataKey.currentState!.validate()) return;
    setState(() => _savingMetadata = true);
    try {
      final updated = await ref
          .read(communityApiProvider)
          .updateMetadata(
            conversationId: _conversation.id,
            title: _titleController.text,
            description: _descriptionController.text,
            visibility: _visibility,
            handle: _handleController.text,
          );
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (!mounted) return;
      setState(() => _conversation = updated);
      showCommunityMessage(context, 'Community details saved.');
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _savingMetadata = false);
    }
  }

  Future<void> _saveSettings() async {
    final slowMode = int.tryParse(_slowModeController.text.trim());
    if (slowMode == null || slowMode < 0 || slowMode > 86400) {
      showCommunityMessage(
        context,
        'Slow mode must be from 0 to 86400 seconds.',
      );
      return;
    }
    setState(() => _savingSettings = true);
    try {
      final updated = await ref
          .read(communityApiProvider)
          .updateSettings(
            conversationId: _conversation.id,
            slowModeSeconds: slowMode,
            membersCanPost: _membersCanPost,
            membersCanInvite: _membersCanInvite,
            commentsEnabled: _commentsEnabled,
          );
      if (!mounted) return;
      setState(() => _conversation = updated);
      showCommunityMessage(context, 'Community settings saved.');
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  void _close() => Navigator.pop(context, _conversation);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back',
        onPressed: _close,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Metadata and settings'),
    ),
    body: CommunityContent(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 36),
        children: [
          Form(
            key: _metadataKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Community details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  maxLength: 180,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CommunityVisibility>(
                  initialValue: _visibility,
                  decoration: const InputDecoration(labelText: 'Visibility'),
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
                const SizedBox(height: 16),
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
                  ),
                  validator: (value) {
                    if (_visibility == CommunityVisibility.public &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Enter a handle.';
                    }
                    return null;
                  },
                ),
                FilledButton.icon(
                  onPressed: _savingMetadata ? null : _saveMetadata,
                  icon: _savingMetadata
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Conversation settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slowModeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Slow mode (seconds)',
              helperText: 'Use 0 to turn slow mode off.',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                SwitchListTile(
                  value: _membersCanPost,
                  onChanged: (value) => setState(() => _membersCanPost = value),
                  title: const Text('Members can post'),
                  subtitle: const Text(
                    'Allow regular members to send messages.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _membersCanInvite,
                  onChanged: (value) =>
                      setState(() => _membersCanInvite = value),
                  title: const Text('Members can invite'),
                  subtitle: const Text('Allow members to share invite links.'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _commentsEnabled,
                  onChanged: (value) =>
                      setState(() => _commentsEnabled = value),
                  title: const Text('Comments enabled'),
                  subtitle: const Text('Allow discussion on channel posts.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: _savingSettings ? null : _saveSettings,
            icon: _savingSettings
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tune_rounded),
            label: const Text('Save settings'),
          ),
        ],
      ),
    ),
  );
}
