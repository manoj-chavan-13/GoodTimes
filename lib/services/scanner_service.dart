import 'dart:io';
import 'package:path/path.dart' as p;

class ParsedLecture {
  final String title;
  final String filePath;
  ParsedLecture({required this.title, required this.filePath});
}

class ParsedModule {
  final String title;
  final String folderPath;
  final List<ParsedLecture> lectures;
  ParsedModule({required this.title, required this.folderPath, required this.lectures});
}

class ParsedCourse {
  final String title;
  final String folderPath;
  final String thumbnailPath;
  final List<ParsedModule> modules;
  ParsedCourse({required this.title, required this.folderPath, required this.thumbnailPath, required this.modules});
}

class ScannerService {
  static const List<String> supportedExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm', '.flv', '.wmv'
  ];

  Future<List<ParsedCourse>> scanRootFolder(String rootPath) async {
    List<ParsedCourse> courses = [];
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return courses;

    try {
      final courseEntities = rootDir.listSync(followLinks: false).whereType<Directory>().toList();
      courseEntities.sort((a, b) => a.path.compareTo(b.path));

      for (var courseDir in courseEntities) {
        // Find thumbnail
        String thumbPath = '';
        final possibleThumbs = ['thumbnail.jpg', 'thumbnail.png'];
        for (var name in possibleThumbs) {
          final file = File(p.join(courseDir.path, name));
          if (file.existsSync()) {
            thumbPath = file.path;
            break;
          }
        }

        // Find modules
        List<ParsedModule> modules = [];
        final moduleEntities = courseDir.listSync(followLinks: false).whereType<Directory>().toList();
        moduleEntities.sort((a, b) => a.path.compareTo(b.path));

        for (var moduleDir in moduleEntities) {
          // Find lectures
          List<ParsedLecture> lectures = [];
          final fileEntities = moduleDir.listSync(followLinks: false).whereType<File>().toList();
          fileEntities.sort((a, b) => a.path.compareTo(b.path));

          for (var file in fileEntities) {
            final ext = p.extension(file.path).toLowerCase();
            if (supportedExtensions.contains(ext)) {
              lectures.add(ParsedLecture(
                title: p.basenameWithoutExtension(file.path),
                filePath: file.path,
              ));
            }
          }

          if (lectures.isNotEmpty) {
            modules.add(ParsedModule(
              title: p.basename(moduleDir.path),
              folderPath: moduleDir.path,
              lectures: lectures,
            ));
          }
        }

        if (modules.isNotEmpty) {
          courses.add(ParsedCourse(
            title: p.basename(courseDir.path),
            folderPath: courseDir.path,
            thumbnailPath: thumbPath,
            modules: modules,
          ));
        }
      }
    } catch (e) {
      print('Error scanning root folder $rootPath: $e');
    }

    return courses;
  }
}
