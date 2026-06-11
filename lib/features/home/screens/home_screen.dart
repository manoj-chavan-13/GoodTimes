import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/features/settings/screens/settings_screen.dart';
import 'package:goodtimes/features/folder/screens/course_screen.dart';
import 'package:goodtimes/providers/course_provider.dart';
import 'package:goodtimes/providers/history_provider.dart';
import 'package:goodtimes/widgets/hoverable_card.dart';
import 'package:goodtimes/models/course_model.dart';
import 'package:goodtimes/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:goodtimes/providers/scan_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isScanning = false;
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRescan();
    });
  }

  Future<void> _autoRescan() async {
    final courses = ref.read(coursesProvider);
    if (courses.isEmpty) return;
    
    Set<String> rootFolders = courses.map((c) => p.dirname(c.folderPath)).toSet();
    
    setState(() => _isScanning = true);
    try {
      for (var path in rootFolders) {
        await ref.read(scanProvider).scanRootFolder(path);
      }
      ref.read(coursesProvider.notifier).refresh();
      ref.read(historyProvider.notifier).refresh();
    } catch (e) {
      print('Auto-rescan error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Column(
        children: [
          const CustomTitleBar(isTransparent: false),
          Expanded(
            child: Row(
              children: [
                // GLOBAL SIDEBAR
                _buildSidebar(),
                
                // MAIN CONTENT AREA
                Expanded(
                  child: Stack(
                    children: [
                      _buildMainContent(courses, history),
                      if (_isScanning)
                        Container(
                          color: Colors.black.withOpacity(0.8),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFFE50914)),
                                SizedBox(height: 16),
                                Text('Scanning for courses...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? 80 : 250,
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 16.0 : 24.0, vertical: 24.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  ),
                  if (!_isSidebarCollapsed) ...[
                    const SizedBox(width: 12),
                    Image.asset('lib/assets/icon.png', height: 32),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.home_filled, 'Home', 0),
          _buildSidebarItem(Icons.video_library, 'All Courses', 1),
          _buildSidebarItem(Icons.history, 'Continue Watching', 2),
          const Spacer(),
          _buildSidebarItem(Icons.settings, 'Settings', 3),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.white : Colors.white54;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      hoverColor: Colors.white.withOpacity(0.05),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: isSelected ? const Color(0xFFE50914) : Colors.transparent, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List courses, List<HistoryItem> history) {
    // If settings is selected, render it directly
    if (_selectedIndex == 3) {
      return const SettingsScreen();
    }

    // Top utility bar (Search, Profile) overlaying the content
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: const Color(0xFF141414)),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedIndex == 0
              ? SingleChildScrollView(
                  key: const ValueKey(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(courses),
                      const SizedBox(height: 32),
                      _buildContinueWatching(history),
                      const SizedBox(height: 32),
                      _buildAllCoursesHeader(),
                      const SizedBox(height: 16),
                      _buildCoursesList(courses),
                      const SizedBox(height: 64),
                    ],
                  ),
                )
              : _selectedIndex == 1
                  ? Padding(
                      key: const ValueKey(1),
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          _buildAllCoursesHeader(),
                          const SizedBox(height: 24),
                          Expanded(
                            child: courses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.folder_open, size: 100, color: Colors.white24),
                                        const SizedBox(height: 24),
                                        const Text('You have not added any folders yet.', style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _handleAddFolder,
                                          icon: const Icon(Icons.add, color: Colors.black),
                                          label: const Text('Add New Folder', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 24,
                                      mainAxisSpacing: 24,
                                      childAspectRatio: 1.5,
                                    ),
                                    itemCount: courses.length,
                                    itemBuilder: (context, index) {
                                      return _buildCourseCard(courses[index]);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      key: const ValueKey(2),
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          const Text('Watch History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 24),
                          Expanded(
                            child: history.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.history_toggle_off, size: 100, color: Colors.white24),
                                        SizedBox(height: 24),
                                        Text('You have not watched anything yet.', style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 16),
                                        Text('Play a video to show your history here.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 24,
                                      mainAxisSpacing: 24,
                                      childAspectRatio: 16 / 9,
                                    ),
                                    itemCount: history.length,
                                    itemBuilder: (context, index) {
                                      return _buildHistoryCard(history[index]);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
        ),
          
        // Top right utilities
        Positioned(
          top: 24,
          right: 32,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, size: 28, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(List courses) {
    if (courses.isEmpty) {
      return Container(
        height: 600,
        width: double.infinity,
        decoration: BoxDecoration(color: Theme.of(context).cardColor),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie_creation_outlined, size: 100, color: Colors.white24),
              const SizedBox(height: 24),
              const Text('You have not added any folders yet.', style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleAddFolder,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Add New Folder', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }

    final featured = courses.first;
    return Stack(
      children: [
        Container(
          height: 600,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            image: featured.thumbnailPath.isNotEmpty
                ? DecorationImage(image: FileImage(File(featured.thumbnailPath)), fit: BoxFit.cover, alignment: Alignment.topCenter)
                : null,
          ),
          child: featured.thumbnailPath.isEmpty ? _buildAutoThumbnail(featured.title) : null,
        ),
        // Royal Vignette & Left Gradient
        Container(
          height: 600,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
              stops: const [0.1, 1.0],
            ),
          ),
        ),
        // Cinematic Bottom Gradient matching Netflix exactly
        Container(
          height: 600,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.3), Colors.transparent, const Color(0xFF141414)],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 48,
          right: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                featured.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 72, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -2, 
                  height: 1.0, 
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 10))]
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${featured.moduleIds.length} MODULES', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(3)),
                    child: const Text('HD', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => CourseScreen(course: featured)));
                      ref.read(historyProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                    label: const Text('Play', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 8,
                      shadowColor: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, color: Colors.white, size: 32),
                    label: const Text('More Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueWatching(List<HistoryItem> history) {
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Continue Watching', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Center(
                child: Text('You have not watched anything yet. Play a video to show your history here.', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Row(
            children: [
              const Text('Continue Watching', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 320,
                  child: _buildHistoryCard(history[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    int secondsLeft = item.lecture.duration.inSeconds - item.lecture.lastPositionSeconds;
    String timeLeftText = '';
    
    if (item.lecture.duration.inSeconds <= 0) {
      timeLeftText = 'Resume';
    } else if (secondsLeft <= 0) {
      timeLeftText = 'Completed';
    } else {
      int hoursLeft = secondsLeft ~/ 3600;
      int minsLeft = (secondsLeft % 3600) ~/ 60;
      if (hoursLeft > 0) {
        timeLeftText = '${hoursLeft}h ${minsLeft}m left';
      } else if (minsLeft > 0) {
        timeLeftText = '${minsLeft}m left';
      } else {
        timeLeftText = '< 1m left';
      }
    }
    
    return HoverableCard(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => CourseScreen(course: item.course)));
        ref.read(historyProvider.notifier).refresh();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      image: item.lecture.thumbnailPath.isNotEmpty
                          ? DecorationImage(image: FileImage(File(item.lecture.thumbnailPath)), fit: BoxFit.cover)
                          : item.course.thumbnailPath.isNotEmpty
                              ? DecorationImage(image: FileImage(File(item.course.thumbnailPath)), fit: BoxFit.cover)
                              : null,
                    ),
                    child: item.lecture.thumbnailPath.isEmpty && item.course.thumbnailPath.isEmpty
                        ? _buildAutoThumbnail(item.lecture.title)
                        : null,
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      alignment: Alignment.centerLeft,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: item.lecture.watchProgressPercentage / 100.0,
                        child: Container(color: const Color(0xFFE50914)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () {
                          ref.read(historyProvider.notifier).removeFromHistory(item.lecture);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Removed from Continue Watching'),
                            backgroundColor: Colors.grey,
                            duration: Duration(seconds: 2),
                          ));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(item.lecture.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(item.course.title.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12))),
              const SizedBox(width: 8),
              Text(timeLeftText, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllCoursesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('All Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _handleAddFolder,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('SCAN FOLDER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white70,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddFolder() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      await ref.read(coursesProvider.notifier).addRootFolder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Courses scanned successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error scanning folder: $e'),
          backgroundColor: Theme.of(context).primaryColor,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Widget _buildCoursesList(List courses) {
    if (courses.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('You have not added any folders yet. Add a new folder to begin.', style: TextStyle(color: Colors.white54))),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 320,
              child: _buildCourseCard(courses[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return HoverableCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CourseScreen(course: course)),
        );
        ref.read(historyProvider.notifier).refresh();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                image: course.thumbnailPath.isNotEmpty
                    ? DecorationImage(image: FileImage(File(course.thumbnailPath)), fit: BoxFit.cover)
                    : null,
              ),
              child: course.thumbnailPath.isEmpty
                  ? _buildAutoThumbnail(course.title)
                  : null,
            ),
            // Cinematic shadow from bottom to make text readable
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [const Color(0xFF141414).withOpacity(0.95), const Color(0xFF141414).withOpacity(0.3), Colors.transparent],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('${course.moduleIds.length} MODULES', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ),
            // Royal thin border on top
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoThumbnail(String title) {
    int hash = 0;
    for (int i = 0; i < title.length; i++) {
      hash = title.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    final List<List<Color>> gradients = [
      [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)], // Sunset
      [const Color(0xFF009FFF), const Color(0xFFec2F4B)], // Cyberpunk
      [const Color(0xFF1D976C), const Color(0xFF93F9B9)], // Emerald
      [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Neon Green
      [const Color(0xFF4568DC), const Color(0xFFB06AB3)], // Twilight
      [const Color(0xFFff9966), const Color(0xFFff5e62)], // Peach
      [const Color(0xFF0f0c29), const Color(0xFF302b63), const Color(0xFF24243e)], // Deep Space
      [const Color(0xFFC33764), const Color(0xFF1D2671)], // Royal
    ];
    
    final gradient = gradients[hash.abs() % gradients.length];
    final String initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.movie_creation_outlined, size: 160, color: Colors.white.withOpacity(0.08)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.25),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 42,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
