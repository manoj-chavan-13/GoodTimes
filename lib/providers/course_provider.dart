import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:goodtimes/models/course_model.dart';
import 'package:goodtimes/database/hive_boxes.dart';
import 'package:goodtimes/providers/scan_provider.dart';

final coursesProvider = NotifierProvider<CourseNotifier, List<CourseModel>>(() {
  return CourseNotifier();
});

class CourseNotifier extends Notifier<List<CourseModel>> {
  @override
  List<CourseModel> build() {
    final box = HiveBoxes.getCoursesBox();
    return box.values.toList();
  }

  Future<void> addRootFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    // Scan root directory
    await ref.read(scanProvider).scanRootFolder(selectedDirectory);
    
    // Update state
    final box = HiveBoxes.getCoursesBox();
    state = box.values.toList();
  }

  Future<void> removeCourse(String id) async {
    final coursesBox = HiveBoxes.getCoursesBox();
    final modulesBox = HiveBoxes.getModulesBox();
    final lecturesBox = HiveBoxes.getLecturesBox();

    final course = coursesBox.get(id);
    if (course != null) {
      for (var moduleId in course.moduleIds) {
        final module = modulesBox.get(moduleId);
        if (module != null) {
          for (var lectureId in module.lectureIds) {
            await lecturesBox.delete(lectureId);
          }
          await modulesBox.delete(moduleId);
        }
      }
    }

    await coursesBox.delete(id);
    state = state.where((c) => c.id != id).toList();
  }
}
