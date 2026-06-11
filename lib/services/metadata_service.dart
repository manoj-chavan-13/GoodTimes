import 'package:media_kit/media_kit.dart';
import 'dart:io';

class MetadataService {
  Future<Map<String, dynamic>> extractMetadata(String filePath) async {
    final player = Player();
    Duration duration = Duration.zero;
    int width = 0;
    int height = 0;
    int size = 0;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        size = await file.length();
      }
      
      await player.open(Media(filePath), play: false);
      
      // Wait for metadata to load (simplistic approach, ideally listen to streams)
      await Future.delayed(const Duration(milliseconds: 500));
      
      duration = player.state.duration;
      width = player.state.width ?? 0;
      height = player.state.height ?? 0;
    } catch (e) {
      print('Error extracting metadata for $filePath: $e');
    } finally {
      await player.dispose();
    }
    
    return {
      'duration': duration,
      'width': width,
      'height': height,
      'fileSize': size,
    };
  }
}
