// --- lib/providers/tasks_provider.dart ---

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ajial/tasks/models/task_model.dart';

class TasksProvider extends ChangeNotifier {
  static const String _instructionsSeenKey = 'tasks_instructions_seen';

  // ── Tab: 0 = مهامي, 1 = مهام اطفالي ──
  int _activeTab = 0;
  int get activeTab => _activeTab;

  void switchTab(int index) {
    if (_activeTab == index) return;
    _activeTab = index;
    notifyListeners();
  }

  // ── Categories / Filters ──
  final List<String> _categories = ['الكل', 'متطلبات المنزل', 'دواء', 'كشف'];
  List<String> get categories => List.unmodifiable(_categories);


  int _activeFilter = 0;
  int get activeFilter => _activeFilter;

  void setFilter(int index) {
    if (_activeFilter == index) return;
    _activeFilter = index;
    notifyListeners();
  }

  void addCategory(String name) {
    if (!_categories.contains(name)) {
      _categories.add(name);
      notifyListeners();
    }
  }

  // ── Tasks ──
  final List<TaskModel> _tasks = [];
  List<TaskModel> get allTasks => List.unmodifiable(_tasks);

  List<TaskModel> get myTasks    => _tasks.where((t) => t.isForSelf).toList();
  List<TaskModel> get kidsTasks  => _tasks.where((t) => t.isForChild).toList();

  /// Current visible tasks based on active tab and filter.
  List<TaskModel> get filteredTasks {
    final tabTasks = _activeTab == 0 ? myTasks : kidsTasks;
    if (_activeFilter == 0) return tabTasks;
    final filterName = _categories[_activeFilter];
    return tabTasks.where((t) => t.category == filterName).toList();
  }

  int countForFilter(int filterIndex) {
    final tabTasks = _activeTab == 0 ? myTasks : kidsTasks;
    if (filterIndex == 0) return tabTasks.length;
    final filterName = _categories[filterIndex];
    return tabTasks.where((t) => t.category == filterName).length;
  }

  /// Returns tasks grouped by time section (only those matching active tab+filter).
  Map<TaskGroup, List<TaskModel>> get groupedTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    final tasks = filteredTasks;

    final Map<TaskGroup, List<TaskModel>> result = {
      TaskGroup.past: [],
      TaskGroup.yesterday: [],
      TaskGroup.today: [],
      TaskGroup.tomorrow: [],
      TaskGroup.future: [],
      TaskGroup.completed: [],
    };

    for (final t in tasks) {
      if (t.isCompleted) {
        result[TaskGroup.completed]!.add(t);
        continue;
      }

      // Tasks with no date go into "today"
      if (t.date == null) {
        result[TaskGroup.today]!.add(t);
        continue;
      }

      final taskDay = DateTime(t.date!.year, t.date!.month, t.date!.day);

      if (taskDay.isBefore(yesterday)) {
        result[TaskGroup.past]!.add(t);
      } else if (taskDay == yesterday) {
        result[TaskGroup.yesterday]!.add(t);
      } else if (taskDay == today) {
        result[TaskGroup.today]!.add(t);
      } else if (taskDay == tomorrow) {
        result[TaskGroup.tomorrow]!.add(t);
      } else {
        result[TaskGroup.future]!.add(t);
      }
    }

    return result;
  }

  void addTask(TaskModel task) {
    _tasks.insert(0, task);
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void updateTask(TaskModel updated) {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _tasks[index] = updated;
      notifyListeners();
    }
  }

  // ── Category helpers ──

  /// Count tasks in a given category (current tab).
  int countForCategory(String name) {
    return _tasks.where((t) => t.category == name).length;
  }

  /// Rename an existing category and update all tasks that use it.
  void renameCategory(String oldName, String newName) {
    final idx = _categories.indexOf(oldName);
    if (idx == -1 || _categories.contains(newName)) return;
    _categories[idx] = newName;
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == oldName) {
        _tasks[i] = _tasks[i].copyWith(category: newName);
      }
    }
    notifyListeners();
  }

  /// Remove a category and reassign its tasks to "الكل".
  void removeCategory(String name) {
    _categories.remove(name);
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == name) {
        _tasks[i] = _tasks[i].copyWith(category: 'الكل');
      }
    }
    notifyListeners();
  }

  void toggleComplete(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isCompleted = !task.isCompleted;
    notifyListeners();
  }

  // ── First-time instructions ──
  bool _instructionsSeen = true;
  bool get instructionsSeen => _instructionsSeen;

  int _instructionStep = 0;
  int get instructionStep => _instructionStep;

  bool _showInstructions = false;
  bool get showInstructions => _showInstructions;

  Future<void> checkInstructionsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    _instructionsSeen = prefs.getBool(_instructionsSeenKey) ?? false;
    if (!_instructionsSeen) {
      _showInstructions = true;
      _instructionStep = 0;
      _activeTab = 0;
    }
    notifyListeners();
  }

  void nextInstructionStep() {
    if (_instructionStep < 2) {
      _instructionStep++;
      if (_instructionStep == 1) _activeTab = 1;
      notifyListeners();
    } else {
      markInstructionsSeen();
    }
  }

  void skipInstructions() => markInstructionsSeen();

  Future<void> markInstructionsSeen() async {
    _instructionsSeen = true;
    _showInstructions = false;
    _activeTab = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_instructionsSeenKey, true);
  }

  void reset() {
    _activeTab = 0;
    _activeFilter = 0;
    _instructionStep = 0;
    _showInstructions = false;
    notifyListeners();
  }
}
