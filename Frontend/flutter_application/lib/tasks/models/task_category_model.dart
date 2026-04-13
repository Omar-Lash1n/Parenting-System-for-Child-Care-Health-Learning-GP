// lib/tasks/models/task_category_model.dart
//
// Represents a single task category as returned by the API endpoint
// GET /TaskCategory/parent/{parentId}

class TaskCategoryModel {
  final String id;
  final String name;
  final bool isSystem;
  final int taskCount;

  const TaskCategoryModel({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.taskCount,
  });

  factory TaskCategoryModel.fromJson(Map<String, dynamic> json) {
    return TaskCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isSystem: json['isSystem'] as bool? ?? false,
      taskCount: json['taskCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isSystem': isSystem,
        'taskCount': taskCount,
      };

  @override
  String toString() =>
      'TaskCategoryModel(id: $id, name: $name, isSystem: $isSystem, count: $taskCount)';
}
