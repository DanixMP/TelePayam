import 'package:video_player/video_player.dart';

typedef PlaybackSource = ({
  VideoPlayerController? player,
  Future<void> Function() release,
});
