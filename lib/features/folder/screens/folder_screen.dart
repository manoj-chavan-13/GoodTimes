import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/models/folder_model.dart';
import 'package:goodtimes/providers/video_provider.dart';
import 'package:goodtimes/features/player/screens/player_screen.dart';
import 'package:goodtimes/widgets/hoverable_card.dart';
import 'dart:io';

class FolderScreen extends ConsumerWidget {
  final FolderModel folder;

  const FolderScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(videosProvider(folder.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(folder.folderName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: videos.isEmpty
          ? const Center(child: Text('No Videos Found', style: TextStyle(fontSize: 18, color: Colors.white54)))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(32.0, 100.0, 32.0, 32.0),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 16 / 9,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return HoverableCard(
                  scaleFactor: 1.08,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayerScreen(video: video)),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail
                      video.thumbnailPath.isNotEmpty
                          ? Image.file(
                              File(video.thumbnailPath),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Theme.of(context).cardColor,
                              child: const Icon(Icons.movie, size: 48, color: Colors.white24),
                            ),
                      // Dark Gradient for Text
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Play Button Overlay (visible on hover could be implemented, but static for now)
                      const Center(
                        child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white70),
                      ),
                      // Duration Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${video.duration.inMinutes}m ${video.duration.inSeconds % 60}s',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Title & Progress Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Text(
                                video.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                            ),
                            if (video.watchProgress > 0)
                              Container(
                                height: 4,
                                width: double.infinity,
                                color: Colors.white24,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (video.watchProgress / 100).clamp(0.0, 1.0),
                                  child: Container(color: Theme.of(context).primaryColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
