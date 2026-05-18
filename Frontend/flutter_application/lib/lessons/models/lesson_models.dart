class LessonCategoryModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final int orderIndex;
  final int lessonCount;

  const LessonCategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.orderIndex,
    required this.lessonCount,
  });

  factory LessonCategoryModel.fromJson(Map<String, dynamic> json) {
    return LessonCategoryModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class LessonCardModel {
  final String id;
  final String titleAr;
  final String contentPreviewAr;
  final String? imageUrl;
  final String categoryNameAr;
  final String categoryId;
  final int totalStarsReward;
  final int questionsCount;
  final bool isRead;
  final bool isQuizCompleted;
  final int starsEarned;

  const LessonCardModel({
    required this.id,
    required this.titleAr,
    required this.contentPreviewAr,
    this.imageUrl,
    required this.categoryNameAr,
    required this.categoryId,
    required this.totalStarsReward,
    required this.questionsCount,
    required this.isRead,
    required this.isQuizCompleted,
    required this.starsEarned,
  });

  factory LessonCardModel.fromJson(Map<String, dynamic> json) {
    return LessonCardModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? '',
      contentPreviewAr: json['contentPreviewAr']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      categoryNameAr: json['categoryNameAr']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      totalStarsReward: (json['totalStarsReward'] as num?)?.toInt() ?? 0,
      questionsCount: (json['questionsCount'] as num?)?.toInt() ?? 0,
      isRead: json['isRead'] as bool? ?? false,
      isQuizCompleted: json['isQuizCompleted'] as bool? ?? false,
      starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class LessonDetailModel {
  final String id;
  final String titleAr;
  final String contentAr;
  final String? imageUrl;
  final String? videoUrl;
  final String categoryId;
  final String categoryNameAr;
  final int totalStarsReward;
  final int questionsCount;
  final bool isRead;
  final bool isQuizCompleted;
  final int starsEarned;

  const LessonDetailModel({
    required this.id,
    required this.titleAr,
    required this.contentAr,
    this.imageUrl,
    this.videoUrl,
    required this.categoryId,
    required this.categoryNameAr,
    required this.totalStarsReward,
    required this.questionsCount,
    required this.isRead,
    required this.isQuizCompleted,
    required this.starsEarned,
  });

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    return LessonDetailModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? '',
      contentAr: json['contentAr']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      categoryNameAr: json['categoryNameAr']?.toString() ?? '',
      totalStarsReward: (json['totalStarsReward'] as num?)?.toInt() ?? 0,
      questionsCount: (json['questionsCount'] as num?)?.toInt() ?? 0,
      isRead: json['isRead'] as bool? ?? false,
      isQuizCompleted: json['isQuizCompleted'] as bool? ?? false,
      starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class LessonQuizOptionModel {
  final String id;
  final String optionText;
  final int orderIndex;

  const LessonQuizOptionModel({
    required this.id,
    required this.optionText,
    required this.orderIndex,
  });

  factory LessonQuizOptionModel.fromJson(Map<String, dynamic> json) {
    return LessonQuizOptionModel(
      id: json['id']?.toString() ?? '',
      optionText: json['optionText']?.toString() ?? '',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class LessonPreviousAnswerModel {
  final String selectedOptionId;
  final bool isCorrect;
  final int starsEarned;
  final String correctOptionId;

  const LessonPreviousAnswerModel({
    required this.selectedOptionId,
    required this.isCorrect,
    required this.starsEarned,
    required this.correctOptionId,
  });

  factory LessonPreviousAnswerModel.fromJson(Map<String, dynamic> json) {
    return LessonPreviousAnswerModel(
      selectedOptionId: json['selectedOptionId']?.toString() ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
      correctOptionId: json['correctOptionId']?.toString() ?? '',
    );
  }
}

class LessonQuizQuestionModel {
  final String id;
  final String questionText;
  final int starsReward;
  final int orderIndex;
  final List<LessonQuizOptionModel> options;
  final bool hasAnswered;
  final LessonPreviousAnswerModel? previousAnswer;

  const LessonQuizQuestionModel({
    required this.id,
    required this.questionText,
    required this.starsReward,
    required this.orderIndex,
    required this.options,
    required this.hasAnswered,
    this.previousAnswer,
  });

  factory LessonQuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((o) => LessonQuizOptionModel.fromJson(
                  Map<String, dynamic>.from(o),
                ))
            .toList()
        : <LessonQuizOptionModel>[];

    LessonPreviousAnswerModel? previousAnswer;
    if (json['previousAnswer'] is Map) {
      previousAnswer = LessonPreviousAnswerModel.fromJson(
        Map<String, dynamic>.from(json['previousAnswer'] as Map),
      );
    }

    return LessonQuizQuestionModel(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      starsReward: (json['starsReward'] as num?)?.toInt() ?? 0,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      options: options,
      hasAnswered: json['hasAnswered'] as bool? ?? false,
      previousAnswer: previousAnswer,
    );
  }
}

class MarkLessonReadResult {
  final bool isRead;
  final List<LessonQuizQuestionModel> questions;

  const MarkLessonReadResult({
    required this.isRead,
    required this.questions,
  });

  factory MarkLessonReadResult.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((q) => LessonQuizQuestionModel.fromJson(
                  Map<String, dynamic>.from(q),
                ))
            .toList()
        : <LessonQuizQuestionModel>[];
    return MarkLessonReadResult(
      isRead: json['isRead'] as bool? ?? false,
      questions: questions,
    );
  }
}

class LessonAnswerResult {
  final bool isCorrect;
  final int starsEarned;
  final String correctOptionId;
  final int newStarsBalance;
  final bool isQuizCompleted;
  final int totalLessonStarsEarned;
  final String message;

  const LessonAnswerResult({
    required this.isCorrect,
    required this.starsEarned,
    required this.correctOptionId,
    required this.newStarsBalance,
    required this.isQuizCompleted,
    required this.totalLessonStarsEarned,
    required this.message,
  });

  factory LessonAnswerResult.fromJson(
    Map<String, dynamic> json, {
    String message = '',
  }) {
    return LessonAnswerResult(
      isCorrect: json['isCorrect'] as bool? ?? false,
      starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
      correctOptionId: json['correctOptionId']?.toString() ?? '',
      newStarsBalance: (json['newStarsBalance'] as num?)?.toInt() ?? 0,
      isQuizCompleted: json['isQuizCompleted'] as bool? ?? false,
      totalLessonStarsEarned:
          (json['totalLessonStarsEarned'] as num?)?.toInt() ?? 0,
      message: message,
    );
  }
}
