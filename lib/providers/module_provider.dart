import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/models/module_model.dart';

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

final modulesProvider = Provider.family<List<ModuleModel>, String>((ref, courseId) {
  final box = HiveBoxes.getModulesBox();
  final modules = box.values.where((m) => m.courseId == courseId).toList();
  // Ensure sorted by natural order (e.g., 'Module 2' before 'Module 10')
  modules.sort((a, b) => _naturalCompare(a.title, b.title));
  return modules;
});
