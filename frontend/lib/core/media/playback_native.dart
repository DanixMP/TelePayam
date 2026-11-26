import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:university_messenger/core/media/playback_source.dart';
import 'package:video_player/video_player.dart';

Future<PlaybackSource> preparePlayback(Uint8List bytes, String mime) async {
  // Never launch a sender-controlled filename in an external application.
  final ext = const {
    'video/mp4': 'mp4',
    'video/webm': 'webm',
    'audio/mp4': 'm4a',
    'audio/mpeg': 'mp3',
    'audio/ogg': 'ogg',
  }[mime];
  if (ext == null) throw const FormatException('Unsupported media format');
  final root = await getTemporaryDirectory();
  final dir = await root.createTemp('messenger-play-');
  final file = File('${dir.path}/clip.$ext');
  try {
    await file.writeAsBytes(bytes, flush: true);
    if (Platform.isWindows || Platform.isLinux) {
      final result = await OpenFilex.open(file.path, type: mime);
      if (result.type != ResultType.done) throw StateError(result.message);
      // The system player owns the open file; the OS temp directory is disposable.
      return (player: null, release: () async {});
    }
    return (
      player: VideoPlayerController.file(file),
      release: () async {
        await dir.delete(recursive: true);
      },
    );
  } catch (_) {
    await dir.delete(recursive: true);
    rethrow;
  }
}
