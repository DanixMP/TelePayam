import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';

final mediaBytesProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, id) {
    ref.watch(authControllerProvider.select((auth) => auth.state.account?.id));
    return ref.watch(mediaClientProvider).download(id);
  },
);

class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail(
    this.id, {
    this.fit = BoxFit.cover,
    this.label,
    super.key,
  });
  final String id;
  final BoxFit fit;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(mediaBytesProvider(id))
      .when(
        data: (bytes) => Image.memory(
          bytes,
          fit: fit,
          semanticLabel: label,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        ),
        loading: () => const Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => IconButton(
          tooltip: 'Retry image',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(mediaBytesProvider(id)),
        ),
      );
}

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    required this.id,
    required this.fallback,
    this.radius = 20,
    super.key,
  });
  final String? id;
  final Widget fallback;
  final double radius;
  @override
  Widget build(BuildContext context) => id == null
      ? fallback
      : ClipOval(
          child: SizedBox.square(
            dimension: radius * 2,
            child: MediaThumbnail(id!, label: 'Profile photo'),
          ),
        );
}
