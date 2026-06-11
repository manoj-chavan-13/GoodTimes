import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/lecture_model.dart';

int _naturalCompare(String a, String b) {
  final regExp = RegExp(r'\d+|\D+');
  final matchesA = regExp.allMatches(a).map((m) => m.group(0)!).toList();
  final matchesB = regExp.allMatches(b).map((m) => m.group(0)!).toList();

  final length = matchesA.length < matchesB.length ? matchesA.length : matchesB.length;

  for (int i = 0; i < length; i++) {
    final partA = matchesA[i];
    final partB = matchesB[i];

    final isNumA = int.tryParse(partA) != null;
    final isNumB = int.tryParse(partB) != null;

    if (isNumA && isNumB) {
      final numA = int.parse(partA);
      final numB = int.parse(partB);
      if (numA != numB) return numA.compareTo(numB);
    } else if (!isNumA && !isNumB) {
      final cmp = partA.compareTo(partB);
      if (cmp != 0) return cmp;
    } else {
      return partA.compareTo(partB);
    }
  }
  return matchesA.length.compareTo(matchesB.length);
}

final lecturesProvider = Provider.family<List<LectureModel>, String>((ref, moduleId) {
  final box = HiveBoxes.getLecturesBox();
  final lectures = box.values.where((l) => l.moduleId == moduleId).toList();
  // Ensure sorted by natural order (e.g., 'Episode 2' before 'Episode 10')
  lectures.sort((a, b) => _naturalCompare(a.title, b.title));
  return lectures;
});
