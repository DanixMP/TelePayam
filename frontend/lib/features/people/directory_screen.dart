import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/media_thumbnail.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({this.initialQuery = '', super.key});
  final String initialQuery;
  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryState();
}

class _DirectoryState extends ConsumerState<DirectoryScreen> {
  late final query = TextEditingController(text: widget.initialQuery);
  List<Map<String, dynamic>>? results;
  bool busy = false;
  String? errorCode;
  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) search();
      });
    }
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (busy) return;
    final term = query.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (term.length < 2) {
      setState(() {
        errorCode = 'query_too_short';
        results = null;
      });
      return;
    }
    setState(() {
      busy = true;
      errorCode = null;
      results = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .dio
          .get<List<dynamic>>('/search', queryParameters: {'q': term});
      if (mounted) {
        setState(() => results = response.data!.cast<Map<String, dynamic>>());
      }
    } catch (error) {
      if (mounted) {
        setState(() => errorCode = apiErrorCode(error) ?? 'request_failed');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(Map<String, dynamic> result) async {
    final id = result['id'] as String;
    if (result['kind'] != 'user') {
      await context.push('/home/communities/$id');
      return;
    }
    setState(() {
      busy = true;
      errorCode = null;
    });
    try {
      final chat = await ref.read(chatRepositoryProvider).openDm(id);
      if (mounted) {
        ref.read(chatSearchProvider.notifier).state = '';
        context.go('/home/chat/$chat');
      }
    } catch (error) {
      if (mounted) {
        setState(() => errorCode = apiErrorCode(error) ?? 'request_failed');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.findById)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: query,
                    readOnly: busy,
                    autofocus: true,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                    decoration: InputDecoration(
                      labelText: l.findById,
                      helperText: l.searchIdHint,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: l.findById,
                        onPressed: busy ? null : search,
                      ),
                    ),
                  ),
                  if (busy) const LinearProgressIndicator(),
                  if (errorCode != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(switch (errorCode) {
                        'query_too_short' => l.searchIdHint,
                        'search_rate_limited' => l.directorySearchRateLimited,
                        _ => localizedApiError(l, errorCode),
                      }),
                    ),
                  if (results?.isEmpty == true)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.noIdMatches),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results?.length ?? 0,
                      itemBuilder: (_, index) {
                        final item = results![index];
                        final title = item['title'] as String?;
                        final handle = item['handle'] as String?;
                        return ListTile(
                          leading: ContactAvatar(
                            id: item['avatar_id'] as String?,
                            fallback: CircleAvatar(
                              child: Icon(
                                item['kind'] == 'user'
                                    ? Icons.person_outline
                                    : Icons.forum_outlined,
                              ),
                            ),
                          ),
                          title: Text(
                            title == null || title.trim().isEmpty
                                ? l.account
                                : title,
                          ),
                          subtitle: Text(
                            handle == null ? item['id'] as String : '@$handle',
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: Icon(
                            item['kind'] == 'user'
                                ? Icons.chat_bubble_outline
                                : Icons.navigate_next_rounded,
                          ),
                          onTap: busy ? null : () => open(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
