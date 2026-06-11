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
    final courses = ref.watch(coursesProvider);
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
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text('Add New Folder', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () async {
              final added = await ref.read(coursesProvider.notifier).addRootFolder();
              if (!context.mounted) return;
              if (added == -1) {
                // Cancelled
              } else if (added == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No courses or videos found in the selected folder.'), backgroundColor: Colors.orange),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully added $added course(s).'), backgroundColor: Colors.green),
                );
              }
            },
          ),
          ...courses.map((course) => ListTile(
                leading: const Icon(Icons.movie_creation, color: Colors.white54),
                title: Text(course.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(course.folderPath, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF141414),
                        title: const Text('Remove Folder?', style: TextStyle(color: Colors.white)),
                        content: Text('Are you sure you want to remove "${course.title}" from your library?\n\n(Your local files will NOT be deleted.)', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              ref.read(coursesProvider.notifier).removeCourse(course.id);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Folder removed successfully.'), backgroundColor: Colors.green),
                              );
                            },
                            child: const Text('Remove', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )).toList(),
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
