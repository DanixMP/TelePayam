import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/media_thumbnail.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

const photoTypes = XTypeGroup(
  label: 'Photo',
  extensions: ['jpg', 'jpeg', 'png', 'webp'],
  mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
  uniformTypeIdentifiers: ['public.image'],
);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  bool busy = false;
  String? error;

  Future<void> changePhoto({bool remove = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      String? id;
      if (!remove) {
        final file = await openFile(acceptedTypeGroups: [photoTypes]);
        if (file == null || !mounted) return;
        final media = await ref.read(mediaClientProvider).upload(file);
        id = media.id;
      }
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      await ref
          .read(apiClientProvider)
          .dio
          .patch('/users/me', data: {'avatar_id': id});
      if (!await auth.refreshStatus()) throw StateError('Refresh failed');
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.photoUpdateError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authControllerProvider).state.account;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.myProfile)),
      body: account == null
          ? null
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: ContactAvatar(
                        id: account.avatarId,
                        radius: 56,
                        fallback: const CircleAvatar(
                          radius: 56,
                          child: Icon(Icons.person_outline, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      account.displayName.isEmpty
                          ? account.phone
                          : account.displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    if (busy) const LinearProgressIndicator(),
                    FilledButton.tonalIcon(
                      onPressed: busy ? null : () => changePhoto(),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(l.changePhoto),
                    ),
                    if (account.avatarId != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => changePhoto(remove: true),
                        child: Text(l.removePhoto),
                      ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const Divider(height: 32),
                    for (final entry in [
                      if (account.handle != null)
                        (l.username, '@${account.handle}'),
                      (l.messengerId, account.id),
                    ])
                      ListTile(
                        title: Text(entry.$1),
                        subtitle: SelectableText(
                          entry.$2,
                          textDirection: TextDirection.ltr,
                        ),
                        trailing: IconButton(
                          tooltip: l.copyId,
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: entry.$2)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
