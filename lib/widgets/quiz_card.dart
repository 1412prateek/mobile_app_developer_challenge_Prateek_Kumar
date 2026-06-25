import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';
import '../providers/quiz_provider.dart';

class QuizCard extends ConsumerStatefulWidget {
  final QuizQuestion question;

  const QuizCard({
    super.key,
    required this.question,
  });

  @override
  ConsumerState<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends ConsumerState<QuizCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // Custom physics-aligned shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 12.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizData = ref.watch(quizProvider);

    // Setup listener to trigger shake and haptics on wrong answer
    ref.listen<QuizStateData>(quizProvider, (previous, next) {
      if (next.state == QuizState.wrongAnswer) {
        _shakeController.forward(from: 0.0);
        HapticFeedback.lightImpact();
      }
    });

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0.0),
          child: child,
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "QUIZ TIME!",
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (quizData.state == QuizState.success)
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                        SizedBox(width: 4),
                        Text(
                          "Completed!",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Question Text
              Text(
                widget.question.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.indigo.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 20),
              // Dynamic Options List
              Column(
                children: List.generate(widget.question.options.length, (index) {
                  final option = widget.question.options[index];
                  final isSelected = quizData.selectedIndex == index;
                  final isWrong = quizData.wrongAttempts.contains(index);
                  final isCorrect = quizData.state == QuizState.success && option == widget.question.answer;

                  // Styling determinations
                  Color cardBg = Colors.grey.shade50;
                  Color borderColor = Colors.grey.shade300;
                  Color textColor = Colors.black87;
                  Widget iconAvatar = _buildLetterAvatar(index, Colors.indigo.shade400);

                  if (isCorrect) {
                    cardBg = Colors.green.shade50;
                    borderColor = Colors.green.shade400;
                    textColor = Colors.green.shade900;
                    iconAvatar = const Icon(Icons.check_circle, color: Colors.green, size: 24);
                  } else if (isWrong) {
                    cardBg = Colors.red.shade50;
                    borderColor = Colors.red.shade300;
                    textColor = Colors.red.shade900;
                    iconAvatar = const Icon(Icons.cancel, color: Colors.red, size: 24);
                  } else if (isSelected && quizData.state == QuizState.wrongAnswer) {
                    cardBg = Colors.orange.shade50;
                    borderColor = Colors.orange.shade400;
                    textColor = Colors.orange.shade900;
                    iconAvatar = const Icon(Icons.warning_rounded, color: Colors.orange, size: 24);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: quizData.state == QuizState.success
                          ? null
                          : () {
                              ref.read(quizProvider.notifier).selectOption(index);
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: (isSelected || isCorrect || isWrong) ? 2.5 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            iconAvatar,
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterAvatar(int index, Color color) {
    final letter = String.fromCharCode(65 + index); // A, B, C, D...
    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withOpacity(0.15),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
