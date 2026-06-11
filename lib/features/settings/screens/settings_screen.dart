import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/providers/settings_provider.dart';
import 'package:goodtimes/providers/course_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        );

    return Container(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        children: [
          const Text('SETTINGS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 32),
          ListTile(
            title: Text('Folders', style: titleStyle),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Manage Folders', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              ref.read(coursesProvider.notifier).addRootFolder(ref);
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          ListTile(
            title: Text('Playback', style: titleStyle),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.play_arrow),
            title: const Text('Auto Resume', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Resume video from last watched position', style: TextStyle(color: Colors.white54)),
            value: settings.autoResume,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleAutoResume(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.skip_next),
            title: const Text('Autoplay Next', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Play the next video automatically', style: TextStyle(color: Colors.white54)),
            value: settings.autoplay,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleAutoplay(val);
            },
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          ListTile(
            title: Text('System', style: titleStyle),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Thumbnail Cache', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Frees up storage space by deleting cached images', style: TextStyle(color: Colors.white54)),
            trailing: ElevatedButton(
              onPressed: () async {
                final appDir = await getApplicationSupportDirectory();
                final thumbDir = Directory(p.join(appDir.path, 'GoodTime', 'thumbnails'));
                if (await thumbDir.exists()) {
                  await thumbDir.delete(recursive: true);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thumbnail cache cleared successfully.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}
