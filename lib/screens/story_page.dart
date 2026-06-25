import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quiz_question.dart';
import '../providers/story_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/buddy_character.dart';
import '../widgets/story_card.dart';
import '../widgets/quiz_card.dart';
import '../widgets/confetti_celebration.dart';

class StoryPage extends ConsumerStatefulWidget {
  const StoryPage({super.key});

  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage> {
  static const String _storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...";

  static const String _quizJsonString = '''
  {
    "question": "What colour was Pip the Robot's lost gear?",
    "options": ["Red", "Green", "Blue", "Yellow"],
    "answer": "Blue"
  }
  ''';

  late final QuizQuestion _quizQuestion;

  // Controlled scroll instead of letting SingleChildScrollView snap on its own.
  final ScrollController _scrollController = ScrollController();
  // Key on the quiz/result section so we know exactly where to scroll to.
  final GlobalKey _quizSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    try {
      final data = jsonDecode(_quizJsonString) as Map<String, dynamic>;
      _quizQuestion = QuizQuestion.fromJson(data);
    } catch (e) {
      _quizQuestion = QuizQuestion.fromJson(null);
    }

    // Side-effect only: this listener block does NOT cause StoryPage to
    // rebuild by itself — only the matched callback runs.
    ref.listenManual<AppPlaybackState>(storyAudioProvider, (previous, next) {
      final quizData = ref.read(quizProvider);
      if (next == AppPlaybackState.finished && previous != AppPlaybackState.finished) {
        ref.read(quizProvider.notifier).loadQuestion(_quizQuestion);
        _scrollToQuizSection();
      } else if (next == AppPlaybackState.idle ||
          next == AppPlaybackState.preparing ||
          next == AppPlaybackState.playing) {
        if (quizData.state != QuizState.notStarted) {
          ref.read(quizProvider.notifier).reset();
          _scrollToTop();
        }
      }
    });

    ref.listenManual<QuizStateData>(quizProvider, (previous, next) {
      if (next.state == QuizState.success && previous?.state != QuizState.success) {
        // Let the AnimatedSwitcher's fade/slide start, then smoothly follow it
        // down to the success card once it has laid out.
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToQuizSection());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToQuizSection() {
    final ctx = _quizSectionKey.currentContext;
    if (ctx == null) return;
    // Scrollable.ensureVisible gives a smooth, animated scroll instead of an
    // instant offset correction, and it's safe even if the section is
    // already fully visible (it simply won't move).
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.1, // keep a little headroom above the section
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: deliberately not watching storyAudioProvider/quizProvider here.
    // Doing so previously forced this entire screen (header, buddy, story
    // card, gradient, scroll view) to rebuild on every provider tick,
    // including during the confetti celebration — that compounded rebuild
    // work was the main source of the jank cluster around the success
    // transition. Each section below now reads only what it needs.
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: ConfettiCelebration(
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  const Center(child: BuddyCharacter()),
                  const SizedBox(height: 24),
                  StoryCard(storyText: _storyText),
                  const SizedBox(height: 20),
                  // Only this small section watches quiz state, and it owns
                  // the key used for the animated scroll target.
                  KeyedSubtree(
                    key: _quizSectionKey,
                    child: _QuizSection(fallbackQuestion: _quizQuestion),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.face_retouching_natural_rounded, color: Colors.indigo.shade700, size: 28),
        const SizedBox(width: 8),
        Text(
          "Peblo Story Buddy",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Isolated section: only this widget watches [quizProvider], so the
/// AnimatedSwitcher between quiz card / success card / nothing no longer
/// drags the rest of the screen into a rebuild.
class _QuizSection extends ConsumerWidget {
  final QuizQuestion fallbackQuestion;

  const _QuizSection({required this.fallbackQuestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizData = ref.watch(quizProvider);
    final isQuizVisible = quizData.state != QuizState.notStarted;
    final isSuccess = quizData.state == QuizState.success;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isQuizVisible
          ? (isSuccess
              ? _SuccessCard(onPlayAgain: () {
                  ref.read(quizProvider.notifier).reset();
                  // Reset audio after the card has had a moment to play its
                  // exit transition, so the layout shrink doesn't fight the
                  // fade-out animation.
                  Future.delayed(const Duration(milliseconds: 50), () {
                    ref.read(storyAudioProvider.notifier).reset();
                  });
                })
              : QuizCard(
                  key: const ValueKey('quiz_card'),
                  question: quizData.question ?? fallbackQuestion,
                ))
          : const SizedBox.shrink(key: ValueKey('empty_quiz')),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final VoidCallback onPlayAgain;

  const _SuccessCard({required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('success_card'),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.green.shade300, width: 2),
      ),
      color: Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              "Awesome Job!",
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You successfully answered: Pip's lost gear was Blue!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPlayAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Text("Play Again", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}