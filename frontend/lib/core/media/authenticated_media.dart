import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/media_client.dart';
import 'package:university_messenger/core/media/playback.dart';

class AuthenticatedMediaTile extends ConsumerStatefulWidget {
  const AuthenticatedMediaTile({
    required this.mediaId,
    this.label,
    this.compact = false,
    super.key,
  });

  final String mediaId;
  final String? label;
  final bool compact;

  @override
  ConsumerState<AuthenticatedMediaTile> createState() =>
      _AuthenticatedMediaTileState();
}

class _AuthenticatedMediaTileState
    extends ConsumerState<AuthenticatedMediaTile> {
  late Future<({MediaResource resource, Uint8List? bytes})> _media = _load();
  var _saving = false;

  @override
  void didUpdateWidget(covariant AuthenticatedMediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) _media = _load();
  }

  Future<({MediaResource resource, Uint8List? bytes})> _load() async {
    final client = ref.read(mediaClientProvider);
    final resource = await client.metadata(widget.mediaId);
    final bytes = resource.kind == 'image' || resource.kind == 'gif'
        ? await client.download(widget.mediaId)
        : null;
    return (resource: resource, bytes: bytes);
  }

  Future<void> _save(MediaResource resource) async {
    if (_saving || !mounted) return;
    setState(() => _saving = true);
    try {
      final path = await ref
          .read(mediaClientProvider)
          .save(widget.mediaId, resource: resource);
      if (mounted && path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this attachment. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _media,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Retry attachment'),
          onPressed: () => setState(() => _media = _load()),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final data = snapshot.data!;
      if (data.bytes case final bytes?) {
        final image = Image.memory(
          bytes,
          fit: widget.compact ? BoxFit.contain : BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
        return Semantics(
          button: true,
          label:
              widget.label ?? data.resource.originalName ?? 'Image attachment',
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => _ImageViewer(
                  bytes: bytes,
                  title: widget.label ?? data.resource.originalName,
                  onSave: () => _save(data.resource),
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: widget.compact ? 92 : 180,
                width: double.infinity,
                child: image,
              ),
            ),
          ),
        );
      }
      return ListTile(
        onTap:
            _saving || !['audio', 'voice', 'video'].contains(data.resource.kind)
            ? null
            : () async {
                if (_saving) return;
                setState(() => _saving = true);
                try {
                  final bytes = await ref
                      .read(mediaClientProvider)
                      .download(widget.mediaId);
                  if (context.mounted) {
                    await playMedia(
                      context,
                      bytes,
                      data.resource.mime,
                      data.resource.originalName ?? 'Media',
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Playback unavailable. Try downloading the attachment.',
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Icon(_icon(data.resource.kind))),
        title: Text(
          data.resource.originalName ?? widget.label ?? data.resource.kind,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatBytes(data.resource.size)),
        trailing: IconButton(
          onPressed: _saving ? null : () => _save(data.resource),
          tooltip: 'Download',
          icon: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
        ),
      );
    },
  );
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.bytes, required this.onSave, this.title});

  final Uint8List bytes;
  final String? title;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(title ?? 'Media'),
      actions: [
        IconButton(
          onPressed: onSave,
          tooltip: 'Download',
          icon: const Icon(Icons.download_outlined),
        ),
      ],
    ),
    body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
  );
}

IconData _icon(String kind) => switch (kind) {
  'video' => Icons.play_circle_outline_rounded,
  'voice' || 'audio' => Icons.graphic_eq_rounded,
  'document' => Icons.picture_as_pdf_outlined,
  _ => Icons.insert_drive_file_outlined,
};

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
