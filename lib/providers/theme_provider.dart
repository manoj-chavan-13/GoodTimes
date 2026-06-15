import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';

// Modern Riverpod 3.x Notifier for ThemeMode
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      final settingsBox = HiveBoxes.getSettingsBox();
      final settings = settingsBox.get('user_settings');
      // darkMode true -> dark theme, false -> light theme
      return (settings?.darkMode ?? false) ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  void toggleTheme() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    try {
      final settingsBox = HiveBoxes.getSettingsBox();
      final settings = settingsBox.get('user_settings');
      if (settings != null) {
        settings.darkMode = next == ThemeMode.dark;
        settingsBox.put('user_settings', settings);
      }
    } catch (_) {}
  }
}
