import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:university_messenger/core/media/playback_native.dart'
    if (dart.library.js_interop) 'package:university_messenger/core/media/playback_web.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';
import 'package:video_player/video_player.dart';

Future<void> playMedia(
  BuildContext context,
  Uint8List bytes,
  String mime, {
  required String kind,
  String? filename,
}) async {
  final source = await preparePlayback(bytes, mime);
  final player = source.player;
  try {
    if (player == null || !context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _Player(
          player: player,
          kind: kind,
          filename: filename,
          video: mime.startsWith('video/'),
        ),
      ),
    );
  } finally {
    await player?.dispose();
    await source.release();
  }
}

class _Player extends StatefulWidget {
  const _Player({
    required this.player,
    required this.kind,
    this.filename,
    required this.video,
  });
  final VideoPlayerController player;
  final String kind;
  final String? filename;
  final bool video;
  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  late final ready = widget.player.initialize();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.filename ?? localizedMessageType(context.l10n, widget.kind),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: FutureBuilder(
          future: ready,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.mediaFormatUnavailable,
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            final player = widget.player;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.video)
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: player.value.aspectRatio,
                      child: VideoPlayer(player),
                    ),
                  )
                else
                  const Icon(Icons.audiotrack, size: 64),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: VideoProgressIndicator(player, allowScrubbing: true),
                ),
                ValueListenableBuilder(
                  valueListenable: player,
                  builder: (context, value, _) => IconButton.filled(
                    tooltip: value.isPlaying
                        ? context.l10n.mediaPause
                        : context.l10n.mediaPlay,
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: value.isPlaying ? player.pause : player.play,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
