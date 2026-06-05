import 'package:hive_flutter/hive_flutter.dart';
import 'package:goodtimes/models/course_model.dart';
import 'package:goodtimes/models/module_model.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/models/playback_model.dart';
import 'package:goodtimes/models/settings_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class HiveBoxes {
  static const String coursesBox = 'coursesBox';
  static const String modulesBox = 'modulesBox';
  static const String lecturesBox = 'lecturesBox';
  static const String playbackBox = 'playbackBox';
  static const String settingsBox = 'settingsBox';

  static Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'GoodTime', 'database');
    final dir = Directory(dbPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Delete stale .lock files left behind by force-killed / hot-restarted instances.
    for (final name in [coursesBox, modulesBox, lecturesBox, playbackBox, settingsBox]) {
      final lock = File(p.join(dir.path, '$name.lock'));
      if (await lock.exists()) {
        try { await lock.delete(); } catch (_) {}
      }
    }

    Hive.init(dir.path);

    Hive.registerAdapter(CourseModelAdapter());
    Hive.registerAdapter(ModuleModelAdapter());
    Hive.registerAdapter(LectureModelAdapter());
    Hive.registerAdapter(PlaybackModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    await _safeOpen<CourseModel>(coursesBox, dir.path);
    await _safeOpen<ModuleModel>(modulesBox, dir.path);
    await _safeOpen<LectureModel>(lecturesBox, dir.path);
    await _safeOpen<PlaybackModel>(playbackBox, dir.path);
    await _safeOpen<SettingsModel>(settingsBox, dir.path);

    final settings = Hive.box<SettingsModel>(settingsBox);
    if (settings.isEmpty) {
      await settings.put('user_settings', SettingsModel.defaultSettings());
    }
  }

  /// Opens a Hive box; if it is corrupt, wipes the files and retries once.
  static Future<void> _safeOpen<T>(String name, String dirPath) async {
    try {
      await Hive.openBox<T>(name);
    } catch (_) {
      for (final ext in ['.hive', '.lock']) {
        final f = File(p.join(dirPath, '$name$ext'));
        if (await f.exists()) {
          try { await f.delete(); } catch (_) {}
        }
      }
      await Hive.openBox<T>(name);
    }
  }

  static Box<CourseModel> getCoursesBox() => Hive.box<CourseModel>(coursesBox);
  static Box<ModuleModel> getModulesBox() => Hive.box<ModuleModel>(modulesBox);
  static Box<LectureModel> getLecturesBox() => Hive.box<LectureModel>(lecturesBox);
  static Box<PlaybackModel> getPlaybackBox() => Hive.box<PlaybackModel>(playbackBox);
  static Box<SettingsModel> getSettingsBox() => Hive.box<SettingsModel>(settingsBox);
}
