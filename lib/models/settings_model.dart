import 'package:hive/hive.dart';

class SettingsModel {
  bool autoResume;
  bool autoplay;
  bool darkMode;
  bool autoScan;
  int thumbnailQuality;
  int maxThumbnailJobs;

  SettingsModel({
    required this.autoResume,
    required this.autoplay,
    required this.darkMode,
    required this.autoScan,
    required this.thumbnailQuality,
    required this.maxThumbnailJobs,
  });

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      autoResume: true,
      autoplay: false,
      darkMode: false,
      autoScan: true,
      thumbnailQuality: 75,
      maxThumbnailJobs: 2,
    );
  }
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 3;

  @override
  SettingsModel read(BinaryReader reader) {
    return SettingsModel(
      autoResume: reader.readBool(),
      autoplay: reader.readBool(),
      darkMode: reader.readBool(),
      autoScan: reader.readBool(),
      thumbnailQuality: reader.readInt(),
      maxThumbnailJobs: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer.writeBool(obj.autoResume);
    writer.writeBool(obj.autoplay);
    writer.writeBool(obj.darkMode);
    writer.writeBool(obj.autoScan);
    writer.writeInt(obj.thumbnailQuality);
    writer.writeInt(obj.maxThumbnailJobs);
  }
}
