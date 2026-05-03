import 'package:flutter/foundation.dart';
import 'package:Ajial/homepage/models/current_vaccination_model.dart';
import 'package:Ajial/homepage/models/upcoming_task_model.dart';
import 'package:Ajial/homepage/repositories/parent_home_repository.dart';

enum HomeDataStatus { initial, loading, loaded, error }

class ParentHomeProvider extends ChangeNotifier {
  final ParentHomeRepository _repository;

  ParentHomeProvider({ParentHomeRepository? repository})
      : _repository = repository ?? ParentHomeRepository();

  HomeDataStatus _vaccinationsStatus = HomeDataStatus.initial;
  HomeDataStatus _tasksStatus = HomeDataStatus.initial;
  List<CurrentVaccinationModel> _vaccinations = [];
  List<UpcomingTaskModel> _tasks = [];
  String? _vaccinationsError;
  String? _tasksError;

  HomeDataStatus get vaccinationsStatus => _vaccinationsStatus;
  HomeDataStatus get tasksStatus => _tasksStatus;
  List<CurrentVaccinationModel> get vaccinations =>
      List.unmodifiable(_vaccinations);
  List<UpcomingTaskModel> get tasks => List.unmodifiable(_tasks);
  String? get vaccinationsError => _vaccinationsError;
  String? get tasksError => _tasksError;

  bool get isInitialLoading =>
      (_vaccinationsStatus == HomeDataStatus.initial ||
          _vaccinationsStatus == HomeDataStatus.loading) &&
      (_tasksStatus == HomeDataStatus.initial ||
          _tasksStatus == HomeDataStatus.loading);

  Future<void> loadAll() async {
    await Future.wait([
      loadVaccinations(),
      loadTasks(),
    ]);
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
    _vaccinations = [];
    _tasks = [];
    _vaccinationsError = null;
    _tasksError = null;
    notifyListeners();
  }
}
