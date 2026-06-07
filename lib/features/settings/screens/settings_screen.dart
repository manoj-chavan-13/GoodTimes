import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/providers/settings_provider.dart';
import 'package:goodtimes/providers/course_provider.dart';
import 'package:goodtimes/providers/history_provider.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:goodtimes/core/themes/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Sync initial state
    final initialTab = ref.read(settingsActiveTabProvider);
    _tabController.index = initialTab;

    // Listen to changes inside the controller to update the provider
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(settingsActiveTabProvider.notifier).setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch settingsActiveTabProvider and update controller index when changed from outside
    ref.listen<int>(settingsActiveTabProvider, (prev, next) {
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
    });
    
    final settings = ref.watch(settingsProvider);
    final courses = ref.watch(coursesProvider);

    return Container(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 48, top: 40, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure preferences, learn keyboard shortcuts, or inspect application details.',
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Beautiful Custom TabBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 8.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted(context),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Tab(child: Text('How to Use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  ],
                ),
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPreferencesTab(context, ref, settings, courses),
                    _buildHowToUseTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesTab(BuildContext context, WidgetRef ref, dynamic settings, List<dynamic> courses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder management card
          _buildSectionCard(
            context: context,
            icon: Icons.folder_shared_outlined,
            title: 'Library Folders',
            subtitle: 'Configure the root directories scanned by GoodTime to discover courses',
            children: [
              if (courses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 48, color: AppColors.textFaint(context).withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text(
                          'No folders added yet.',
                          style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.border(context).withOpacity(0.5), height: 1),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Icon(Icons.folder_copy_outlined, color: AppColors.primary.withOpacity(0.8), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: TextStyle(
                                    color: AppColors.text(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  course.folderPath,
                                  style: TextStyle(
                                    color: AppColors.textFaint(context),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: 'Remove Folder',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Remove Folder?', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                                  content: Text(
                                    'Are you sure you want to remove "${course.title}" from your library?\n\n(Your local files will NOT be deleted.)',
                                    style: TextStyle(color: AppColors.textMuted(context)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        ref.read(coursesProvider.notifier).removeCourse(course.id);
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Folder removed successfully.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final added = await ref.read(coursesProvider.notifier).addRootFolder();
                    if (!context.mounted) return;
                    _showScanResultDialog(context, added);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                  label: const Text(
                    'Add Folder Path',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          // Playback preference card
          _buildSectionCard(
            context: context,
            icon: Icons.play_circle_outline,
            title: 'Playback Preferences',
            subtitle: 'Manage how GoodTime plays and tracks video learning lectures',
            children: [
              _buildSwitchSetting(
                context: context,
                icon: Icons.play_arrow_outlined,
                title: 'Auto Resume',
                subtitle: 'Resume video from last watched position',
                value: settings.autoResume,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).toggleAutoResume(val);
                },
              ),
              Divider(color: AppColors.border(context).withOpacity(0.5), height: 24),
              _buildSwitchSetting(
                context: context,
                icon: Icons.skip_next_outlined,
                title: 'Autoplay Next',
                subtitle: 'Play the next video automatically',
                value: settings.autoplay,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).toggleAutoplay(val);
                },
              ),
            ],
          ),

          // System maintenance card
          _buildSectionCard(
            context: context,
            icon: Icons.settings_suggest_outlined,
            title: 'System & Maintenance',
            subtitle: 'Perform housekeeping tasks and manage storage cache',
            children: [
              _buildActionSetting(
                context: context,
                icon: Icons.image_outlined,
                title: 'Clear Thumbnail Cache',
                subtitle: 'Frees up storage space by deleting cached images',
                buttonText: 'Clear Cache',
                isDanger: false,
                onPressed: () async {
                  try {
                    final docsDir = await getApplicationDocumentsDirectory();
                    final thumbDir = Directory(p.join(docsDir.path, 'GoodTime', 'Thumbnails'));
                    if (await thumbDir.exists()) {
                      await thumbDir.delete(recursive: true);
                    }
                    final appDir = await getApplicationSupportDirectory();
                    final oldThumbDir = Directory(p.join(appDir.path, 'GoodTime', 'thumbnails'));
                    if (await oldThumbDir.exists()) {
                      await oldThumbDir.delete(recursive: true);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thumbnail cache cleared successfully.', style: TextStyle(color: AppColors.text(context))),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error clearing thumbnail cache: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to clear thumbnail cache: $e', style: TextStyle(color: AppColors.text(context))),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
              Divider(color: AppColors.border(context).withOpacity(0.5), height: 24),
              _buildActionSetting(
                context: context,
                icon: Icons.history,
                title: 'Clear Watch History',
                subtitle: 'Removes all watch progress and continue watching items',
                buttonText: 'Clear History',
                isDanger: true,
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Clear History?', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                      content: Text(
                        'Are you sure you want to clear all your watch progress? This cannot be undone.',
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final lecturesBox = HiveBoxes.getLecturesBox();
                            for (var lecture in lecturesBox.values) {
                              lecture.watchProgressPercentage = 0;
                              lecture.lastPositionSeconds = 0;
                              lecture.lastWatched = null;
                              lecture.isCompleted = false;
                              await lecturesBox.put(lecture.id, lecture);
                            }
                            await HiveBoxes.getPlaybackBox().clear();
                            ref.read(historyProvider.notifier).refresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Watch history cleared successfully.', style: TextStyle(color: AppColors.text(context))),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHowToUseTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final features = [
      {'title': 'Local Folder Scanning', 'desc': 'Add any folder containing video files to automatically detect and index courses, modules, and lessons.'},
      {'title': 'Automatic Progress Tracking', 'desc': 'The player tracks playback progress and saves it. If a video is watched >90%, it is marked as completed.'},
      {'title': 'Resume Playback', 'desc': 'Close the app and resume from the exact second you left off with Auto-Resume enabled.'},
      {'title': 'Variable Playback Speed', 'desc': 'Speed up or slow down videos using keyboard shortcuts.'},
    ];

    final shortcuts = [
      {'key': 'Space', 'action': 'Play / Pause playback'},
      {'key': 'F', 'action': 'Toggle Fullscreen mode'},
      {'key': 'M', 'action': 'Mute / Unmute audio'},
      {'key': '→ (Right)', 'action': 'Skip forward 10 seconds'},
      {'key': '← (Left)', 'action': 'Skip backward 10 seconds'},
      {'key': '↑ (Up)', 'action': 'Volume Up (by 5%)'},
      {'key': '↓ (Down)', 'action': 'Volume Down (by 5%)'},
      {'key': 'Shift + >', 'action': 'Increase playback speed (+0.25x)'},
      {'key': 'Shift + <', 'action': 'Decrease playback speed (-0.25x)'},
      {'key': 'N / Shift+N', 'action': 'Skip to the Next lecture'},
      {'key': 'P / Shift+P', 'action': 'Go back to the Previous lecture'},
      {'key': 'Esc', 'action': 'Exit fullscreen mode'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Features Section
          Text(
            'App Features',
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final item = features[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['desc']!,
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Shortcuts Section
          Text(
            'Keyboard Shortcuts',
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
              childAspectRatio: 3.2,
            ),
            itemCount: shortcuts.length,
            itemBuilder: (context, index) {
              final shortcut = shortcuts[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        shortcut['key']!,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        shortcut['action']!,
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }



  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textFaint(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted(context), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: AppColors.border(context),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required bool isDanger,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted(context), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDanger ? Colors.redAccent.withOpacity(0.5) : AppColors.border(context)),
            foregroundColor: isDanger ? Colors.redAccent : AppColors.text(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showScanResultDialog(BuildContext context, int result) {
    if (result == -1) return;

    showDialog(
      context: context,
      builder: (context) {
        final isAlreadyAdded = result == -2;
        final isSuccess = result > 0;
        final icon = isAlreadyAdded
            ? Icons.info_outline
            : (isSuccess ? Icons.check_circle_outline : Icons.warning_amber_outlined);
        final title = isAlreadyAdded
            ? 'Already Added'
            : (isSuccess ? 'Congratulations!' : 'No Courses Found');
        final message = isAlreadyAdded
            ? 'This folder has already been added to your GoodTime library.'
            : (isSuccess
                ? 'We have successfully added $result new course folder(s) to your library.'
                : 'No compatible course folders or media files were found in the selected directory.');

        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
