import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/models/course_model.dart';

class HistoryItem {
  final LectureModel lecture;
  final CourseModel course;
  HistoryItem(this.lecture, this.course);
}

final historyProvider = Provider<List<HistoryItem>>((ref) {
  final lecturesBox = HiveBoxes.getLecturesBox();
  final coursesBox = HiveBoxes.getCoursesBox();
  
  final watched = lecturesBox.values
      .where((l) => l.lastWatched != null && !l.isCompleted && l.watchProgressPercentage > 0)
      .toList();
      
  watched.sort((a, b) => b.lastWatched!.compareTo(a.lastWatched!));
  
  List<HistoryItem> items = [];
  for (var lecture in watched) {
    final course = coursesBox.values.where((c) => c.id == lecture.courseId).firstOrNull;
    if (course != null) {
      items.add(HistoryItem(lecture, course));
    }
  }
  return items;
});
