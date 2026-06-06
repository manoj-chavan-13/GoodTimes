import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:goodtimes/widgets/custom_title_bar.dart';
import 'package:goodtimes/widgets/animations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:goodtimes/core/themes/app_colors.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CourseScreen extends ConsumerStatefulWidget {
  final CourseModel course;
  const CourseScreen({super.key, required this.course});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  LectureModel? _currentLecture;
  bool _isSidebarOpen = true; // Sidebar open by default matching mockup
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<double>? _volumeSub;
  double _lastVolume = 50.0;
  final Map<String, List<File>> _pdfCache = {};
  final Set<String> _expandedModuleIds = {};

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = true;
    
    // Start background sequential thumbnail generation for this course
    Future.microtask(() async {
      await ThumbnailGenerator.generateThumbnailsForCourse(widget.course.id);
      if (mounted) {
        // Invalidate the provider to refresh UI with screenshots
        ref.invalidate(modulesProvider(widget.course.id));
        final modules = ref.read(modulesProvider(widget.course.id));
        for (var mod in modules) {
          ref.invalidate(lecturesProvider(mod.id));
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _completedSub?.cancel();
    _playingSub?.cancel();
    _volumeSub?.cancel();
    windowManager.setTitle('GoodTime');
    super.dispose();
  }

  void _setLecture(LectureModel lecture) {
    setState(() {
      _currentLecture = lecture;
      _expandedModuleIds.add(lecture.moduleId); // Auto-expand only the active module
      _pdfCache.clear(); // Clear cached PDFs to refresh on new lecture
    });
    windowManager.setTitle('${widget.course.title} - ${lecture.title}');
    _completedSub?.cancel();
    _playingSub?.cancel();
    _volumeSub?.cancel();
    
    Future.microtask(() {
      final playerController = ref.read(playerProvider(lecture));
      final player = playerController.player;
      final speed = ref.read(playbackSpeedProvider);

      // Listen to playing events and apply the playback rate
      _playingSub = player.stream.playing.listen((playing) {
        final currentSpeed = ref.read(playbackSpeedProvider);
        if (playing && player.state.rate != currentSpeed) {
          player.setRate(currentSpeed);
        }
        if (mounted) setState(() {});
      });

      // Apply rate directly and with safe delays to handle video loading transitions
      player.setRate(speed);
      Future.delayed(const Duration(milliseconds: 300), () {
        final currentSpeed = ref.read(playbackSpeedProvider);
        if (mounted && player.state.rate != currentSpeed) {
          player.setRate(currentSpeed);
        }
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        final currentSpeed = ref.read(playbackSpeedProvider);
        if (mounted && player.state.rate != currentSpeed) {
          player.setRate(currentSpeed);
        }
      });

      _volumeSub = player.stream.volume.listen((volume) {
        if (mounted) setState(() {});
      });

      _completedSub = player.stream.completed.listen((completed) {
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
        if (currentIdx + 1 < lectures.length) {
          _setLecture(lectures[currentIdx + 1]);
        } else if (i + 1 < modules.length) {
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

  List<File> _getPdfsInModule(String folderPath) {
    if (_pdfCache.containsKey(folderPath)) {
      return _pdfCache[folderPath]!;
    }
    try {
      final dir = Directory(folderPath);
      if (dir.existsSync()) {
        final pdfs = dir
            .listSync(followLinks: false)
            .whereType<File>()
            .where((file) => p.extension(file.path).toLowerCase() == '.pdf')
            .toList()
          ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
        _pdfCache[folderPath] = pdfs;
        return pdfs;
      }
    } catch (e) {
      print('Error listing PDFs: $e');
    }
    _pdfCache[folderPath] = [];
    return [];
  }

  void _openPdf(String pdfPath) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', [pdfPath]);
      }
    } catch (e) {
      print('Error opening PDF: $e');
    }
  }

  bool _isPlaying(LectureModel lecture) {
    try {
      final playerController = ref.read(playerProvider(lecture));
      return playerController.player.state.playing;
    } catch (_) {
      return false;
    }
  }

  void _togglePlay(LectureModel lecture) {
    try {
      final playerController = ref.read(playerProvider(lecture));
      playerController.player.playOrPause();
    } catch (_) {}
  }

  bool _isMuted(LectureModel lecture) {
    try {
      final playerController = ref.read(playerProvider(lecture));
      return playerController.player.state.volume == 0.0;
    } catch (_) {
      return false;
    }
  }

  void _toggleMute(LectureModel lecture) {
    try {
      final playerController = ref.read(playerProvider(lecture));
      final player = playerController.player;
      if (player.state.volume > 0.0) {
        _lastVolume = player.state.volume;
        player.setVolume(0.0);
      } else {
        player.setVolume(_lastVolume > 0.0 ? _lastVolume : 50.0);
      }
    } catch (_) {}
  }

  void _showNotesDialog(LectureModel lecture) async {
    final notesBox = await Hive.openBox<String>('notesBox');
    final initialNote = notesBox.get(lecture.id) ?? '';
    final controller = TextEditingController(text: initialNote);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notes: ${lecture.title}',
                style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            maxLines: 8,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Write down important points or key take-aways...',
              hintStyle: TextStyle(color: AppColors.textFaint(context)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.02)
                  : Colors.black.withOpacity(0.01),
              filled: true,
            ),
            style: TextStyle(color: AppColors.text(context), fontSize: 13),
          ),
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
              await notesBox.put(lecture.id, controller.text);
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes saved successfully.'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSpeedToast(double speed) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.speed, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                'Speed: ${speed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        width: 140, // Compact size prevents any text overflows
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    final logicalKey = event.logicalKey;
    final lecture = _currentLecture;
    if (lecture == null) return;
    
    final playerController = ref.read(playerProvider(lecture));
    final player = playerController.player;

    final currentSpeed = ref.read(playbackSpeedProvider);
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    
    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);

    if (logicalKey == LogicalKeyboardKey.space) {
      player.playOrPause();
    } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      final pos = player.state.position;
      player.seek(pos - const Duration(seconds: 10));
    } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
      final pos = player.state.position;
      player.seek(pos + const Duration(seconds: 10));
    } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
      final vol = player.state.volume;
      player.setVolume((vol + 5.0).clamp(0.0, 100.0));
    } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
      final vol = player.state.volume;
      player.setVolume((vol - 5.0).clamp(0.0, 100.0));
    } else if (logicalKey == LogicalKeyboardKey.keyM) {
      _toggleMute(lecture);
    } else if (logicalKey == LogicalKeyboardKey.keyN) {
      _playNextLecture();
    } else if (logicalKey == LogicalKeyboardKey.keyP) {
      _playPreviousLecture();
    } else if (logicalKey == LogicalKeyboardKey.keyF) {
      windowManager.isFullScreen().then((isFS) {
        windowManager.setFullScreen(!isFS);
      });
    } else if (isShiftPressed && logicalKey == LogicalKeyboardKey.period) {
      // Shift + > to increase speed
      final currentIndex = speeds.indexOf(currentSpeed);
      if (currentIndex != -1 && currentIndex < speeds.length - 1) {
        final newSpeed = speeds[currentIndex + 1];
        ref.read(playbackSpeedProvider.notifier).setSpeed(newSpeed);
        player.setRate(newSpeed);
        _showSpeedToast(newSpeed);
      }
    } else if (isShiftPressed && logicalKey == LogicalKeyboardKey.comma) {
      // Shift + < to decrease speed
      final currentIndex = speeds.indexOf(currentSpeed);
      if (currentIndex != -1 && currentIndex > 0) {
        final newSpeed = speeds[currentIndex - 1];
        ref.read(playbackSpeedProvider.notifier).setSpeed(newSpeed);
        player.setRate(newSpeed);
        _showSpeedToast(newSpeed);
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
      backgroundColor: AppColors.bg(context),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            _handleKeyPress(event);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            // Standard Custom Header with controls
            _buildTopHeader(_currentLecture),
            
            Expanded(
              child: Row(
                children: [
                  // Main Player Content Section
                  Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.black, // Cinematic black viewport box for player
                              child: _currentLecture == null
                                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                  : ScreenSwitcher(
                                      child: KeyedSubtree(
                                        key: ValueKey(_currentLecture!.id),
                                        child: _buildPlayerArea(_currentLecture!),
                                      ),
                                    ),
                            ),
                          ),
                          if (_currentLecture != null)
                            _buildBottomStatusBar(_currentLecture!),
                        ],
                      ),
                  ),
                  
                  // Course Content Sidebar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: _isSidebarOpen ? 400 : 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: 400,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.border(context),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'COURSE CONTENT',
                                            style: TextStyle(
                                              color: AppColors.textMuted(context),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.course.title,
                                            style: TextStyle(
                                              color: AppColors.text(context),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close, color: AppColors.text(context), size: 24),
                                      onPressed: () => setState(() => _isSidebarOpen = false),
                                    ),
                                  ],
                                ),
                              ),
                              
                              Divider(color: AppColors.border(context).withOpacity(0.3), height: 1),
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

  Widget _buildTopHeader(LectureModel? currentLecture) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.card(context),
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
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.text(context), size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.course.title,
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (currentLecture != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    currentLecture.title,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          if (currentLecture != null) ...[
            IconButton(
              icon: Icon(Icons.skip_previous_outlined, color: AppColors.text(context), size: 22),
              onPressed: _playPreviousLecture,
              tooltip: 'Previous Lecture (P)',
            ),
            IconButton(
              icon: Icon(
                _isPlaying(currentLecture) ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: AppColors.text(context),
                size: 24,
              ),
              onPressed: () => _togglePlay(currentLecture),
              tooltip: 'Play/Pause (Space)',
            ),
            IconButton(
              icon: Icon(Icons.skip_next_outlined, color: AppColors.text(context), size: 22),
              onPressed: _playNextLecture,
              tooltip: 'Next Lecture (N)',
            ),
            IconButton(
              icon: Icon(
                _isMuted(currentLecture) ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                color: AppColors.text(context),
                size: 22,
              ),
              onPressed: () => _toggleMute(currentLecture),
              tooltip: 'Mute/Unmute (M)',
            ),
            const SizedBox(width: 8),
            
            ElevatedButton.icon(
              onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
              icon: Icon(
                _isSidebarOpen ? Icons.grid_view : Icons.grid_view_outlined,
                size: 16,
                color: _isSidebarOpen ? Colors.white : AppColors.text(context),
              ),
              label: Text(
                'Episodes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _isSidebarOpen ? Colors.white : AppColors.text(context),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSidebarOpen ? AppColors.primary : Colors.transparent,
                shadowColor: Colors.transparent,
                side: BorderSide(
                  color: _isSidebarOpen ? AppColors.primary : AppColors.border(context),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar(LectureModel currentLecture) {
    final settings = ref.watch(settingsProvider);
    
    // Find next episode title
    String nextEpisodeTitle = 'None';
    final modules = ref.read(modulesProvider(widget.course.id));
    LectureModel? nextLecture;
    for (int i = 0; i < modules.length; i++) {
      final module = modules[i];
      final lectures = ref.read(lecturesProvider(module.id));
      final currentIdx = lectures.indexWhere((l) => l.id == currentLecture.id);
      if (currentIdx != -1) {
        if (currentIdx + 1 < lectures.length) {
          nextLecture = lectures[currentIdx + 1];
        } else if (i + 1 < modules.length) {
          final nextLectures = ref.read(lecturesProvider(modules[i + 1].id));
          if (nextLectures.isNotEmpty) {
            nextLecture = nextLectures.first;
          }
        }
        break;
      }
    }
    if (nextLecture != null) {
      nextEpisodeTitle = nextLecture.title;
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(Icons.autorenew_outlined, size: 18, color: AppColors.textMuted(context)),
          const SizedBox(width: 8),
          Text(
            'Auto Play',
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: settings.autoplay,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: AppColors.border(context),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleAutoplay(val);
            },
          ),
          
          // Expanded and ellipsis-safe layout to prevent overflows!
          const SizedBox(width: 16),
          if (nextLecture != null)
            Expanded(
              child: Center(
                child: Text(
                  'Next: $nextEpisodeTitle',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          
          OutlinedButton.icon(
            onPressed: () => _showNotesDialog(currentLecture),
            icon: Icon(Icons.edit_note, size: 18, color: AppColors.text(context)),
            label: Text(
              'Notes',
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          
          ElevatedButton.icon(
            onPressed: () async {
              final updatedLecture = LectureModel(
                id: currentLecture.id,
                moduleId: currentLecture.moduleId,
                courseId: currentLecture.courseId,
                title: currentLecture.title,
                filePath: currentLecture.filePath,
                duration: currentLecture.duration,
                watchProgressPercentage: currentLecture.isCompleted ? 0 : 100,
                lastPositionSeconds: currentLecture.isCompleted ? 0 : currentLecture.duration.inSeconds,
                isCompleted: !currentLecture.isCompleted,
                lastWatched: DateTime.now(),
                thumbnailPath: currentLecture.thumbnailPath,
              );
              await HiveBoxes.getLecturesBox().put(updatedLecture.id, updatedLecture);
              ref.invalidate(lecturesProvider(currentLecture.moduleId));
              setState(() {
                _currentLecture = updatedLecture;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(updatedLecture.isCompleted ? 'Marked lecture as completed!' : 'Marked lecture as incomplete.'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            icon: Icon(
              currentLecture.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              currentLecture.isCompleted ? 'Completed' : 'Mark Complete',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentLecture.isCompleted ? Colors.green : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea(LectureModel lecture) {
    final controller = ref.watch(playerProvider(lecture));
    
    final bottomBarWidgets = [
      IconButton(
        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20),
        tooltip: 'Previous Video',
        onPressed: _playPreviousLecture,
      ),
      IconButton(
        icon: const Icon(Icons.replay_10, color: Colors.white, size: 20),
        tooltip: 'Seek Backward 10s',
        onPressed: () {
          final playerController = ref.read(playerProvider(lecture));
          final currentPos = playerController.player.state.position;
          playerController.player.seek(currentPos - const Duration(seconds: 10));
        },
      ),
      const MaterialPlayOrPauseButton(),
      IconButton(
        icon: const Icon(Icons.forward_10, color: Colors.white, size: 20),
        tooltip: 'Seek Forward 10s',
        onPressed: () {
          final playerController = ref.read(playerProvider(lecture));
          final currentPos = playerController.player.state.position;
          playerController.player.seek(currentPos + const Duration(seconds: 10));
        },
      ),
      IconButton(
        icon: const Icon(Icons.skip_next, color: Colors.white, size: 20),
        tooltip: 'Next Video',
        onPressed: _playNextLecture,
      ),
      const SizedBox(width: 8),
      const MaterialPositionIndicator(),
      const Spacer(),
      const MaterialDesktopVolumeButton(),
      const MaterialFullscreenButton(),
    ];

    return MaterialDesktopVideoControlsTheme(
      key: ValueKey(lecture.id),
      normal: MaterialDesktopVideoControlsThemeData(
        topButtonBar: const [], // Empty top button bar to avoid duplication
        bottomButtonBar: bottomBarWidgets,
        seekBarPositionColor: AppColors.primary,
        seekBarThumbColor: AppColors.primary,
      ),
      fullscreen: MaterialDesktopVideoControlsThemeData(
        topButtonBar: const [],
        bottomButtonBar: bottomBarWidgets,
        seekBarPositionColor: AppColors.primary,
        seekBarThumbColor: AppColors.primary,
      ),
      child: Stack(
        children: [
          Video(
            controller: controller.controller,
            controls: MaterialDesktopVideoControls,
          ),
          Positioned.fill(
            bottom: 60, // Clear of control bar
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  final playerController = ref.read(playerProvider(lecture));
                  final player = playerController.player;
                  final currentVol = player.state.volume;
                  if (pointerSignal.scrollDelta.dy < 0) {
                    player.setVolume((currentVol + 5.0).clamp(0.0, 100.0));
                  } else {
                    player.setVolume((currentVol - 5.0).clamp(0.0, 100.0));
                  }
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  windowManager.isFullScreen().then((isFS) {
                    windowManager.setFullScreen(!isFS);
                  });
                },
                onTap: () {
                  final playerController = ref.read(playerProvider(lecture));
                  playerController.player.playOrPause();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildModuleSection(ModuleModel module) {
    final pdfs = _getPdfsInModule(module.folderPath);

    return Consumer(
      builder: (context, ref, child) {
        final lectures = ref.watch(lecturesProvider(module.id));
        
        // If no lectures and no PDFs, hide this module completely
        if (lectures.isEmpty && pdfs.isEmpty) {
          return const SizedBox.shrink();
        }

        final isExpanded = _expandedModuleIds.contains(module.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.015)
                : Colors.black.withOpacity(0.01),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border(context).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: ValueKey(module.id),
              initiallyExpanded: isExpanded,
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              onExpansionChanged: (expanded) {
                setState(() {
                  if (expanded) {
                    _expandedModuleIds.add(module.id);
                  } else {
                    _expandedModuleIds.remove(module.id);
                  }
                });
              },
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textMuted(context),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              title: Text(
                module.title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              children: [
                Divider(color: AppColors.border(context).withOpacity(0.3), height: 1),
                
                // Lectures list
                ...lectures.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lecture = entry.value;
                  final isSelected = _currentLecture?.id == lecture.id;

                  return InkWell(
                    onTap: () => _setLecture(lecture),
                    hoverColor: AppColors.bg(context).withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildEpisodeThumbnail(lecture, index, isSelected),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lecture.title,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.text(context),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (lecture.watchProgressPercentage > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lecture.watchProgressPercentage}% watched',
                                    style: TextStyle(color: AppColors.textMuted(context), fontSize: 10),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                // PDF Resources list
                ...pdfs.map((pdfFile) {
                  final pdfName = p.basenameWithoutExtension(pdfFile.path);
                  return InkWell(
                    onTap: () => _openPdf(pdfFile.path),
                    hoverColor: AppColors.bg(context).withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.text(context).withOpacity(0.1),
                                width: 1,
                              ),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF3A1C1C) // Deep red accent dark
                                  : const Color(0xFFFEE2E2), // Clean light red tint
                            ),
                            child: const Center(
                              child: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pdfName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text(context),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PDF RESOURCE',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.open_in_new, color: AppColors.textFaint(context), size: 14),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodeThumbnail(LectureModel lecture, int index, bool isSelected) {
    final progress = lecture.watchProgressPercentage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 110,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border(context).withOpacity(0.5),
          width: isSelected ? 2 : 1.2,
        ),
        color: AppColors.card(context),
        image: lecture.thumbnailPath.isNotEmpty && File(lecture.thumbnailPath).existsSync()
            ? DecorationImage(image: FileImage(File(lecture.thumbnailPath)), fit: BoxFit.cover)
            : null,
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 6, spreadRadius: 1)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Elegant background gradient when no thumbnail is generated yet
            if (lecture.thumbnailPath.isEmpty || !File(lecture.thumbnailPath).existsSync())
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF2C2C35), const Color(0xFF1B1B1F)]
                        : [const Color(0xFFE5E7EB), const Color(0xFFF3F4F6)],
                  ),
                ),
              ),
            
            // Subtle dark overlay to ensure high contrast for indicators
            Container(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.15),
            ),
            
            // Episode Label on Top-Left
            Positioned(
              top: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EP ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Glassmorphic Center Play Button
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                ),
                child: Icon(
                  isSelected ? Icons.play_arrow : Icons.play_arrow_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

            // Sleek progress bar at bottom
            if (progress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: Colors.black26,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress / 100.0,
                    child: Container(color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Sequential 0.1s video-frame thumbnail extractor (100% crash-safe)
class ThumbnailGenerator {
  static bool _isGenerating = false;

  static Future<void> generateThumbnailsForCourse(String courseId) async {
    if (_isGenerating) return;
    _isGenerating = true;

    Player? player;
    try {
      final lecturesBox = HiveBoxes.getLecturesBox();
      final lectures = lecturesBox.values.where((l) => l.courseId == courseId && l.thumbnailPath.isEmpty).toList();
      if (lectures.isEmpty) {
        _isGenerating = false;
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(docsDir.path, 'GoodTime', 'Thumbnails'));
      if (!await thumbDir.exists()) await thumbDir.create(recursive: true);

      // Single, shared Player instance to prevent threading crashes
      player = Player();

      for (var lecture in lectures) {
        try {
          if (!File(lecture.filePath).existsSync()) continue;
          
          await player.open(Media(lecture.filePath), play: false);
          
          // Wait for player initialization and seek to exactly 0.1 seconds (100ms)
          await Future.delayed(const Duration(milliseconds: 400));
          await player.seek(const Duration(milliseconds: 100));
          await Future.delayed(const Duration(milliseconds: 300));

          final screenshot = await player.screenshot();
          if (screenshot != null && screenshot.isNotEmpty) {
            final fileName = '${lecture.id}.jpeg';
            final destFile = File(p.join(thumbDir.path, fileName));
            await destFile.writeAsBytes(screenshot);

            lecture.thumbnailPath = destFile.path;
            await lecturesBox.put(lecture.id, lecture);

            // Set course-level thumbnail if it doesn't have one
            final coursesBox = HiveBoxes.getCoursesBox();
            final course = coursesBox.get(courseId);
            if (course != null && course.thumbnailPath.isEmpty) {
              course.thumbnailPath = destFile.path;
              await coursesBox.put(course.id, course);
            }
          }
        } catch (e) {
          print('Error generating thumbnail for ${lecture.title}: $e');
        }
      }
    } catch (e) {
      print('Sequential thumbnail error: $e');
    } finally {
      if (player != null) {
        try {
          await player.dispose();
        } catch (e) {
          print('Error disposing thumbnail player: $e');
        }
      }
      _isGenerating = false;
    }
  }
}
