import 'dart:js_interop';
import 'dart:typed_data';

import 'package:university_messenger/core/media/playback_source.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

Future<PlaybackSource> preparePlayback(Uint8List bytes, String mime) async {
  final url = web.URL.createObjectURL(
    web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime)),
  );
  return (
    player: VideoPlayerController.networkUrl(Uri.parse(url)),
    release: () async => web.URL.revokeObjectURL(url),
  );
}
