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

  Future<void> addRootFolder(WidgetRef ref) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    // Scan root directory
    await ref.read(scanProvider).scanRootFolder(selectedDirectory);
    
    // Update state
    final box = HiveBoxes.getCoursesBox();
    state = box.values.toList();
  }

  Future<void> removeCourse(String id) async {
    final box = HiveBoxes.getCoursesBox();
    await box.delete(id);
    state = state.where((c) => c.id != id).toList();
  }
}
