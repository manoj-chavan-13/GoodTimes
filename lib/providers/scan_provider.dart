import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/course_model.dart';
import 'package:goodtimes/models/module_model.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/services/scanner_service.dart';
import 'package:goodtimes/services/metadata_service.dart';
import 'package:uuid/uuid.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

final scanProvider = Provider((ref) => ScanController(ref));

class ScanController {
  final Ref ref;
  final ScannerService _scannerService = ScannerService();
  final MetadataService _metadataService = MetadataService();

  ScanController(this.ref);

  Future<int> scanRootFolder(String rootPath) async {
    final parsedCourses = await _scannerService.scanRootFolder(rootPath);
    
    final coursesBox = HiveBoxes.getCoursesBox();
    final modulesBox = HiveBoxes.getModulesBox();
    final lecturesBox = HiveBoxes.getLecturesBox();
    
    List<LectureModel> lecturesNeedingThumbnails = [];
    
    for (var parsedCourse in parsedCourses) {
      // Check if course exists by path
      CourseModel? course = coursesBox.values.where((c) => c.folderPath == parsedCourse.folderPath).firstOrNull;
      course ??= CourseModel(
          id: const Uuid().v4(),
          title: parsedCourse.title,
          folderPath: parsedCourse.folderPath,
          thumbnailPath: parsedCourse.thumbnailPath,
          moduleIds: [],
          totalDurationMilliseconds: 0,
          watchedDurationMilliseconds: 0,
          lastWatched: DateTime.now(),
          lastScanned: DateTime.now(),
        );

      List<String> moduleIds = [];
      int totalDuration = 0;

      for (var parsedModule in parsedCourse.modules) {
        ModuleModel? module = modulesBox.values.where((m) => m.folderPath == parsedModule.folderPath).firstOrNull;
        module ??= ModuleModel(
            id: const Uuid().v4(),
            courseId: course.id,
            title: parsedModule.title,
            folderPath: parsedModule.folderPath,
            lectureIds: [],
          );
        
        List<String> lectureIds = [];

        for (var parsedLecture in parsedModule.lectures) {
          LectureModel? lecture = lecturesBox.values.where((l) => l.filePath == parsedLecture.filePath).firstOrNull;
          
          if (lecture == null) {
            // Disabled metadata extraction during scan to prevent MediaKit crashes
            // and speed up the scanning process significantly.
            // Duration will be updated when the video is played.
            final duration = Duration.zero;
            
            lecture = LectureModel(
              id: const Uuid().v4(),
              moduleId: module.id,
              courseId: course.id,
              title: parsedLecture.title,
              filePath: parsedLecture.filePath,
              duration: duration,
              watchProgressPercentage: 0,
              lastPositionSeconds: 0,
              isCompleted: false,
              thumbnailPath: parsedLecture.thumbnailPath,
            );
          } else {
            // Update thumbnail if empty
            if (lecture.thumbnailPath.isEmpty && parsedLecture.thumbnailPath.isNotEmpty) {
              lecture.thumbnailPath = parsedLecture.thumbnailPath;
            }
          }
          
          if (lecture.thumbnailPath.isEmpty) {
            lecturesNeedingThumbnails.add(lecture);
          }
          
          await lecturesBox.put(lecture.id, lecture);
          lectureIds.add(lecture.id);
          totalDuration += lecture.duration.inMilliseconds;
        }

        module.lectureIds = lectureIds;
        await modulesBox.put(module.id, module);
        moduleIds.add(module.id);
      }

      course.moduleIds = moduleIds;
      course.totalDurationMilliseconds = totalDuration;
      // We will let the course use the first lecture's thumbnail later or auto thumbnail
      course.lastScanned = DateTime.now();
      await coursesBox.put(course.id, course);
    }
    
    // Start background thumbnail generation so it doesn't block UI
    if (lecturesNeedingThumbnails.isNotEmpty) {
      _startBackgroundThumbnailGeneration(lecturesNeedingThumbnails);
    }
    
    return parsedCourses.length;
  }

  void _startBackgroundThumbnailGeneration(List<LectureModel> lectures) async {
    for (var lecture in lectures) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final thumbDir = Directory(p.join(docsDir.path, 'GoodTime', 'Thumbnails'));
        if (!await thumbDir.exists()) await thumbDir.create(recursive: true);
        
        final fileName = '${const Uuid().v4()}.jpeg';
        final destFile = File(p.join(thumbDir.path, fileName));
        
        final player = Player();
        await player.open(Media(lecture.filePath), play: false);
        
        await Future.delayed(const Duration(milliseconds: 200));
        await player.seek(const Duration(seconds: 1));
        await Future.delayed(const Duration(milliseconds: 300));
        
        final screenshot = await player.screenshot();
        await player.dispose();

        if (screenshot != null && screenshot.isNotEmpty) {
          await destFile.writeAsBytes(screenshot);
          lecture.thumbnailPath = destFile.path;
          
          // Save to Hive
          await HiveBoxes.getLecturesBox().put(lecture.id, lecture);
          
          // Also check if we need to update course thumbnail
          final course = HiveBoxes.getCoursesBox().get(lecture.courseId);
          if (course != null && course.thumbnailPath.isEmpty) {
            course.thumbnailPath = destFile.path;
            await HiveBoxes.getCoursesBox().put(course.id, course);
          }
        }
      } catch (e) {
        print('Background thumb error for ${lecture.title}: $e');
      }
    }
  }
}
