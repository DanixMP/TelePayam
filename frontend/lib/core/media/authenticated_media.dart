import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/media/media_client.dart';
import 'package:university_messenger/core/media/playback.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

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
    final id = widget.mediaId;
    final resource = await client.metadata(id);
    final bytes = resource.kind == 'image' || resource.kind == 'gif'
        ? await client.download(id)
        : null;
    return (resource: resource, bytes: bytes);
  }

  Future<void> _save(MediaResource resource) async {
    if (_saving || !mounted) return;
    setState(() => _saving = true);
    try {
      final path = await ref
          .read(mediaClientProvider)
          .save(
            resource.id,
            resource: resource,
            fallbackName: '${context.l10n.attachment}-${resource.id}',
          );
      if (mounted && path != null) {
        _showFeedback((l10n) => l10n.mediaSavedTo('\u2068$path\u2069'));
      }
    } catch (error) {
      if (mounted) {
        _showFeedback(
          (l10n) => localizedMediaError(l10n, error, l10n.mediaSaveFailed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showFeedback(String Function(AppLocalizations) message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Builder(builder: (context) => Text(message(context.l10n))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _media,
    builder: (context, snapshot) {
      final l10n = context.l10n;
      if (snapshot.hasError) {
        return TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retryAttachment),
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
      final resource = data.resource;
      final filename = resource.originalName;
      if (data.bytes case final bytes?) {
        final image = Image.memory(
          bytes,
          fit: widget.compact ? BoxFit.contain : BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
        return Semantics(
          button: true,
          label: widget.label ?? filename ?? l10n.imageAttachment,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => _ImageViewer(
                  bytes: bytes,
                  filename: filename,
                  kind: resource.kind,
                  onSave: () => _save(resource),
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
        onTap: _saving || !['audio', 'voice', 'video'].contains(resource.kind)
            ? null
            : () async {
                if (_saving) return;
                setState(() => _saving = true);
                try {
                  final bytes = await ref
                      .read(mediaClientProvider)
                      .download(resource.id);
                  if (context.mounted) {
                    await playMedia(
                      context,
                      bytes,
                      resource.mime,
                      kind: resource.kind,
                      filename: filename,
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    _showFeedback((l10n) => l10n.mediaPlaybackUnavailable);
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Icon(_icon(resource.kind))),
        title: Text(
          filename ?? widget.label ?? localizedMessageType(l10n, resource.kind),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatBytes(l10n, resource.size)),
        trailing: IconButton(
          onPressed: _saving ? null : () => _save(resource),
          tooltip: l10n.download,
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
  const _ImageViewer({
    required this.bytes,
    required this.onSave,
    required this.kind,
    this.filename,
  });

  final Uint8List bytes;
  final String? filename;
  final String kind;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(filename ?? localizedMessageType(context.l10n, kind)),
      actions: [
        IconButton(
          onPressed: onSave,
          tooltip: context.l10n.download,
          icon: const Icon(Icons.download_outlined),
        ),
      ],
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.memory(
          bytes,
          semanticLabel: filename ?? context.l10n.imageAttachment,
        ),
      ),
    ),
  );
}

IconData _icon(String kind) => switch (kind) {
  'video' => Icons.play_circle_outline_rounded,
  'voice' || 'audio' => Icons.graphic_eq_rounded,
  'document' => Icons.picture_as_pdf_outlined,
  _ => Icons.insert_drive_file_outlined,
};

String _formatBytes(AppLocalizations l10n, int bytes) {
  if (bytes < 1024) {
    return l10n.mediaBytes(
      NumberFormat.decimalPattern(l10n.localeName).format(bytes),
    );
  }
  final decimal = NumberFormat.decimalPatternDigits(
    locale: l10n.localeName,
    decimalDigits: 1,
  );
  if (bytes < 1024 * 1024) {
    return l10n.mediaKilobytes(decimal.format(bytes / 1024));
  }
  return l10n.mediaMegabytes(decimal.format(bytes / (1024 * 1024)));
}
