import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_story_buddy/models/quiz_question.dart';
import 'package:peblo_story_buddy/providers/quiz_provider.dart';

void main() {
  group('QuizQuestion Defensive Parsing Tests', () {
    test('Parses valid JSON correctly', () {
      final json = {
        'question': 'What colour was Pip\'s gear?',
        'options': ['Red', 'Green', 'Blue', 'Yellow'],
        'answer': 'Blue',
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.question, equals('What colour was Pip\'s gear?'));
      expect(question.options, equals(['Red', 'Green', 'Blue', 'Yellow']));
      expect(question.answer, equals('Blue'));
    });

    test('Handles missing fields with defaults', () {
      final question = QuizQuestion.fromJson(null);

      expect(question.question, isNotEmpty);
      expect(question.options, isNotEmpty);
      expect(question.options.length, equals(4));
      expect(question.options.contains(question.answer), isTrue);
    });

    test('Handles empty JSON or invalid option formats', () {
      final json = {
        'question': '',
        'options': 'not a list',
        'answer': 'Blue',
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.question, isNotEmpty); // should fallback
      expect(question.options, equals(['Red', 'Green', 'Blue', 'Yellow'])); // should fallback
      expect(question.answer, equals('Blue')); // since 'Blue' is present in fallback options
    });

    test('Supports variable option lengths (3 options)', () {
      final json = {
        'question': 'How many gears?',
        'options': ['One', 'Two', 'Three'],
        'answer': 'Three',
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.options.length, equals(3));
      expect(question.answer, equals('Three'));
    });

    test('Filters out empty or null items in options', () {
      final json = {
        'question': 'What is the color?',
        'options': ['Red', null, '  ', 'Blue'],
        'answer': 'Blue',
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.options, equals(['Red', 'Blue']));
      expect(question.answer, equals('Blue'));
    });
  });

  group('Quiz State Provider Tests', () {
    test('Initial state is notStarted', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(quizProvider);
      expect(state.state, equals(QuizState.notStarted));
      expect(state.question, isNull);
      expect(state.selectedIndex, isNull);
    });

    test('loadQuestion transitions state to playing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final question = QuizQuestion.fromJson({
        'question': 'Is Pip a robot?',
        'options': ['Yes', 'No'],
        'answer': 'Yes',
      });

      container.read(quizProvider.notifier).loadQuestion(question);

      final state = container.read(quizProvider);
      expect(state.state, equals(QuizState.playing));
      expect(state.question, equals(question));
      expect(state.selectedIndex, isNull);
    });

    test('Selecting correct answer transitions to success', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final question = QuizQuestion.fromJson({
        'question': 'Is Pip a robot?',
        'options': ['Yes', 'No'],
        'answer': 'Yes',
      });

      container.read(quizProvider.notifier).loadQuestion(question);
      container.read(quizProvider.notifier).selectOption(0); // 'Yes'

      final state = container.read(quizProvider);
      expect(state.state, equals(QuizState.success));
      expect(state.selectedIndex, equals(0));
    });

    test('Selecting wrong answer transitions to wrongAnswer, and returns to playing after delay', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final question = QuizQuestion.fromJson({
        'question': 'Is Pip a robot?',
        'options': ['Yes', 'No'],
        'answer': 'Yes',
      });

      container.read(quizProvider.notifier).loadQuestion(question);
      container.read(quizProvider.notifier).selectOption(1); // 'No' (Wrong)

      var state = container.read(quizProvider);
      expect(state.state, equals(QuizState.wrongAnswer));
      expect(state.selectedIndex, equals(1));
      expect(state.wrongAttempts.contains(1), isTrue);

      // Wait for delay
      await Future.delayed(const Duration(milliseconds: 650));

      state = container.read(quizProvider);
      expect(state.state, equals(QuizState.playing));
      expect(state.selectedIndex, isNull); // Selection cleared
      expect(state.wrongAttempts.contains(1), isTrue); // Wrong attempts list persists
    });
  });
}
