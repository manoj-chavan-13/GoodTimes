import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/core/themes/app_theme.dart';
import 'package:goodtimes/features/home/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize media_kit
  MediaKit.ensureInitialized();
  
  // Initialize Hive and DB
  await HiveBoxes.init();

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(900, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    const ProviderScope(
      child: GoodTimeApp(),
    ),
  );
}

class GoodTimeApp extends ConsumerWidget {
  const GoodTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: MaterialApp(
            title: 'GoodTime',
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Enforce dark cinematic theme
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
