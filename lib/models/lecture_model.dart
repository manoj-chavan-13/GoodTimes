import 'package:hive/hive.dart';

class LectureModel {
  String id;
  String moduleId;
  String courseId;
  String title;
  String filePath;
  Duration duration;
  int watchProgressPercentage;
  int lastPositionSeconds;
  bool isCompleted;
  DateTime? lastWatched;

  LectureModel({
    required this.id,
    required this.moduleId,
    required this.courseId,
    required this.title,
    required this.filePath,
    required this.duration,
    required this.watchProgressPercentage,
    required this.lastPositionSeconds,
    required this.isCompleted,
    this.lastWatched,
  });
}

class LectureModelAdapter extends TypeAdapter<LectureModel> {
  @override
  final int typeId = 1; // Overwriting VideoModel typeId

  @override
  LectureModel read(BinaryReader reader) {
    return LectureModel(
      id: reader.readString(),
      moduleId: reader.readString(),
      courseId: reader.readString(),
      title: reader.readString(),
      filePath: reader.readString(),
      duration: Duration(milliseconds: reader.readInt()),
      watchProgressPercentage: reader.readInt(),
      lastPositionSeconds: reader.readInt(),
      isCompleted: reader.readBool(),
      lastWatched: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
    );
  }

  @override
  void write(BinaryWriter writer, LectureModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.moduleId);
    writer.writeString(obj.courseId);
    writer.writeString(obj.title);
    writer.writeString(obj.filePath);
    writer.writeInt(obj.duration.inMilliseconds);
    writer.writeInt(obj.watchProgressPercentage);
    writer.writeInt(obj.lastPositionSeconds);
    writer.writeBool(obj.isCompleted);
    
    writer.writeBool(obj.lastWatched != null);
    if (obj.lastWatched != null) {
      writer.writeInt(obj.lastWatched!.millisecondsSinceEpoch);
    }
  }
}
