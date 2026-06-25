import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/story_provider.dart';
import '../providers/quiz_provider.dart';

class BuddyCharacter extends ConsumerStatefulWidget {
  const BuddyCharacter({super.key});

  @override
  ConsumerState<BuddyCharacter> createState() => _BuddyCharacterState();
}

class _BuddyCharacterState extends ConsumerState<BuddyCharacter> with SingleTickerProviderStateMixin {
  late final AnimationController _bobbingController;
  late final Animation<double> _bobbingAnimation;

  @override
  void initState() {
    super.initState();
    // 2-second loop for a gentle breathing/floating motion
    _bobbingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _bobbingAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(
        parent: _bobbingController,
        curve: Curves.easeInOut,
      ),
    );

    _bobbingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobbingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch states
    final playbackState = ref.watch(storyAudioProvider);
    final quizState = ref.watch(quizProvider);

    // Determine asset based on current states
    final String assetPath;
    final String bubbleText;

    if (quizState.state == QuizState.success) {
      assetPath = 'assets/images/buddy_happy.png';
      bubbleText = "Yay! You got it! You're super smart! 🎉";
    } else if (playbackState == AppPlaybackState.playing) {
      assetPath = 'assets/images/buddy_talking.png';
      bubbleText = "Listening closely... 🎙️";
    } else if (playbackState == AppPlaybackState.preparing) {
      assetPath = 'assets/images/buddy_talking.png';
      bubbleText = "Getting ready to read... 🤖";
    } else if (playbackState == AppPlaybackState.error) {
      assetPath = 'assets/images/buddy_idle.png';
      bubbleText = "Oh no! Try tapping retry. 🛠️";
    } else if (quizState.state == QuizState.wrongAnswer) {
      assetPath = 'assets/images/buddy_idle.png'; // or a separate retry buddy
      bubbleText = "Ouch! That's not it, let's try again! 💪";
    } else if (playbackState == AppPlaybackState.finished) {
      assetPath = 'assets/images/buddy_idle.png';
      bubbleText = "Can you answer my question? 🧐";
    } else {
      assetPath = 'assets/images/buddy_idle.png';
      bubbleText = "Tap below to read the story! 👇";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dialogue Bubble for Buddy
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo.shade100, width: 1.5),
          ),
          child: Text(
            bubbleText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Custom pointing tail for chat bubble
        Container(
          width: 0,
          height: 0,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 8),
              left: BorderSide(color: Colors.transparent, width: 8),
              right: BorderSide(color: Colors.transparent, width: 8),
            ),
          ),
        ),
        // The Buddy Character illustration with Bobbing Animation
        AnimatedBuilder(
          animation: _bobbingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bobbingAnimation.value),
              child: child,
            );
          },
          // Keep the Image loading outside of the animation builder ticker to optimize performance
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.lightBlue.shade50,
              border: Border.all(color: Colors.blue.shade100, width: 4),
            ),
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                // Add key to force cross-fade when swapping images in AnimatedSwitcher if desired, 
                // but standard Image.asset handles swap efficiently
                key: ValueKey<String>(assetPath),
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image asset is not loaded/found
                  return Icon(
                    Icons.android,
                    size: 80,
                    color: Colors.blue.shade300,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
