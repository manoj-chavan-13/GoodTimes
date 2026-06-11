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

  String _findThumbnail(String path) {
    final possibleThumbs = ['thumbnail.jpg', 'thumbnail.png', 'cover.jpg', 'cover.png', 'poster.jpg', 'poster.png'];
    for (var name in possibleThumbs) {
      final file = File(p.join(path, name));
      if (file.existsSync()) return file.path;
    }
    return '';
  }

  Future<List<ParsedCourse>> scanRootFolder(String rootPath) async {
    List<ParsedCourse> courses = [];
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return courses;

    try {
      // 1. Check if Root Folder itself has videos directly (Root -> Videos)
      final rootFiles = rootDir.listSync(followLinks: false).whereType<File>().toList();
      rootFiles.sort((a, b) => a.path.compareTo(b.path));
      List<ParsedLecture> rootLectures = [];
      for (var file in rootFiles) {
        if (supportedExtensions.contains(p.extension(file.path).toLowerCase())) {
          rootLectures.add(ParsedLecture(title: p.basenameWithoutExtension(file.path), filePath: file.path));
        }
      }
      if (rootLectures.isNotEmpty) {
        courses.add(ParsedCourse(
          title: p.basename(rootDir.path),
          folderPath: rootDir.path,
          thumbnailPath: _findThumbnail(rootDir.path),
          modules: [ParsedModule(title: 'Main Content', folderPath: rootDir.path, lectures: rootLectures)],
        ));
      }

      // 2. Iterate over subdirectories of Root
      final subDirs = rootDir.listSync(followLinks: false).whereType<Directory>().toList();
      subDirs.sort((a, b) => a.path.compareTo(b.path));

      for (var courseDir in subDirs) {
        List<ParsedModule> modules = [];
        
        // Check if courseDir has videos directly (Root -> Course -> Videos)
        final courseFiles = courseDir.listSync(followLinks: false).whereType<File>().toList();
        courseFiles.sort((a, b) => a.path.compareTo(b.path));
        List<ParsedLecture> directLectures = [];
        for (var file in courseFiles) {
          if (supportedExtensions.contains(p.extension(file.path).toLowerCase())) {
            directLectures.add(ParsedLecture(title: p.basenameWithoutExtension(file.path), filePath: file.path));
          }
        }
        if (directLectures.isNotEmpty) {
          modules.add(ParsedModule(title: 'Content', folderPath: courseDir.path, lectures: directLectures));
        }

        // Check if courseDir has subdirectories (Root -> Course -> Module -> Videos)
        final moduleDirs = courseDir.listSync(followLinks: false).whereType<Directory>().toList();
        moduleDirs.sort((a, b) => a.path.compareTo(b.path));
        for (var moduleDir in moduleDirs) {
          final moduleFiles = moduleDir.listSync(followLinks: false).whereType<File>().toList();
          moduleFiles.sort((a, b) => a.path.compareTo(b.path));
          List<ParsedLecture> moduleLectures = [];
          for (var file in moduleFiles) {
            if (supportedExtensions.contains(p.extension(file.path).toLowerCase())) {
              moduleLectures.add(ParsedLecture(title: p.basenameWithoutExtension(file.path), filePath: file.path));
            }
          }
          if (moduleLectures.isNotEmpty) {
            modules.add(ParsedModule(title: p.basename(moduleDir.path), folderPath: moduleDir.path, lectures: moduleLectures));
          }
        }

        if (modules.isNotEmpty) {
          courses.add(ParsedCourse(
            title: p.basename(courseDir.path),
            folderPath: courseDir.path,
            thumbnailPath: _findThumbnail(courseDir.path),
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
