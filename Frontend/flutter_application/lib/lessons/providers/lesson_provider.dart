import 'package:flutter/foundation.dart';
import 'package:Ajial/lessons/models/lesson_models.dart';
import 'package:Ajial/lessons/repositories/lesson_repository.dart';

enum LessonsStatus { initial, loading, loaded, error }

class LessonProvider extends ChangeNotifier {
  final LessonRepository _repository;

  LessonProvider({LessonRepository? repository})
      : _repository = repository ?? LessonRepository();

  // ── Categories ────────────────────────────────────────────────────────────
  LessonsStatus _categoriesStatus = LessonsStatus.initial;
  List<LessonCategoryModel> _categories = [];
  String? _categoriesError;

  LessonsStatus get categoriesStatus => _categoriesStatus;
  List<LessonCategoryModel> get categories => List.unmodifiable(_categories);
  String? get categoriesError => _categoriesError;

  // ── Lessons list ──────────────────────────────────────────────────────────
  LessonsStatus _lessonsStatus = LessonsStatus.initial;
  List<LessonCardModel> _lessons = [];
  String? _lessonsError;

  LessonsStatus get lessonsStatus => _lessonsStatus;
  List<LessonCardModel> get lessons => List.unmodifiable(_lessons);
  String? get lessonsError => _lessonsError;

  // ── Lesson detail ─────────────────────────────────────────────────────────
  LessonsStatus _lessonDetailStatus = LessonsStatus.initial;
  LessonDetailModel? _currentLesson;
  String? _lessonDetailError;

  LessonsStatus get lessonDetailStatus => _lessonDetailStatus;
  LessonDetailModel? get currentLesson => _currentLesson;
  String? get lessonDetailError => _lessonDetailError;

  // ── Mark-read / Quiz questions ────────────────────────────────────────────
  LessonsStatus _markReadStatus = LessonsStatus.initial;
  List<LessonQuizQuestionModel> _quizQuestions = [];
  String? _markReadError;

  LessonsStatus get markReadStatus => _markReadStatus;
  List<LessonQuizQuestionModel> get quizQuestions =>
      List.unmodifiable(_quizQuestions);
  String? get markReadError => _markReadError;

  // ── Answer submission ─────────────────────────────────────────────────────
  bool _isSubmittingAnswer = false;
  bool get isSubmittingAnswer => _isSubmittingAnswer;

  // ── Public methods ────────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    _categoriesStatus = LessonsStatus.loading;
    _categoriesError = null;
    notifyListeners();
    try {
      _categories = await _repository.fetchCategories();
      _categoriesStatus = LessonsStatus.loaded;
    } catch (e) {
      _categoriesError = e.toString().replaceFirst('Exception: ', '');
      _categoriesStatus = LessonsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadLessons({
    String? categoryId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    _lessonsStatus = LessonsStatus.loading;
    _lessonsError = null;
    notifyListeners();
    try {
      _lessons = await _repository.fetchLessons(
        categoryId: categoryId,
        search: search,
        page: page,
        pageSize: pageSize,
      );
      _lessonsStatus = LessonsStatus.loaded;
    } catch (e) {
      _lessonsError = e.toString().replaceFirst('Exception: ', '');
      _lessonsStatus = LessonsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadLessonDetail(String lessonId) async {
    _lessonDetailStatus = LessonsStatus.loading;
    _currentLesson = null;
    _lessonDetailError = null;
    notifyListeners();
    try {
      _currentLesson = await _repository.fetchLessonDetail(lessonId);
      _lessonDetailStatus = LessonsStatus.loaded;
    } catch (e) {
      _lessonDetailError = e.toString().replaceFirst('Exception: ', '');
      _lessonDetailStatus = LessonsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markLessonRead(String lessonId) async {
    _markReadStatus = LessonsStatus.loading;
    _quizQuestions = [];
    _markReadError = null;
    notifyListeners();
    try {
      final result = await _repository.markLessonRead(lessonId);
      _quizQuestions = result.questions;
      _markReadStatus = LessonsStatus.loaded;
    } catch (e) {
      _markReadError = e.toString().replaceFirst('Exception: ', '');
      _markReadStatus = LessonsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String questionId,
    required String selectedOptionId,
  }) async {
    _isSubmittingAnswer = true;
    notifyListeners();
    try {
      return await _repository.submitAnswer(
        lessonId: lessonId,
        questionId: questionId,
        selectedOptionId: selectedOptionId,
      );
    } finally {
      _isSubmittingAnswer = false;
      notifyListeners();
    }
  }

  void resetDetail() {
    _lessonDetailStatus = LessonsStatus.initial;
    _currentLesson = null;
    _lessonDetailError = null;
    _markReadStatus = LessonsStatus.initial;
    _quizQuestions = [];
    _markReadError = null;
    notifyListeners();
  }
}
