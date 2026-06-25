import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/story_provider.dart';

class StoryCard extends ConsumerWidget {
  final String storyText;

  const StoryCard({
    super.key,
    required this.storyText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(storyAudioProvider);
    final playbackNotifier = ref.read(storyAudioProvider.notifier);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Narrative Header
            Row(
              children: [
                const Icon(Icons.book_rounded, color: Colors.indigo, size: 28),
                const SizedBox(width: 8),
                Text(
                  "Pip's Adventure",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.indigo.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Narrative Text
            Text(
              storyText,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            // Narration Trigger Button
            _buildNarrationButton(context, playbackState, playbackNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrationButton(
    BuildContext context,
    AppPlaybackState state,
    StoryAudioNotifier notifier,
  ) {
    switch (state) {
      case AppPlaybackState.preparing:
        return ElevatedButton.icon(
          onPressed: null, // Disabled
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.indigo,
            ),
          ),
          label: const Text(
            "Preparing Audio...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        );

      case AppPlaybackState.playing:
        return ElevatedButton.icon(
          onPressed: () => notifier.stop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade900,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: Colors.red.shade200, width: 2),
          ),
          icon: const Icon(Icons.stop_circle_rounded),
          label: const Text(
            "Stop Story",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

      case AppPlaybackState.error:
        return ElevatedButton.icon(
          onPressed: () => notifier.speak(storyText),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade100,
            foregroundColor: Colors.amber.shade900,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: Colors.amber.shade300, width: 2),
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(
            "Narration Failed. Retry?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

      case AppPlaybackState.finished:
        return OutlinedButton.icon(
          onPressed: () => notifier.speak(storyText),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Colors.indigo, width: 2),
          ),
          icon: const Icon(Icons.replay_rounded),
          label: const Text(
            "Listen Again",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

      case AppPlaybackState.idle:
      default:
        return ElevatedButton.icon(
          onPressed: () => notifier.speak(storyText),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.indigo.shade200,
          ),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text(
            "Read Me a Story",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
    }
  }
}
