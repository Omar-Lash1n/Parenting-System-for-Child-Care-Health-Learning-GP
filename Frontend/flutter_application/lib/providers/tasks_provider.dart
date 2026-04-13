// --- lib/providers/tasks_provider.dart ---

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ajial/tasks/models/task_model.dart';
import 'package:Ajial/tasks/models/task_category_model.dart';
import 'package:Ajial/tasks/repositories/task_category_repository.dart';
import 'package:Ajial/tasks/repositories/task_repository.dart';

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

  /// Full category objects from the API (includes id, isSystem, taskCount).
  List<TaskCategoryModel> _categoryModels = [];
  List<TaskCategoryModel> get categoryModels =>
      List.unmodifiable(_categoryModels);

  /// Flat list of category names — used by the UI filter chips.
  /// Index 0 is always 'الكل'.
  List<String> get categories =>
      _categoryModels.isEmpty
          ? ['الكل']
          : _categoryModels.map((c) => c.name).toList();

  /// Whether category data is currently being loaded from the API.
  bool _categoriesLoading = false;
  bool get categoriesLoading => _categoriesLoading;

  /// Error message from the last failed category fetch (null if none).
  String? _categoriesError;
  String? get categoriesError => _categoriesError;

  final _categoryRepo = TaskCategoryRepository();
  final _taskRepo = TaskRepository();

  /// Load categories from the API.
  ///
  /// - If categories are already loaded, skips the fetch (use [reloadCategories]
  ///   to force a refresh).
  /// - Falls back to default categories if the call fails so the UI still works.
  Future<void> loadCategories() async {
    // Skip if already loaded — avoids wiping and re-fetching on every navigate
    if (_categoryModels.isNotEmpty) return;
    await reloadCategories();
  }

  /// Force-fetches categories from the API, replacing any existing data.
  ///
  /// Unlike [loadCategories], this always makes a network request.
  /// It does NOT wipe the visible list first — the old data stays visible
  /// until the new data arrives, so there is no empty-list flash.
  Future<void> reloadCategories() async {
    _categoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final fetched = await _categoryRepo.fetchCategories();
      if (fetched.isNotEmpty) {
        _categoryModels = fetched;
      } else {
        // API returned empty — only use defaults if we have nothing at all
        if (_categoryModels.isEmpty) _useDefaultCategories();
      }
    } catch (e) {
      print('⚠️  TasksProvider.reloadCategories error: $e');
      _categoriesError = e.toString();
      // On failure, keep whatever we already have; only fill defaults if empty
      if (_categoryModels.isEmpty) _useDefaultCategories();
    } finally {
      _categoriesLoading = false;
      // Reset filter if it's out of bounds after reload
      if (_activeFilter >= categories.length) _activeFilter = 0;
      notifyListeners();
    }
  }

  void _useDefaultCategories() {
    _categoryModels = [
      const TaskCategoryModel(
          id: 'default_all',
          name: 'الكل',
          isSystem: true,
          taskCount: 0),
      const TaskCategoryModel(
          id: 'default_home',
          name: 'متطلبات المنزل',
          isSystem: true,
          taskCount: 0),
      const TaskCategoryModel(
          id: 'default_medicine',
          name: 'دواء',
          isSystem: true,
          taskCount: 0),
      const TaskCategoryModel(
          id: 'default_checkup',
          name: 'كشف',
          isSystem: true,
          taskCount: 0),
    ];
  }


  int _activeFilter = 0;
  int get activeFilter => _activeFilter;

  void setFilter(int index) {
    if (_activeFilter == index) return;
    _activeFilter = index;
    notifyListeners();
  }

  /// Creates a new custom category via the API.
  ///
  /// Uses an optimistic-update pattern:
  /// 1. Immediately adds a local placeholder so the UI responds instantly.
  /// 2. Calls POST /TaskCategory and replaces the placeholder with the
  ///    server-created model (which has the real GUID id).
  /// 3. On failure, removes the placeholder and re-throws so the UI can
  ///    show an error message.
  Future<void> addCategory(String name) async {
    // Do NOT short-circuit on local duplicates — the backend is the source of
    // truth. If the category already exists on the server (e.g. after a
    // re-login that didn't refresh local state), the API will return a proper
    // error message that the UI can show. A local-only guard would silently
    // swallow the error and hide the real problem.

    // ── 1. Optimistic local add ──
    final placeholder = TaskCategoryModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isSystem: false,
      taskCount: 0,
    );
    _categoryModels.add(placeholder);
    notifyListeners();

    try {
      // ── 2. Real API call ──
      final created = await _categoryRepo.createCategory(name);

      // Replace placeholder with the server model (keeps real id)
      final idx = _categoryModels.indexWhere((c) => c.id == placeholder.id);
      if (idx != -1) {
        _categoryModels[idx] = created;
        notifyListeners();
      }
    } catch (e) {
      // ── 3. Rollback on failure ──
      _categoryModels.removeWhere((c) => c.id == placeholder.id);
      notifyListeners();
      rethrow; // let the UI handle the error
    }
  }


  // ── Tasks ──
  final List<TaskModel> _tasks = []; // Active tasks
  final List<TaskModel> _doneTasks = []; // Completed tasks

  List<TaskModel> get allTasks {
    final Map<String, TaskModel> map = {};
    // Done tasks have priority if there's an overlap (fresher state)
    for (final t in _tasks) map[t.id] = t;
    for (final t in _doneTasks) map[t.id] = t;
    return map.values.toList();
  }

  List<TaskModel> get myTasks    => _tasks.where((t) => t.isForSelf).toList();
  List<TaskModel> get kidsTasks  => _tasks.where((t) => t.isForChild).toList();

  /// Current visible tasks based on active tab and filter.
  List<TaskModel> get filteredTasks {
    final tabTasks = _activeTab == 0 ? myTasks : kidsTasks;
    if (_activeFilter == 0) return tabTasks;
    final filterName = categories[_activeFilter];
    return tabTasks.where((t) => t.category == filterName).toList();
  }

  int countForFilter(int filterIndex) {
    final tabTasks = _activeTab == 0 ? myTasks : kidsTasks;
    if (filterIndex == 0) return tabTasks.length;
    final filterName = categories[filterIndex];
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

  bool _tasksLoading = false;
  bool get tasksLoading => _tasksLoading;

  Future<void> reloadTasks() async {
    _tasksLoading = true;
    notifyListeners();
    try {
      final fetched = await _taskRepo.fetchActiveTasks();
      _tasks.clear();
      _tasks.addAll(fetched);
    } catch (e) {
      print('⚠️ TasksProvider.reloadTasks error: $e');
    } finally {
      _tasksLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoneTasks() async {
    try {
      final fetched = await _taskRepo.fetchCompletedTasks();
      _doneTasks.clear();
      _doneTasks.addAll(fetched);
      notifyListeners();
    } catch (e) {
      print('⚠️ TasksProvider.loadDoneTasks error: $e');
    }
  }

  Future<void> addTask(TaskModel placeholder) async {
    _tasks.insert(0, placeholder);
    notifyListeners();

    try {
      final colorHex = placeholder.color.value.toRadixString(16).substring(2);
      final childIds = placeholder.assignees
          .where((a) => !a.isSelf)
          .map((a) => a.id)
          .toList();

      DateTime? combinedDate;
      if (placeholder.date != null) {
        combinedDate = DateTime(
          placeholder.date!.year,
          placeholder.date!.month,
          placeholder.date!.day,
          placeholder.time?.hour ?? 0,
          placeholder.time?.minute ?? 0,
        );
      }

      final created = await _taskRepo.createTask(
        title: placeholder.title,
        categoryId: placeholder.categoryId,
        colorHex: colorHex,
        dueDate: combinedDate,
        includeParent: placeholder.isForSelf,
        childIds: childIds,
      );

      final idx = _tasks.indexWhere((t) => t.id == placeholder.id);
      if (idx != -1) {
        _tasks[idx] = created;
        notifyListeners();
      }
    } catch (e) {
      _tasks.removeWhere((t) => t.id == placeholder.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeTask(String id) async {
    TaskModel? target;
    int idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) target = _tasks[idx];

    if (target == null) return;

    _tasks.removeAt(idx);
    notifyListeners();

    try {
      await _taskRepo.deleteTask(id);
    } catch (e) {
      _tasks.insert(idx, target);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel updated) async {
    final idx = _tasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;

    final old = _tasks[idx];
    _tasks[idx] = updated;
    notifyListeners();

    try {
      final colorHex = updated.color.value.toRadixString(16).substring(2);
      final childIds = updated.assignees
          .where((a) => !a.isSelf)
          .map((a) => a.id)
          .toList();

      DateTime? combinedDate;
      if (updated.date != null) {
        combinedDate = DateTime(
          updated.date!.year,
          updated.date!.month,
          updated.date!.day,
          updated.time?.hour ?? 0,
          updated.time?.minute ?? 0,
        );
      }

      final returned = await _taskRepo.updateTask(
        taskId: updated.id,
        title: updated.title,
        categoryId: updated.categoryId,
        colorHex: colorHex,
        dueDate: combinedDate,
        includeParent: updated.isForSelf,
        childIds: childIds,
      );

      _tasks[idx] = returned;
      notifyListeners();
    } catch (e) {
      _tasks[idx] = old;
      notifyListeners();
      rethrow;
    }
  }

  // ── Category helpers ──

  /// Count tasks in a given category (current tab).
  int countForCategory(String name) {
    return _tasks.where((t) => t.category == name).length;
  }

  /// Renames an existing custom category via the API.
  ///
  /// Guards:
  /// - Silent no-op if the category is not found or the name is unchanged.
  /// - Throws [Exception] if the category is a system category (cannot rename).
  ///
  /// Uses optimistic update: renames locally first, rolls back on API failure.
  Future<void> renameCategory(String oldName, String newName) async {
    final idx = _categoryModels.indexWhere((c) => c.name == oldName);
    if (idx == -1 || oldName == newName) return;
    if (_categoryModels.any((c) => c.name == newName)) return;

    final old = _categoryModels[idx];

    // Block renaming system categories
    if (old.isSystem) {
      throw Exception('لا يمكن تعديل التصنيفات الافتراضية للنظام.');
    }

    // ── 1. Optimistic local rename ──
    _categoryModels[idx] = TaskCategoryModel(
      id: old.id,
      name: newName,
      isSystem: old.isSystem,
      taskCount: old.taskCount,
    );
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == oldName) {
        _tasks[i] = _tasks[i].copyWith(category: newName);
      }
    }
    notifyListeners();

    try {
      // ── 2. Real API call ──
      await _categoryRepo.updateCategory(
        categoryId: old.id,
        newName: newName,
      );
    } catch (e) {
      // ── 3. Rollback on failure ──
      _categoryModels[idx] = old;
      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].category == newName) {
          _tasks[i] = _tasks[i].copyWith(category: oldName);
        }
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a custom category via the API and reassigns its tasks to "الكل".
  ///
  /// Guards:
  /// - Silent no-op if the category is not found.
  /// - Throws [Exception] if the category is a system category (cannot delete).
  ///
  /// Uses optimistic update: removes from UI and re-assigns tasks first,
  /// then rolls back on API failure.
  Future<void> removeCategory(String name) async {
    final idx = _categoryModels.indexWhere((c) => c.name == name);
    if (idx == -1) return;

    final target = _categoryModels[idx];

    // Block deleting system categories
    if (target.isSystem) {
      throw Exception('لا يمكن حذف التصنيفات الافتراضية للنظام.');
    }

    // Capture state for rollback
    final originalTasks = List<TaskModel>.from(_tasks);

    // ── 1. Optimistic local delete ──
    _categoryModels.removeAt(idx);
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == name) {
        _tasks[i] = _tasks[i].copyWith(category: 'الكل');
      }
    }
    notifyListeners();

    try {
      // ── 2. Real API call ──
      await _categoryRepo.deleteCategory(target.id);
    } catch (e) {
      // ── 3. Rollback on failure ──
      _categoryModels.insert(idx, target);
      _tasks.clear();
      _tasks.addAll(originalTasks);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleComplete(String id) async {
    TaskModel? task;

    int idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      task = _tasks[idx];
    } else {
      idx = _doneTasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        task = _doneTasks[idx];
      }
    }

    if (task == null) return;

    // Optimistic toggle (keep it in its list, the getters handle filtering)
    task.isCompleted = !task.isCompleted;
    notifyListeners();

    try {
      await _taskRepo.toggleTaskCompletion(id);
    } catch (e) {
      // Rollback
      task.isCompleted = !task.isCompleted;
      notifyListeners();
      rethrow;
    }
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
    // Clear categories so the next login always fetches fresh data from the API
    // Clear state on logout
    _categoryModels = [];
    _categoriesError = null;
    _tasks.clear();
    _doneTasks.clear();
    notifyListeners();
  }
}
