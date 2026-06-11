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
    // Rename database dir for GoodTime so it doesn't conflict with PlayIt
    final dbPath = p.join(appDir.path, 'GoodTime', 'database');
    final dir = Directory(dbPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    Hive.init(dir.path);

    Hive.registerAdapter(CourseModelAdapter());
    Hive.registerAdapter(ModuleModelAdapter());
    Hive.registerAdapter(LectureModelAdapter());
    Hive.registerAdapter(PlaybackModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    await Hive.openBox<CourseModel>(coursesBox);
    await Hive.openBox<ModuleModel>(modulesBox);
    await Hive.openBox<LectureModel>(lecturesBox);
    await Hive.openBox<PlaybackModel>(playbackBox);
    await Hive.openBox<SettingsModel>(settingsBox);
    
    final settings = Hive.box<SettingsModel>(settingsBox);
    if (settings.isEmpty) {
      await settings.put('user_settings', SettingsModel.defaultSettings());
    }
  }

  static Box<CourseModel> getCoursesBox() => Hive.box<CourseModel>(coursesBox);
  static Box<ModuleModel> getModulesBox() => Hive.box<ModuleModel>(modulesBox);
  static Box<LectureModel> getLecturesBox() => Hive.box<LectureModel>(lecturesBox);
  static Box<PlaybackModel> getPlaybackBox() => Hive.box<PlaybackModel>(playbackBox);
  static Box<SettingsModel> getSettingsBox() => Hive.box<SettingsModel>(settingsBox);
}
