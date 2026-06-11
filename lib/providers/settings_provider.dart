import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/settings_model.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    return HiveBoxes.getSettingsBox().get('user_settings') ?? SettingsModel.defaultSettings();
  }

  void toggleAutoResume(bool value) {
    state = SettingsModel(
      autoResume: value,
      autoplay: state.autoplay,
      darkMode: state.darkMode,
      autoScan: state.autoScan,
      thumbnailQuality: state.thumbnailQuality,
      maxThumbnailJobs: state.maxThumbnailJobs,
    );
    _saveSettings();
  }

  void toggleAutoplay(bool value) {
    state = SettingsModel(
      autoResume: state.autoResume,
      autoplay: value,
      darkMode: state.darkMode,
      autoScan: state.autoScan,
      thumbnailQuality: state.thumbnailQuality,
      maxThumbnailJobs: state.maxThumbnailJobs,
    );
    _saveSettings();
  }

  void _saveSettings() {
    HiveBoxes.getSettingsBox().put('user_settings', state);
  }
}

final settingsActiveTabProvider = NotifierProvider<SettingsActiveTabNotifier, int>(() {
  return SettingsActiveTabNotifier();
});

class SettingsActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}
