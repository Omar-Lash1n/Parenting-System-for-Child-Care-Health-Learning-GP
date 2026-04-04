// --- lib/tasks/models/task_model.dart ---

import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final String category;
  final List<Assignee> assignees; // ← now a list
  final Color color;
  final DateTime? date;  // nullable — not required
  final TimeOfDay? time; // nullable
  final DateTime createdAt;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.assignees,
    required this.color,
    this.date,
    this.time,
    DateTime? createdAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isForChild => assignees.any((a) => !a.isSelf);
  bool get isForSelf  => assignees.isEmpty || assignees.any((a) => a.isSelf);
}

/// Represents an assignee option (self or a child).
class Assignee {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isSelf;

  const Assignee({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isSelf = false,
  });
}

/// Time-based groupings for the task list.
enum TaskGroup {
  past,       // الفترة السابقة
  yesterday,  // امس
  today,      // اليوم
  tomorrow,   // غدا
  future,     // الفترة القادمة
  completed,  // تم انجازها
}

extension TaskGroupLabels on TaskGroup {
  String get label {
    switch (this) {
      case TaskGroup.past:      return 'الفترة السابقة';
      case TaskGroup.yesterday: return 'امس';
      case TaskGroup.today:     return 'اليوم';
      case TaskGroup.tomorrow:  return 'غدا';
      case TaskGroup.future:    return 'الفترة القادمة';
      case TaskGroup.completed: return 'تم انجازها';
    }
  }
}
