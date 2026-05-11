import 'package:flutter/foundation.dart';
import 'package:Ajial/homepage/models/current_vaccination_model.dart';
import 'package:Ajial/homepage/models/daily_question_model.dart';
import 'package:Ajial/homepage/models/upcoming_task_model.dart';
import 'package:Ajial/homepage/repositories/parent_home_repository.dart';

enum HomeDataStatus { initial, loading, loaded, error }

class ParentHomeProvider extends ChangeNotifier {
  final ParentHomeRepository _repository;

  ParentHomeProvider({ParentHomeRepository? repository})
      : _repository = repository ?? ParentHomeRepository();

  HomeDataStatus _vaccinationsStatus = HomeDataStatus.initial;
  HomeDataStatus _tasksStatus = HomeDataStatus.initial;
  HomeDataStatus _dailyQuestionStatus = HomeDataStatus.initial;
  List<CurrentVaccinationModel> _vaccinations = [];
  List<UpcomingTaskModel> _tasks = [];
  ActiveDailyQuestion? _dailyQuestion;
  String? _vaccinationsError;
  String? _tasksError;
  String? _dailyQuestionError;
  bool _isSubmittingDailyQuestion = false;

  HomeDataStatus get vaccinationsStatus => _vaccinationsStatus;
  HomeDataStatus get tasksStatus => _tasksStatus;
  HomeDataStatus get dailyQuestionStatus => _dailyQuestionStatus;
  List<CurrentVaccinationModel> get vaccinations =>
      List.unmodifiable(_vaccinations);
  List<UpcomingTaskModel> get tasks => List.unmodifiable(_tasks);
  ActiveDailyQuestion? get dailyQuestion => _dailyQuestion;
  String? get vaccinationsError => _vaccinationsError;
  String? get tasksError => _tasksError;
  String? get dailyQuestionError => _dailyQuestionError;
  bool get isSubmittingDailyQuestion => _isSubmittingDailyQuestion;

  bool get isInitialLoading =>
      (_vaccinationsStatus == HomeDataStatus.initial ||
          _vaccinationsStatus == HomeDataStatus.loading) &&
      (_tasksStatus == HomeDataStatus.initial ||
          _tasksStatus == HomeDataStatus.loading);

  Future<void> loadAll() async {
    await Future.wait([
      loadDailyQuestion(),
      loadVaccinations(),
      loadTasks(),
    ]);
  }

  Future<void> loadDailyQuestion() async {
    _dailyQuestionStatus = HomeDataStatus.loading;
    _dailyQuestionError = null;
    notifyListeners();

    try {
      _dailyQuestion = await _repository.fetchActiveDailyQuestion();
      _dailyQuestionStatus = HomeDataStatus.loaded;
    } catch (e) {
      _dailyQuestionError = e.toString().replaceFirst('Exception: ', '');
      _dailyQuestionStatus = HomeDataStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<DailyQuestionAnswerResult> submitDailyQuestionAnswer({
    required String questionId,
    required String selectedOptionId,
  }) async {
    _isSubmittingDailyQuestion = true;
    notifyListeners();

    try {
      final result = await _repository.submitDailyQuestionAnswer(
        questionId: questionId,
        selectedOptionId: selectedOptionId,
      );
      await loadDailyQuestion();
      return result;
    } finally {
      _isSubmittingDailyQuestion = false;
      notifyListeners();
    }
  }

  Future<void> loadVaccinations() async {
    _vaccinationsStatus = HomeDataStatus.loading;
    _vaccinationsError = null;
    notifyListeners();

    try {
      _vaccinations = await _repository.fetchCurrentVaccinations();
      _vaccinationsStatus = HomeDataStatus.loaded;
    } catch (e) {
      _vaccinationsError = e.toString().replaceFirst('Exception: ', '');
      _vaccinationsStatus = HomeDataStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadTasks() async {
    _tasksStatus = HomeDataStatus.loading;
    _tasksError = null;
    notifyListeners();

    try {
      _tasks = await _repository.fetchUpcomingTasks(limit: 5);
      _tasksStatus = HomeDataStatus.loaded;
    } catch (e) {
      _tasksError = e.toString().replaceFirst('Exception: ', '');
      _tasksStatus = HomeDataStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _vaccinationsStatus = HomeDataStatus.initial;
    _tasksStatus = HomeDataStatus.initial;
    _dailyQuestionStatus = HomeDataStatus.initial;
    _vaccinations = [];
    _tasks = [];
    _dailyQuestion = null;
    _vaccinationsError = null;
    _tasksError = null;
    _dailyQuestionError = null;
    _isSubmittingDailyQuestion = false;
    notifyListeners();
  }
}
