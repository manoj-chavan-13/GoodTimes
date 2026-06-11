import 'package:hive/hive.dart';

class PlaybackModel {
  String videoId;
  int watchedSeconds;
  double watchedPercentage;
  DateTime lastPlayed;

  PlaybackModel({
    required this.videoId,
    required this.watchedSeconds,
    required this.watchedPercentage,
    required this.lastPlayed,
  });
}

class PlaybackModelAdapter extends TypeAdapter<PlaybackModel> {
  @override
  final int typeId = 2;

  @override
  PlaybackModel read(BinaryReader reader) {
    return PlaybackModel(
      videoId: reader.readString(),
      watchedSeconds: reader.readInt(),
      watchedPercentage: reader.readDouble(),
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackModel obj) {
    writer.writeString(obj.videoId);
    writer.writeInt(obj.watchedSeconds);
    writer.writeDouble(obj.watchedPercentage);
    writer.writeInt(obj.lastPlayed.millisecondsSinceEpoch);
  }
}
