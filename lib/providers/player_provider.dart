import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/models/playback_model.dart';
import 'package:goodtimes/providers/settings_provider.dart';
import 'dart:async';

final playbackSpeedProvider = NotifierProvider<PlaybackSpeedNotifier, double>(() {
  return PlaybackSpeedNotifier();
});

class PlaybackSpeedNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void setSpeed(double speed) {
    state = speed;
  }
}

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
  bool _isDisposed = false;

  PlayerController(this.lecture, this.ref) {
    player = Player(
      configuration: const PlayerConfiguration(
        pitch: true,
      ),
    );
    controller = VideoController(player);
    _init();
  }

  Future<void> _init() async {
    try {
      await player.open(Media(lecture.filePath));
      
      if (_isDisposed) return;
      
      // Apply speed rate
      final speed = ref.read(playbackSpeedProvider);
      await player.setRate(speed);
      
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
    } catch (e) {
      print('Error initializing player for ${lecture.title}: $e');
    }
  }

  void _saveProgress() {
    if (_isDisposed) return;
    try {
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
      lecture.duration = dur;
      lecture.watchProgressPercentage = (percent * 100).toInt();
      lecture.lastPositionSeconds = pos.inSeconds;
      lecture.lastWatched = DateTime.now();
      if (completed) lecture.isCompleted = true;
      lecturesBox.put(lecture.id, lecture);
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _progressTimer?.cancel();
    _saveProgress();
    try {
      player.dispose();
    } catch (e) {
      print('Error disposing player: $e');
    }
  }
}
