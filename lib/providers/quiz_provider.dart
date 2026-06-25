import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';

enum QuizState { notStarted, playing, wrongAnswer, success }

class QuizStateData {
  final QuizState state;
  final QuizQuestion? question;
  final int? selectedIndex;
  final Set<int> wrongAttempts;

  const QuizStateData({
    this.state = QuizState.notStarted,
    this.question,
    this.selectedIndex,
    this.wrongAttempts = const {},
  });

  QuizStateData copyWith({
    QuizState? state,
    QuizQuestion? question,
    int? selectedIndex,
    bool clearSelection = false,
    Set<int>? wrongAttempts,
  }) {
    return QuizStateData(
      state: state ?? this.state,
      question: question ?? this.question,
      selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}

class QuizNotifier extends Notifier<QuizStateData> {
  @override
  QuizStateData build() {
    return const QuizStateData();
  }

  void loadQuestion(QuizQuestion question) {
    state = QuizStateData(
      state: QuizState.playing,
      question: question,
      selectedIndex: null,
      wrongAttempts: {},
    );
  }

  void selectOption(int index) {
    final question = state.question;
    if (question == null || state.state == QuizState.success) return;

    final selectedOption = question.options[index];
    final isCorrect = selectedOption == question.answer;

    if (isCorrect) {
      state = state.copyWith(
        state: QuizState.success,
        selectedIndex: index,
      );
    } else {
      // Mark as wrong attempt
      final newWrongAttempts = Set<int>.from(state.wrongAttempts)..add(index);
      
      // Temporarily transition to wrongAnswer state to trigger shake animation
      state = state.copyWith(
        state: QuizState.wrongAnswer,
        selectedIndex: index,
        wrongAttempts: newWrongAttempts,
      );

      // Return to playing state after a short delay so user can try again
      Future.delayed(const Duration(milliseconds: 600), () {
        if (ref.mounted && state.state == QuizState.wrongAnswer) {
          state = state.copyWith(
            state: QuizState.playing,
            clearSelection: true,
          );
        }
      });
    }
  }

  void reset() {
    state = const QuizStateData();
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizStateData>(() {
  return QuizNotifier();
});
