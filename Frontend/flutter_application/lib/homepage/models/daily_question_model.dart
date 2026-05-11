class DailyQuestionOption {
  final String id;
  final String optionText;
  final int orderIndex;

  const DailyQuestionOption({
    required this.id,
    required this.optionText,
    required this.orderIndex,
  });

  factory DailyQuestionOption.fromJson(Map<String, dynamic> json) {
    return DailyQuestionOption(
      id: json['id']?.toString() ?? '',
      optionText: json['optionText']?.toString() ?? '',
      orderIndex: json['orderIndex'] is int
          ? json['orderIndex'] as int
          : int.tryParse(json['orderIndex']?.toString() ?? '') ?? 0,
    );
  }
}

class PreviousDailyQuestionAnswer {
  final String selectedOptionId;
  final bool isCorrect;
  final int starsEarned;
  final String correctOptionId;

  const PreviousDailyQuestionAnswer({
    required this.selectedOptionId,
    required this.isCorrect,
    required this.starsEarned,
    required this.correctOptionId,
  });

  factory PreviousDailyQuestionAnswer.fromJson(Map<String, dynamic> json) {
    return PreviousDailyQuestionAnswer(
      selectedOptionId: json['selectedOptionId']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      starsEarned: json['starsEarned'] is int
          ? json['starsEarned'] as int
          : int.tryParse(json['starsEarned']?.toString() ?? '') ?? 0,
      correctOptionId: json['correctOptionId']?.toString() ?? '',
    );
  }
}

class ActiveDailyQuestion {
  final String id;
  final String questionText;
  final int starsReward;
  final List<DailyQuestionOption> options;
  final bool hasAnswered;
  final PreviousDailyQuestionAnswer? previousAnswer;

  const ActiveDailyQuestion({
    required this.id,
    required this.questionText,
    required this.starsReward,
    required this.options,
    required this.hasAnswered,
    required this.previousAnswer,
  });

  factory ActiveDailyQuestion.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'];
    return ActiveDailyQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      starsReward: json['starsReward'] is int
          ? json['starsReward'] as int
          : int.tryParse(json['starsReward']?.toString() ?? '') ?? 0,
      options: optionsJson is List
          ? optionsJson
              .whereType<Map>()
              .map((item) => DailyQuestionOption.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      hasAnswered: json['hasAnswered'] == true,
      previousAnswer: json['previousAnswer'] is Map
          ? PreviousDailyQuestionAnswer.fromJson(
              Map<String, dynamic>.from(json['previousAnswer'] as Map),
            )
          : null,
    );
  }
}

class DailyQuestionAnswerResult {
  final bool isCorrect;
  final int starsEarned;
  final String correctOptionId;
  final int newStarsBalance;
  final String message;

  const DailyQuestionAnswerResult({
    required this.isCorrect,
    required this.starsEarned,
    required this.correctOptionId,
    required this.newStarsBalance,
    required this.message,
  });

  factory DailyQuestionAnswerResult.fromJson(
    Map<String, dynamic> json, {
    required String message,
  }) {
    return DailyQuestionAnswerResult(
      isCorrect: json['isCorrect'] == true,
      starsEarned: json['starsEarned'] is int
          ? json['starsEarned'] as int
          : int.tryParse(json['starsEarned']?.toString() ?? '') ?? 0,
      correctOptionId: json['correctOptionId']?.toString() ?? '',
      newStarsBalance: json['newStarsBalance'] is int
          ? json['newStarsBalance'] as int
          : int.tryParse(json['newStarsBalance']?.toString() ?? '') ?? 0,
      message: message,
    );
  }
}
