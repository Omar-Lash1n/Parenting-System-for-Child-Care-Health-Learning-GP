import 'package:flutter/material.dart';

class UpcomingTaskModel {
  final String id;
  final String title;
  final Color color;
  final DateTime? dueDate;
  final bool isCompleted;
  final List<HomeTaskAssigneeModel> assignees;

  const UpcomingTaskModel({
    required this.id,
    required this.title,
    required this.color,
    this.dueDate,
    this.isCompleted = false,
    this.assignees = const [],
  });

  factory UpcomingTaskModel.fromJson(Map<String, dynamic> json) {
    final rawAssignees = json['assignees'] ?? json['assignedTo'] ?? json['children'];
    final assignees = rawAssignees is List
        ? rawAssignees
            .whereType<Map>()
            .map((item) => HomeTaskAssigneeModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <HomeTaskAssigneeModel>[];

    return UpcomingTaskModel(
      id: _readString(json, const ['id', 'taskId']),
      title: _readString(json, const ['title', 'name'], fallback: 'مهمة'),
      color: _parseColor(_readString(json, const ['color', 'colorHex'])),
      dueDate: _readDate(json, const ['dueDate', 'date', 'scheduledAt']),
      isCompleted: json['isCompleted'] == true || json['completed'] == true,
      assignees: assignees,
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {}
    }
    return null;
  }

  static Color _parseColor(String value) {
    var hex = value.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }
    return const Color(0xFFBF092F);
  }
}

class HomeTaskAssigneeModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isParent;

  const HomeTaskAssigneeModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isParent = false,
  });

  factory HomeTaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase();
    return HomeTaskAssigneeModel(
      id: (json['id'] ?? json['childId'] ?? json['parentId'] ?? '').toString(),
      name: (json['fullName'] ?? json['name'] ?? '').toString(),
      imageUrl: (json['profileImageUrl'] ?? json['photoUrl'] ?? json['imageUrl'])
          ?.toString(),
      isParent: type == 'parent' || json['isParent'] == true,
    );
  }
}
