import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:goodtimes/models/course_model.dart';
import 'package:goodtimes/models/module_model.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/providers/module_provider.dart';
import 'package:goodtimes/providers/lecture_provider.dart';
import 'package:goodtimes/providers/player_provider.dart';
import 'package:goodtimes/providers/settings_provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:goodtimes/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';

class CourseScreen extends ConsumerStatefulWidget {
  final CourseModel course;
  const CourseScreen({super.key, required this.course});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  LectureModel? _currentLecture;
  bool _isSidebarOpen = false;
  StreamSubscription<bool>? _completedSub;

  @override
  void dispose() {
    _completedSub?.cancel();
    windowManager.setTitle('GoodTime');
    super.dispose();
  }

  void _setLecture(LectureModel lecture) {
    setState(() => _currentLecture = lecture);
    windowManager.setTitle('${widget.course.title} - ${lecture.title}');
    _completedSub?.cancel();
    
    Future.microtask(() {
      final playerController = ref.read(playerProvider(lecture));
      _completedSub = playerController.player.stream.completed.listen((completed) {
        if (completed && mounted) {
          final settings = ref.read(settingsProvider);
          if (settings.autoplay) {
            _playNextLecture();
          }
        }
      });
    });
  }

  void _playNextLecture() {
    if (_currentLecture == null) return;
    final modules = ref.read(modulesProvider(widget.course.id));
    
    for (int i = 0; i < modules.length; i++) {
      final module = modules[i];
      final lectures = ref.read(lecturesProvider(module.id));
      final currentIdx = lectures.indexWhere((l) => l.id == _currentLecture!.id);
      
      if (currentIdx != -1) {
        // Found it
        if (currentIdx + 1 < lectures.length) {
          // Next in same module
          _setLecture(lectures[currentIdx + 1]);
        } else if (i + 1 < modules.length) {
          // Next in next module
          final nextLectures = ref.read(lecturesProvider(modules[i + 1].id));
          if (nextLectures.isNotEmpty) {
            _setLecture(nextLectures.first);
          }
        }
        break;
      }
    }
  }

  void _playPreviousLecture() {
    if (_currentLecture == null) return;
    final modules = ref.read(modulesProvider(widget.course.id));
    
    for (int i = 0; i < modules.length; i++) {
      final module = modules[i];
      final lectures = ref.read(lecturesProvider(module.id));
      final currentIdx = lectures.indexWhere((l) => l.id == _currentLecture!.id);
      
      if (currentIdx != -1) {
        if (currentIdx - 1 >= 0) {
          _setLecture(lectures[currentIdx - 1]);
        } else if (i - 1 >= 0) {
          final prevLectures = ref.read(lecturesProvider(modules[i - 1].id));
          if (prevLectures.isNotEmpty) {
            _setLecture(prevLectures.last);
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(modulesProvider(widget.course.id));

    // Auto-select first lecture if none selected
    if (_currentLecture == null && modules.isNotEmpty) {
      Future.microtask(() {
        final firstModLectures = ref.read(lecturesProvider(modules.first.id));
        if (firstModLectures.isNotEmpty && mounted) {
          _setLecture(firstModLectures.first);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          CustomTitleBar(
            isTransparent: true,
            title: _currentLecture != null ? '${widget.course.title} - ${_currentLecture!.title}' : widget.course.title,
          ),
          Expanded(
            child: Stack(
              children: [
                // Video Player Background
                Positioned.fill(
                  child: _currentLecture == null
                      ? const Center(child: CircularProgressIndicator(color: Colors.red))
                      : _buildPlayerArea(_currentLecture!),
                ),

          // Animated Sidebar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,
            right: _isSidebarOpen ? 0 : -400,
            width: 400,
            child: Material(
              color: const Color(0xFF141414).withOpacity(0.98), // Deep Netflix dark
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('COURSE', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            Text(widget.course.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => setState(() => _isSidebarOpen = false),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        return _buildModuleSection(modules[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
);
  }

  Widget _buildPlayerArea(LectureModel lecture) {
    final controller = ref.watch(playerProvider(lecture));
    
    final topBar = [
      IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.course.title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(lecture.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      MaterialCustomButton(
        onPressed: _playPreviousLecture,
        icon: const Icon(Icons.skip_previous_outlined, color: Colors.white, size: 24),
      ),
      MaterialCustomButton(
        onPressed: _playNextLecture,
        icon: const Icon(Icons.skip_next_outlined, color: Colors.white, size: 24),
      ),
      const MaterialDesktopVolumeButton(),
      const MaterialFullscreenButton(),
      const SizedBox(width: 16),
      ElevatedButton.icon(
        onPressed: () => setState(() => _isSidebarOpen = true),
        icon: const Icon(Icons.list, color: Colors.white, size: 18),
        label: const Text('Episodes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      const SizedBox(width: 24),
    ];

    final bottomBar = [
      const MaterialPlayOrPauseButton(iconSize: 32),
      MaterialCustomButton(
        onPressed: _playPreviousLecture,
        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
      ),
      MaterialCustomButton(
        onPressed: _playNextLecture,
        icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
      ),
      const MaterialPositionIndicator(),
      Builder(
        builder: (btnContext) => IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
          tooltip: 'Playback Speed',
          onPressed: () {
            showDialog(
              context: btnContext,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF141414),
                title: const Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                    return ListTile(
                      leading: const Icon(Icons.speed, color: Colors.white70),
                      title: Text('${speed}x', style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        controller.player.setRate(speed);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    ];

    return MaterialDesktopVideoControlsTheme(
      key: ValueKey(lecture.id),
      normal: MaterialDesktopVideoControlsThemeData(
        topButtonBar: topBar,
        bottomButtonBar: bottomBar,
        topButtonBarMargin: const EdgeInsets.only(top: 40, left: 24, right: 24),
        bottomButtonBarMargin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        seekBarMargin: const EdgeInsets.only(bottom: 10, left: 24, right: 24),
        seekBarPositionColor: Theme.of(context).primaryColor,
        seekBarThumbColor: Theme.of(context).primaryColor,
      ),
      fullscreen: MaterialDesktopVideoControlsThemeData(
        topButtonBar: topBar,
        bottomButtonBar: bottomBar,
        topButtonBarMargin: const EdgeInsets.only(top: 40, left: 24, right: 24),
        bottomButtonBarMargin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        seekBarMargin: const EdgeInsets.only(bottom: 10, left: 24, right: 24),
        seekBarPositionColor: Theme.of(context).primaryColor,
        seekBarThumbColor: Theme.of(context).primaryColor,
      ),
      child: Video(
        controller: controller.controller,
        controls: MaterialDesktopVideoControls,
      ),
    );
  }

  Widget _buildModuleSection(ModuleModel module) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: Colors.transparent,
        title: Text(module.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13, letterSpacing: 1.2)),
      children: [
        Consumer(
          builder: (context, ref, child) {
            final lectures = ref.watch(lecturesProvider(module.id));
            return Column(
              children: lectures.asMap().entries.map((entry) {
                final index = entry.key;
                final lecture = entry.value;
                final isSelected = _currentLecture?.id == lecture.id;
                final primaryColor = Theme.of(context).primaryColor;

                return InkWell(
                  onTap: () {
                    _setLecture(lecture);
                    setState(() {
                      _isSidebarOpen = false;
                    });
                  },
                  hoverColor: Colors.white.withOpacity(0.02),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildEpisodeThumbnail(lecture, index, isSelected),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lecture.title,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (lecture.watchProgressPercentage > 0)
                                Text('${lecture.watchProgressPercentage}% watched', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        )
      ],
    ),
    );
  }

  Widget _buildEpisodeThumbnail(LectureModel lecture, int index, bool isSelected) {
    final title = lecture.title;
    final progress = lecture.watchProgressPercentage;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      width: 110,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? primaryColor : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1),
        color: const Color(0xFF141414),
        image: lecture.thumbnailPath.isNotEmpty
            ? DecorationImage(image: FileImage(File(lecture.thumbnailPath)), fit: BoxFit.cover)
            : null,
        boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                ),
              ),
            ),
            if (lecture.thumbnailPath.isEmpty)
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(Icons.movie, size: 50, color: Colors.white.withOpacity(0.05)),
              ),
            Center(
              child: isSelected 
                ? const Icon(Icons.play_arrow, color: Colors.white, size: 32)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      'EP ${index + 1}', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                    ),
                  ),
            ),
            if (progress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: Colors.white24,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress / 100.0,
                    child: Container(color: primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
