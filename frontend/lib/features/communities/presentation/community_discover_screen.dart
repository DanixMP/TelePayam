import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/communities/data/community_api.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/communities/presentation/community_create_screen.dart';
import 'package:university_messenger/features/communities/presentation/community_info_screen.dart';
import 'package:university_messenger/features/communities/presentation/community_widgets.dart';

class CommunityDiscoverScreen extends ConsumerStatefulWidget {
  const CommunityDiscoverScreen({this.onOpenConversation, super.key});

  final ValueChanged<String>? onOpenConversation;

  @override
  ConsumerState<CommunityDiscoverScreen> createState() =>
      _CommunityDiscoverScreenState();
}

class _CommunityDiscoverScreenState
    extends ConsumerState<CommunityDiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<CommunityConversation>? _items;
  Object? _error;
  var _loading = true;
  var _professorChannelsOnly = false;
  var _joiningInvite = false;
  final Set<String> _joining = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(communityApiProvider)
          .discover(
            professorChannels: _professorChannelsOnly,
            query: _searchController.text,
          );
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _join(CommunityConversation conversation) async {
    setState(() => _joining.add(conversation.id));
    try {
      final joined = await ref.read(communityApiProvider).join(conversation.id);
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (!mounted) return;
      setState(() {
        _items = _items
            ?.map((item) => item.id == joined.id ? joined : item)
            .toList();
      });
      showCommunityMessage(context, 'Joined ${joined.title}.');
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _joining.remove(conversation.id));
    }
  }

  Future<void> _joinWithInvite() async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join with invite'),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Invite token',
            hintText: 'Paste an invite token',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (token == null || !mounted) return;
    setState(() => _joiningInvite = true);
    try {
      final conversation = await ref
          .read(communityApiProvider)
          .joinInvite(token);
      await ref.read(chatRepositoryProvider).refreshConversations();
      if (!mounted) return;
      showCommunityMessage(context, 'Joined ${conversation.title}.');
      _openInfo(conversation);
    } catch (error) {
      if (mounted) showCommunityMessage(context, communityErrorText(error));
    } finally {
      if (mounted) setState(() => _joiningInvite = false);
    }
  }

  void _openInfo(CommunityConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityInfoScreen(
          conversationId: conversation.id,
          initialConversation: conversation,
          onOpenConversation: widget.onOpenConversation,
        ),
      ),
    );
  }

  Future<void> _openCreate(CommunityCreationKind kind) async {
    final created = await Navigator.of(context).push<CommunityConversation>(
      MaterialPageRoute<CommunityConversation>(
        builder: (_) => CommunityCreateScreen(initialKind: kind),
      ),
    );
    if (created != null) {
      await _load();
      if (mounted) _openInfo(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authControllerProvider).state.account;
    final role = account?.role;
    final roleAllowed = role == UserRole.student || role == UserRole.professor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover communities'),
        actions: [
          if (roleAllowed)
            IconButton(
              tooltip: 'Join with invite',
              onPressed: _joiningInvite ? null : _joinWithInvite,
              icon: _joiningInvite
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_link_rounded),
            ),
          if (roleAllowed)
            PopupMenuButton<CommunityCreationKind>(
              tooltip: 'Create community',
              icon: const Icon(Icons.add_rounded),
              onSelected: _openCreate,
              itemBuilder: (context) => [
                if (role == UserRole.student)
                  const PopupMenuItem(
                    value: CommunityCreationKind.group,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.groups_rounded),
                      title: Text('Student group'),
                    ),
                  ),
                const PopupMenuItem(
                  value: CommunityCreationKind.channel,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.campaign_rounded),
                    title: Text('Channel'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: !roleAllowed
          ? const CommunityStateMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Communities are unavailable',
              body:
                  'Only active student and professor accounts can use communities.',
            )
          : CommunityContent(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      8,
                    ),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search names and handles',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {});
                        _searchChanged(value);
                      },
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.public_rounded),
                            label: Text('All public'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.school_rounded),
                            label: Text('Professor channels'),
                          ),
                        ],
                        selected: {_professorChannelsOnly},
                        onSelectionChanged: (selection) {
                          setState(
                            () => _professorChannelsOnly = selection.first,
                          );
                          _load();
                        },
                      ),
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  Expanded(child: _buildResults()),
                ],
              ),
            ),
    );
  }

  Widget _buildResults() {
    if (_error != null && _items == null) {
      return CommunityStateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load communities',
        body: communityErrorText(_error!),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    final items = _items ?? const <CommunityConversation>[];
    if (!_loading && items.isEmpty) {
      return CommunityStateMessage(
        icon: Icons.travel_explore_rounded,
        title: 'No communities found',
        body: _searchController.text.trim().isEmpty
            ? 'There are no public communities in this category yet.'
            : 'Try a different name or handle.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final conversation = items[index];
          final joining = _joining.contains(conversation.id);
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 82,
              leading: CommunityAvatar(conversation: conversation),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (conversation.isProfessorChannel) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 18),
                  ],
                ],
              ),
              subtitle: Text(
                [
                  if (conversation.handle != null) '@${conversation.handle}',
                  '${conversation.memberCount} members',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: conversation.isMember
                  ? const Icon(Icons.chevron_right_rounded)
                  : FilledButton.tonal(
                      onPressed: joining ? null : () => _join(conversation),
                      child: joining
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Join'),
                    ),
              onTap: () => _openInfo(conversation),
            ),
          );
        },
      ),
    );
  }
}
