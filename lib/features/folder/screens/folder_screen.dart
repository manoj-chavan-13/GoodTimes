import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodtimes/widgets/hoverable_card.dart';

// This screen is unused - folder browsing is handled through course_screen
// Keeping as a stub to avoid import errors

class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text(
          'No folder selected.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}
