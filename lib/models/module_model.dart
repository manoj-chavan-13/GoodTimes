import 'package:hive/hive.dart';

class ModuleModel {
  String id;
  String courseId;
  String title;
  String folderPath;
  List<String> lectureIds;

  ModuleModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.folderPath,
    required this.lectureIds,
  });
}

class ModuleModelAdapter extends TypeAdapter<ModuleModel> {
  @override
  final int typeId = 4; // Use a new typeId

  @override
  ModuleModel read(BinaryReader reader) {
    return ModuleModel(
      id: reader.readString(),
      courseId: reader.readString(),
      title: reader.readString(),
      folderPath: reader.readString(),
      lectureIds: reader.readStringList(),
    );
  }

  @override
  void write(BinaryWriter writer, ModuleModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.courseId);
    writer.writeString(obj.title);
    writer.writeString(obj.folderPath);
    writer.writeStringList(obj.lectureIds);
  }
}
