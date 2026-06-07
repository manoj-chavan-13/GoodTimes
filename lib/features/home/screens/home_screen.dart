import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/features/settings/screens/settings_screen.dart';
import 'package:goodtimes/features/about/screens/about_screen.dart';
import 'package:goodtimes/widgets/animations.dart';
import 'package:goodtimes/features/folder/screens/course_screen.dart';
import 'package:goodtimes/providers/course_provider.dart';
import 'package:goodtimes/providers/history_provider.dart';
import 'package:goodtimes/providers/settings_provider.dart';
import 'package:goodtimes/widgets/hoverable_card.dart';
import 'package:goodtimes/models/course_model.dart';
import 'package:goodtimes/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:goodtimes/providers/scan_provider.dart';
import 'package:goodtimes/core/themes/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isScanning = false;
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  String _searchQuery = '';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const CustomTitleBar(isTransparent: false),
          Expanded(
            child: Row(
              children: [
                // GLOBAL SIDEBAR
                _buildSidebar(),
                
                // MAIN CONTENT & HEADER COLUMN
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeader(),
                      Expanded(
                        child: Stack(
                          children: [
                            _buildMainContent(courses, history),
                            if (_isScanning)
                              Container(
                                color: Colors.black.withOpacity(0.8),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Theme.of(context).primaryColor),
                                      const SizedBox(height: 16),
                                      Text('Scanning for courses...', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    if (_isSidebarCollapsed) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textFaint(context),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMuted(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: InkWell(
        onTap: () {
          if (index == 4) {
            setState(() => _selectedIndex = 4);
          } else if (index < 4) {
            if (index == 3) {
              ref.read(settingsActiveTabProvider.notifier).setTab(0);
            }
            setState(() => _selectedIndex = index);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title is coming soon!'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.sidebarSelected(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sidebarSelected(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icon,
                  key: ValueKey('$index-$isSelected'),
                  color: color,
                  size: 20,
                ),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: isSelected ? AppColors.text(context) : AppColors.textMuted(context),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final courses = ref.watch(coursesProvider);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? 80 : 250,
      decoration: BoxDecoration(
        color: AppColors.sidebar(context),
        border: Border(
          right: BorderSide(
            color: AppColors.border(context),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 16.0 : 24.0, vertical: 24.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: AppColors.text(context), size: 24),
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'lib/assets/icon.png',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebarSectionHeader('MAIN'),
                  _buildSidebarItem(Icons.home_outlined, 'Home', 0),
                  _buildSidebarItem(Icons.folder_copy_outlined, 'Library', 1),
                  _buildSidebarItem(Icons.play_circle_outline, 'Continue Watching', 2),
                  
                  _buildSidebarSectionHeader('SYSTEM'),
                  _buildSidebarItem(Icons.settings_outlined, 'Settings', 3),
                  _buildSidebarItem(Icons.info_outline, 'About', 4),
                  
                  if (!_isSidebarCollapsed && courses.isEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder_open, color: AppColors.textMuted(context), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No Root Folder',
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Select a root folder to load courses.',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: _handleAddFolder,
                                icon: const Icon(Icons.folder, size: 14, color: Colors.white),
                                label: const Text(
                                  'Open Folder',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.sidebar(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border(context),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (_isSidebarCollapsed) ...[
            Text(
              'GoodTime',
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 32),
          ],
          
          // Search Box
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: AppColors.textMuted(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search courses...',
                          hintStyle: TextStyle(
                            color: AppColors.textFaint(context),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 13,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Text(
                        'Ctrl + F',
                        style: TextStyle(
                          color: AppColors.textFaint(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Help Button
          IconButton(
            icon: Icon(Icons.help_outline, color: AppColors.textMuted(context), size: 20),
            tooltip: 'Help',
            onPressed: () {
              ref.read(settingsActiveTabProvider.notifier).setTab(1); // How to Use
              setState(() => _selectedIndex = 3); // Go to Settings
            },
          ),
          
          // Quick Settings Button
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.textMuted(context), size: 20),
            tooltip: 'Settings',
            onPressed: () {
              ref.read(settingsActiveTabProvider.notifier).setTab(0); // Preferences
              setState(() => _selectedIndex = 3); // Go to Settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F0F10), // Obsidian
                  const Color(0xFF161618), // Charcoal
                ]
              : [
                  const Color(0xFFF3F4F6), // Light grey tint
                  Colors.white,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Abstract background decorative circles
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              child: Row(
                children: [
                  // Text Content Left
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEW RELEASE v1.0.1',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Master Your Craft with GoodTime',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Organize your learning path, track progress dynamically, and review study notes in a single unified dashboard.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted(context),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _handleAddFolder,
                          icon: const Icon(Icons.folder_open, size: 16, color: Colors.white),
                          label: const Text(
                            'Open Root Folder',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // GoodTime Brand Logo on Right
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 145,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'lib/assets/icon.png',
                            height: 96,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyAddedBanner(CourseModel course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderStrong(context) : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2C2C35), // Dark Elevated Grey
                  const Color(0xFF222228), // Matches page background
                ]
              : [
                  const Color(0xFFFEE2E2), // Light Brand Red tint
                  Colors.white,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'RECENTLY ADDED',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Continue your education and master this subject. Click open below to browse all modules and start learning.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted(context),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              FadeSlidePageRoute(
                                page: CourseScreen(course: course),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline, size: 16, color: Colors.white),
                          label: const Text(
                            'Open Course',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: course.thumbnailPath.isNotEmpty && File(course.thumbnailPath).existsSync()
                            ? Image.file(
                                File(course.thumbnailPath),
                                fit: BoxFit.cover,
                              )
                            : _buildAutoThumbnail(course.title),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List courses, List<HistoryItem> history) {
    // ── Shared data ──────────────────────────────────────────────────────────
    final filteredCourses = courses.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery);
    }).toList();

    CourseModel? recentlyAddedCourse;
    if (courses.isNotEmpty) {
      final sorted = List<CourseModel>.from(courses)
        ..sort((a, b) => b.lastScanned.compareTo(a.lastScanned));
      recentlyAddedCourse = sorted.first;
    }

    // ── Decide which page widget to show ─────────────────────────────────────
    // Every page gets a stable ValueKey so AnimatedSwitcher detects the swap
    // and plays the transition. Settings & About are now included here too,
    // so every navigation uses exactly the same transition.
    final Widget page;

    switch (_selectedIndex) {
      case 3:
        page = const SettingsScreen(key: ValueKey('settings'));
        break;
      case 4:
        page = const AboutScreen(key: ValueKey('about'));
        break;
      case 1:
        page = Padding(
          key: const ValueKey('library'),
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAllCoursesHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open, size: 80, color: AppColors.textFaint(context)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No courses added yet.'
                                  : 'No courses match "$_searchQuery"',
                              style: TextStyle(color: AppColors.textMuted(context), fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) => _buildCourseCard(filteredCourses[index]),
                      ),
              ),
            ],
          ),
        );
        break;
      case 2:
        page = Padding(
          key: const ValueKey('continue'),
          padding: const EdgeInsets.all(48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Continue Watching',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              const SizedBox(height: 24),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_toggle_off, size: 80, color: AppColors.textFaint(context)),
                            const SizedBox(height: 16),
                            Text('You have not watched anything yet.',
                                style: TextStyle(color: AppColors.textMuted(context), fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: history.length,
                        itemBuilder: (context, index) => _buildHistoryCard(history[index]),
                      ),
              ),
            ],
          ),
        );
        break;
      default: // 0 = Home
        page = SingleChildScrollView(
          key: const ValueKey('home'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarouselHero(
                welcomeBanner: _buildWelcomeBanner(),
                recentCourseBanner: recentlyAddedCourse != null
                    ? _buildRecentlyAddedBanner(recentlyAddedCourse)
                    : null,
              ),
              const SizedBox(height: 16),
              _buildContinueWatching(history),
              const SizedBox(height: 32),
              _buildAllCoursesHeader(),
              const SizedBox(height: 16),
              _buildCoursesList(filteredCourses),
              const SizedBox(height: 64),
            ],
          ),
        );
    }

    // ── Single transition hub for every page ─────────────────────────────────
    return ScreenSwitcher(child: page);
  }

  Widget _buildContinueWatching(List<HistoryItem> history) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Row(
            children: [
              Text(
                'Continue Watching',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 300,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return HoverableCard(
      onTap: () async {
        await Navigator.push(context, FadeSlidePageRoute(page: CourseScreen(course: item.course)));
        ref.read(historyProvider.notifier).refresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.sidebarSelected(context) : const Color(0xFFF3F4F6),
                        image: item.lecture.thumbnailPath.isNotEmpty
                            ? DecorationImage(image: FileImage(File(item.lecture.thumbnailPath)), fit: BoxFit.cover)
                            : item.course.thumbnailPath.isNotEmpty
                                ? DecorationImage(image: FileImage(File(item.course.thumbnailPath)), fit: BoxFit.cover)
                                : null,
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor, size: 24),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        alignment: Alignment.centerLeft,
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                        child: FractionallySizedBox(
                          widthFactor: item.lecture.watchProgressPercentage / 100.0,
                          child: Container(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 14),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () {
                            ref.read(historyProvider.notifier).removeFromHistory(item.lecture);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.border(context)),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.lecture.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.lecture.watchProgressPercentage}% Completed',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCoursesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('All Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          ElevatedButton.icon(
            onPressed: _handleAddFolder,
            icon: const Icon(Icons.folder_open, size: 16, color: Colors.white),
            label: const Text('SCAN FOLDER', style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddFolder() async {
    setState(() => _isScanning = true);
    try {
      final result = await ref.read(coursesProvider.notifier).addRootFolder();
      if (mounted) {
        _showScanResultDialog(context, result);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
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

  Widget _buildCoursesList(List courses) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: SizedBox(width: 300, child: _buildCourseCard(courses[index])),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return HoverableCard(
      onTap: () => Navigator.push(context, FadeSlidePageRoute(page: CourseScreen(course: course))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: course.thumbnailPath.isNotEmpty && File(course.thumbnailPath).existsSync()
                    ? Image.file(
                        File(course.thumbnailPath),
                        fit: BoxFit.cover,
                      )
                    : _buildAutoThumbnail(course.title),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.video_library_outlined, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${course.moduleIds.length} Modules',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoThumbnail(String title) {
    int hash = title.codeUnits.fold(0, (prev, code) => code + ((prev << 5) - prev));
    final List<List<Color>> gradients = [
      [const Color(0xFF8A2387), const Color(0xFFE94057)],
      [const Color(0xFF009FFF), const Color(0xFFec2F4B)],
    ];
    final gradient = gradients[hash.abs() % gradients.length];
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
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

class CarouselHero extends StatefulWidget {
  final Widget welcomeBanner;
  final Widget? recentCourseBanner;
  const CarouselHero({
    super.key,
    required this.welcomeBanner,
    this.recentCourseBanner,
  });

  @override
  State<CarouselHero> createState() => _CarouselHeroState();
}

class _CarouselHeroState extends State<CarouselHero> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.recentCourseBanner != null) {
      _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
        if (_currentPage < 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(CarouselHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recentCourseBanner != oldWidget.recentCourseBanner) {
      _currentPage = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recentCourseBanner == null) {
      return widget.welcomeBanner;
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              widget.welcomeBanner,
              widget.recentCourseBanner!,
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.textFaint(context).withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
