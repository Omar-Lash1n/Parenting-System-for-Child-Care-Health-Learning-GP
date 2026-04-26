// lib/prizes/add_edit_prize_provider.dart
//
// State for the Add Prize / Edit Prize form.
// Reuses ChildTaskRepository for child + child-task lookups, and uses
// PrizeRepository for the create/update calls.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/tasks/models/child_task_model.dart';
import 'package:Ajial/tasks/models/task_list_model.dart';
import 'package:Ajial/tasks/repositories/child_task_repository.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';
import 'package:Ajial/prizes/repositories/prize_repository.dart';

enum FormMode { add, edit }

class AddEditPrizeProvider extends ChangeNotifier {
  final PrizeRepository _prizeRepo;
  final ChildTaskRepository _childTaskRepo;
  final ImagePicker _picker = ImagePicker();

  AddEditPrizeProvider({
    PrizeRepository? prizeRepo,
    ChildTaskRepository? childTaskRepo,
  })  : _prizeRepo = prizeRepo ?? PrizeRepository(),
        _childTaskRepo = childTaskRepo ?? ChildTaskRepository();

  // ── Form mode + initial prize (edit only) ────────────────────────────────
  FormMode _mode = FormMode.add;
  PrizeDetail? _editingPrize;

  FormMode get mode => _mode;
  PrizeDetail? get editingPrize => _editingPrize;
  bool get isEdit => _mode == FormMode.edit;

  // ── Loading flags ────────────────────────────────────────────────────────
  bool _loadingChildren = false;
  bool _loadingTasks = false;
  bool _submitting = false;
  String? _error;

  bool get loadingChildren => _loadingChildren;
  bool get loadingTasks => _loadingTasks;
  bool get submitting => _submitting;
  String? get error => _error;

  // ── Data ─────────────────────────────────────────────────────────────────
  List<ChildTaskModel> _children = const [];
  List<TaskItem> _availableTasks = const [];

  List<ChildTaskModel> get children => _children;
  List<ChildTaskModel> get eligibleChildren =>
      _children.where((c) => c.isEligible).toList();
  List<TaskItem> get availableTasks => _availableTasks;

  // ── Form fields ──────────────────────────────────────────────────────────
  String _title = '';
  int _stars = 0;
  String? _selectedChildId;
  final Set<String> _selectedTaskIds = <String>{};

  // Image: either freshly picked bytes OR a remote URL kept from the prize.
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _existingImageUrl;
  // True when the user explicitly removed the existing image (edit mode).
  bool _imageRemoved = false;

  String get title => _title;
  int get stars => _stars;
  String? get selectedChildId => _selectedChildId;
  Set<String> get selectedTaskIds => _selectedTaskIds;
  Uint8List? get pickedImageBytes => _pickedImageBytes;
  String? get existingImageUrl => _imageRemoved ? null : _existingImageUrl;
  bool get hasImage =>
      _pickedImageBytes != null ||
      (!_imageRemoved && (_existingImageUrl?.isNotEmpty ?? false));

  ChildTaskModel? get selectedChild {
    if (_selectedChildId == null) return null;
    try {
      return _children.firstWhere((c) => c.childId == _selectedChildId);
    } catch (_) {
      return null;
    }
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  /// Configure for "Add Prize" mode.
  void initAdd() {
    _mode = FormMode.add;
    _editingPrize = null;
    _title = '';
    _stars = 0;
    _selectedChildId = null;
    _selectedTaskIds.clear();
    _pickedImageBytes = null;
    _pickedImageName = null;
    _existingImageUrl = null;
    _imageRemoved = false;
    _availableTasks = const [];
    _error = null;
    notifyListeners();
  }

  /// Configure for "Edit Prize" mode and seed the form from [prize].
  Future<void> initEdit(PrizeDetail prize) async {
    _mode = FormMode.edit;
    _editingPrize = prize;
    _title = prize.title;
    _stars = prize.requiredStars;
    _selectedChildId = prize.childId;
    _selectedTaskIds
      ..clear()
      ..addAll(prize.requiredTasks.map((t) => t.taskId));
    _pickedImageBytes = null;
    _pickedImageName = null;
    _existingImageUrl = prize.imageUrl;
    _imageRemoved = false;
    _error = null;
    notifyListeners();
    await loadChildren();
    await loadChildTasks(prize.childId);
  }

  // ── Children + child tasks ───────────────────────────────────────────────

  Future<void> loadChildren() async {
    _loadingChildren = true;
    _error = null;
    notifyListeners();
    try {
      _children = await _childTaskRepo.fetchChildren();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingChildren = false;
      notifyListeners();
    }
  }

  Future<void> loadChildTasks(String childId) async {
    _loadingTasks = true;
    notifyListeners();
    try {
      final res = await _childTaskRepo.fetchChildTasks(childId);
      // Show pending + completed so existing-prize tasks can be re-checked.
      final all = <TaskItem>[...res.pendingTasks, ...res.completedTasks];
      // Deduplicate by taskId in case both lists overlap.
      final seen = <String>{};
      _availableTasks = [
        for (final t in all)
          if (seen.add(t.taskId)) t
      ];
      // Drop any selected ids that are no longer in the available list
      // (only on add mode — edit keeps prize tasks even if child changes).
      if (_mode == FormMode.add) {
        _selectedTaskIds
            .removeWhere((id) => !_availableTasks.any((t) => t.taskId == id));
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _availableTasks = const [];
    } finally {
      _loadingTasks = false;
      notifyListeners();
    }
  }

  // ── Field setters ────────────────────────────────────────────────────────

  void setTitle(String v) {
    _title = v;
    notifyListeners();
  }

  void incrementStars() {
    _stars++;
    notifyListeners();
  }

  void decrementStars() {
    if (_stars > 0) {
      _stars--;
      notifyListeners();
    }
  }

  void setStars(int v) {
    if (v < 0) v = 0;
    _stars = v;
    notifyListeners();
  }

  Future<void> selectChild(String childId) async {
    if (_selectedChildId == childId) return;
    _selectedChildId = childId;
    _selectedTaskIds.clear();
    notifyListeners();
    await loadChildTasks(childId);
  }

  void toggleTask(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  // ── Image ────────────────────────────────────────────────────────────────

  Future<void> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      try {
        if (bytes.length > 5 * 1024 * 1024) {
          _error = 'حجم الصورة يجب أن يكون أقل من 5 ميغابايت';
          notifyListeners();
          return;
        }
      } catch (_) {
        // size check failed — keep going, server will validate.
      }
      _pickedImageBytes = bytes;
      _pickedImageName =
          picked.name.isNotEmpty ? picked.name : 'prize_image.jpg';
      _imageRemoved = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'تعذر اختيار الصورة. حاول مرة أخرى.';
      notifyListeners();
    }
  }

  void removeImage() {
    _pickedImageBytes = null;
    _pickedImageName = null;
    _imageRemoved = true;
    notifyListeners();
  }

  // ── Validation ───────────────────────────────────────────────────────────

  String? validate() {
    if (_title.trim().isEmpty) return 'يجب إدخال عنوان المكافئة';
    if (_stars <= 0) return 'يجب أن يكون عدد النجوم أكبر من صفر';
    if (_selectedChildId == null || _selectedChildId!.isEmpty) {
      return 'يجب اختيار طفل';
    }
    if (_selectedTaskIds.isEmpty) {
      return 'يجب اختيار مهمة واحدة على الأقل';
    }
    return null;
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<PrizeDetail?> submitCreate() async {
    final v = validate();
    if (v != null) {
      _error = v;
      notifyListeners();
      return null;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('Title', _title.trim()),
        MapEntry('RequiredStars', _stars.toString()),
        MapEntry('ChildId', _selectedChildId!),
      ]);
      for (final id in _selectedTaskIds) {
        form.fields.add(MapEntry('TaskIds', id));
      }
      if (_pickedImageBytes != null) {
        form.files.add(MapEntry(
          'PrizeImage',
          MultipartFile.fromBytes(
            _pickedImageBytes!,
            filename: _pickedImageName ?? 'prize_image.jpg',
          ),
        ));
      }
      final created = await _prizeRepo.createPrize(form);
      return created;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<PrizeDetail?> submitUpdate() async {
    if (_editingPrize == null) {
      _error = 'لا يوجد مكافئة للتحديث';
      notifyListeners();
      return null;
    }
    final v = validate();
    if (v != null) {
      _error = v;
      notifyListeners();
      return null;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('Title', _title.trim()),
        MapEntry('RequiredStars', _stars.toString()),
      ]);
      for (final id in _selectedTaskIds) {
        form.fields.add(MapEntry('TaskIds', id));
      }
      if (_pickedImageBytes != null) {
        form.files.add(MapEntry(
          'PrizeImage',
          MultipartFile.fromBytes(
            _pickedImageBytes!,
            filename: _pickedImageName ?? 'prize_image.jpg',
          ),
        ));
      } else if (_imageRemoved) {
        form.fields.add(const MapEntry('ExistingImageUrl', ''));
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        form.fields.add(MapEntry('ExistingImageUrl', _existingImageUrl!));
      }

      final updated =
          await _prizeRepo.updatePrize(_editingPrize!.prizeId, form);
      return updated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCurrent() async {
    if (_editingPrize == null) return false;
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _prizeRepo.deletePrize(_editingPrize!.prizeId);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
