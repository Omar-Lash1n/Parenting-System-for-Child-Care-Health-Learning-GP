// --- lib/tasks/models/task_model.dart ---

import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final String category;
  final String? categoryId;
  final List<Assignee> assignees;
  final Color color;
  final DateTime? date;
  final TimeOfDay? time;
  final DateTime createdAt;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    this.categoryId,
    required this.assignees,
    required this.color,
    this.date,
    this.time,
    DateTime? createdAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isForChild => assignees.any((a) => !a.isSelf);
  bool get isForSelf => assignees.isEmpty || assignees.any((a) => a.isSelf);

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    String? categoryId,
    List<Assignee>? assignees,
    Color? color,
    DateTime? date,
    TimeOfDay? time,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      assignees: assignees ?? this.assignees,
      color: color ?? this.color,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFFBF092F); // Default red fallback
    if (json['color'] != null) {
      String hex = json['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      try {
        parsedColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    DateTime? parsedDate;
    TimeOfDay? parsedTime;
    if (json['dueDate'] != null) {
      try {
        final dt = DateTime.parse(json['dueDate'].toString());
        parsedDate = dt;
        parsedTime = TimeOfDay.fromDateTime(dt);
      } catch (_) {}
    }

    String catName = 'الكل';
    String? catId;
    if (json['category'] != null && json['category'] is Map) {
      catName = json['category']['name']?.toString() ?? 'الكل';
      catId = json['category']['id']?.toString();
    }

    List<Assignee> parsedAssignees = [];
    if (json['assignees'] != null && json['assignees'] is List) {
      parsedAssignees = (json['assignees'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => Assignee.fromJson(a))
          .toList();
    }

    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: catName,
      categoryId: catId,
      assignees: parsedAssignees,
      color: parsedColor,
      date: parsedDate,
      time: parsedTime,
      isCompleted: json['isCompleted'] == true,
      createdAt: parsedDate ?? DateTime.now(), // Fallback if no creation date is sent
    );
  }
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

  factory Assignee.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase();
    return Assignee(
      id: json['id']?.toString() ?? '',
      name: json['fullName']?.toString() ?? '',
      imageUrl: json['profileImageUrl']?.toString(),
      isSelf: type == 'parent',
    );
  }
}

/// Time-based groupings for the task list.
enum TaskGroup {
  past,
  yesterday,
  today,
  tomorrow,
  future,
  completed,
}

extension TaskGroupLabels on TaskGroup {
  String get label {
    switch (this) {
      case TaskGroup.past:
        return 'الفترة السابقة';
      case TaskGroup.yesterday:
        return 'امس';
      case TaskGroup.today:
        return 'اليوم';
      case TaskGroup.tomorrow:
        return 'غدا';
      case TaskGroup.future:
        return 'الفترة القادمة';
      case TaskGroup.completed:
        return 'تم انجازها';
    }
  }
}
