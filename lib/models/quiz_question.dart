class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final Map<String, dynamic> extraMetadata;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.extraMetadata = const {},
  });

  /// Factory constructor that performs defensive parsing of JSON data.
  factory QuizQuestion.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const QuizQuestion(
        question: 'What colour was Pip\'s lost gear?',
        options: ['Red', 'Green', 'Blue', 'Yellow'],
        answer: 'Blue',
      );
    }

    // Parse question defensively
    final questionStr = json['question'];
    final question = (questionStr is String && questionStr.trim().isNotEmpty)
        ? questionStr.trim()
        : 'What colour was Pip\'s lost gear?';

    // Parse options defensively
    final optionsRaw = json['options'];
    final List<String> optionsList = [];
    if (optionsRaw is List) {
      for (var element in optionsRaw) {
        if (element != null) {
          final elementStr = element.toString().trim();
          if (elementStr.isNotEmpty) {
            optionsList.add(elementStr);
          }
        }
      }
    }

    // Fallback if options list is empty or too short
    final options = optionsList.isNotEmpty
        ? optionsList
        : ['Red', 'Green', 'Blue', 'Yellow'];

    // Parse answer defensively
    final answerStr = json['answer'];
    String answer = (answerStr is String && answerStr.trim().isNotEmpty)
        ? answerStr.trim()
        : '';

    // If answer is empty or not in the options list, fallback to first option or a sensible default
    if (answer.isEmpty || !options.contains(answer)) {
      // Look for first option matching or fallback
      answer = options.first;
    }

    // Capture any unrecognized fields into extraMetadata
    final extra = <String, dynamic>{};
    json.forEach((key, value) {
      if (key != 'question' && key != 'options' && key != 'answer') {
        extra[key] = value;
      }
    });

    return QuizQuestion(
      question: question,
      options: options,
      answer: answer,
      extraMetadata: extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'answer': answer,
      ...extraMetadata,
    };
  }
}
