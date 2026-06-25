import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../providers/quiz_provider.dart';

class ConfettiCelebration extends ConsumerStatefulWidget {
  final Widget child;

  const ConfettiCelebration({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends ConsumerState<ConfettiCelebration> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Confetti duration capped at 1.5 seconds to save memory and CPU
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for success state to trigger confetti
    ref.listen<QuizStateData>(quizProvider, (previous, next) {
      if (next.state == QuizState.success) {
        _confettiController.play();
      }
    });

    return Stack(
      children: [
        // Content wrapped in RepaintBoundary to prevent repaint propagation
        RepaintBoundary(
          child: widget.child,
        ),

        // Confetti Emitter top center shooting downwards
        Align(
          alignment: Alignment.topCenter,
          child: RepaintBoundary(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Shoot down
              emissionFrequency: 0.02, // Lower emission frequency to save rendering resources
              numberOfParticles: 8,    // Capped particles per burst
              gravity: 0.15,           // Fall speed
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ),

        // Optional additional emitter left shooting right-up
        Align(
          alignment: Alignment.bottomLeft,
          child: RepaintBoundary(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 6, // Up and right
              emissionFrequency: 0.015,
              numberOfParticles: 4,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [Colors.lightBlue, Colors.pinkAccent, Colors.yellowAccent],
            ),
          ),
        ),

        // Optional additional emitter right shooting left-up
        Align(
          alignment: Alignment.bottomRight,
          child: RepaintBoundary(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -5 * pi / 6, // Up and left
              emissionFrequency: 0.015,
              numberOfParticles: 4,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [Colors.lightGreen, Colors.orangeAccent, Colors.purpleAccent],
            ),
          ),
        ),
      ],
    );
  }
}
