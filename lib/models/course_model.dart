import 'package:hive/hive.dart';

class CourseModel {
  String id;
  String title;
  String folderPath;
  String thumbnailPath;
  List<String> moduleIds;
  int totalDurationMilliseconds;
  int watchedDurationMilliseconds;
  DateTime lastWatched;
  DateTime lastScanned;

  CourseModel({
    required this.id,
    required this.title,
    required this.folderPath,
    required this.thumbnailPath,
    required this.moduleIds,
    required this.totalDurationMilliseconds,
    required this.watchedDurationMilliseconds,
    required this.lastWatched,
    required this.lastScanned,
  });
}

class CourseModelAdapter extends TypeAdapter<CourseModel> {
  @override
  final int typeId = 0; // Overwriting FolderModel typeId

  @override
  CourseModel read(BinaryReader reader) {
    return CourseModel(
      id: reader.readString(),
      title: reader.readString(),
      folderPath: reader.readString(),
      thumbnailPath: reader.readString(),
      moduleIds: reader.readStringList(),
      totalDurationMilliseconds: reader.readInt(),
      watchedDurationMilliseconds: reader.readInt(),
      lastWatched: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastScanned: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, CourseModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.folderPath);
    writer.writeString(obj.thumbnailPath);
    writer.writeStringList(obj.moduleIds);
    writer.writeInt(obj.totalDurationMilliseconds);
    writer.writeInt(obj.watchedDurationMilliseconds);
    writer.writeInt(obj.lastWatched.millisecondsSinceEpoch);
    writer.writeInt(obj.lastScanned.millisecondsSinceEpoch);
  }
}
