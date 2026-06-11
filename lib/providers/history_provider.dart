import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/lecture_model.dart';
import 'package:goodtimes/models/course_model.dart';

class HistoryItem {
  final LectureModel lecture;
  final CourseModel course;
  HistoryItem(this.lecture, this.course);
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(() {
  return HistoryNotifier();
});

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() {
    return _fetchHistory();
  }

  List<HistoryItem> _fetchHistory() {
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
  }

  void removeFromHistory(LectureModel lecture) async {
    final lecturesBox = HiveBoxes.getLecturesBox();
    lecture.watchProgressPercentage = 0;
    lecture.lastPositionSeconds = 0;
    lecture.lastWatched = null;
    await lecturesBox.put(lecture.id, lecture);
    
    // Also remove from Playback box if we want
    final pbBox = HiveBoxes.getPlaybackBox();
    await pbBox.delete(lecture.id);

    state = _fetchHistory();
  }

  void refresh() {
    state = _fetchHistory();
  }
}
