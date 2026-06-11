import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/models/playback_model.dart';
import 'package:goodtimes/providers/settings_provider.dart';
import 'dart:async';

final playerProvider = Provider.autoDispose.family<PlayerController, LectureModel>((ref, lecture) {
  final controller = PlayerController(lecture, ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class PlayerController {
  final LectureModel lecture;
  final Ref ref;
  late final Player player;
  late final VideoController controller;
  Timer? _progressTimer;

  PlayerController(this.lecture, this.ref) {
    player = Player();
    controller = VideoController(player);
    _init();
  }

  Future<void> _init() async {
    await player.open(Media(lecture.filePath));
    
    // Resume progress if exists
    final settings = ref.read(settingsProvider);
    if (settings.autoResume) {
      final pbBox = HiveBoxes.getPlaybackBox();
      final pb = pbBox.get(lecture.id);
      if (pb != null && pb.watchedSeconds > 0) {
        await player.seek(Duration(seconds: pb.watchedSeconds));
      }
    }

    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveProgress();
    });
  }

  void _saveProgress() {
    final pos = player.state.position;
    final dur = player.state.duration;
    
    if (pos.inSeconds == 0) return;
    
    double percent = dur.inSeconds > 0 ? pos.inSeconds / dur.inSeconds : 0.0;
    
    bool completed = false;
    // If watched > 90%, treat as completed
    if (percent > 0.90) {
      percent = 1.0;
      completed = true;
    }

    final pb = PlaybackModel(
      videoId: lecture.id,
      watchedSeconds: pos.inSeconds,
      watchedPercentage: percent,
      lastPlayed: DateTime.now(),
    );

    HiveBoxes.getPlaybackBox().put(lecture.id, pb);

    // Update lecture model as well
    final lecturesBox = HiveBoxes.getLecturesBox();
    lecture.watchProgressPercentage = (percent * 100).toInt();
    lecture.lastPositionSeconds = pos.inSeconds;
    lecture.lastWatched = DateTime.now();
    if (completed) lecture.isCompleted = true;
    lecturesBox.put(lecture.id, lecture);
  }

  void dispose() {
    _progressTimer?.cancel();
    _saveProgress();
    player.dispose();
  }
}
