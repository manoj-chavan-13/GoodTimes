import 'package:media_kit/media_kit.dart';
import 'dart:io';

class MetadataService {
  Future<Map<String, dynamic>> extractMetadata(String filePath) async {
    final player = Player();
    await player.open(Media(filePath), play: false);
    
    // Wait for metadata to load (simplistic approach, ideally listen to streams)
    await Future.delayed(const Duration(milliseconds: 500));
    
    final duration = player.state.duration;
    final width = player.state.width;
    final height = player.state.height;
    
    await player.dispose();
    
    final file = File(filePath);
    final size = await file.length();
    
    return {
      'duration': duration,
      'width': width ?? 0,
      'height': height ?? 0,
      'fileSize': size,
    };
  }
}
