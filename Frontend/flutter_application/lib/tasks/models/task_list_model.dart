// lib/tasks/models/task_list_model.dart
//
// Models for:
//   GET /api/ChildTask/parent/{parentId}/summary
//   GET /api/ChildTask/child/{childId}
//   GET /api/ChildTask/{taskId}/child/{childId}

// ─── Summary (parent-level) ───────────────────────────────────────────────────

class ParentTaskSummary {
  final int totalChildTasks;
  final int totalPendingTasks;
  final int totalCompletedTasks;
  final int completedToday;
  final List<ChildSummary> perChild;

  const ParentTaskSummary({
    required this.totalChildTasks,
    required this.totalPendingTasks,
    required this.totalCompletedTasks,
    required this.completedToday,
    required this.perChild,
  });

  factory ParentTaskSummary.fromJson(Map<String, dynamic> j) =>
      ParentTaskSummary(
        totalChildTasks: j['totalChildTasks'] as int? ?? 0,
        totalPendingTasks: j['totalPendingTasks'] as int? ?? 0,
        totalCompletedTasks: j['totalCompletedTasks'] as int? ?? 0,
        completedToday: j['completedToday'] as int? ?? 0,
        perChild: (j['perChild'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChildSummary.fromJson)
            .toList(),
      );
}

class ChildSummary {
  final String childId;
  final String fullName;
  final String? profileImageUrl;
  final int totalStars;
  final int pendingTasksCount;
  final int completedTasksCount;

  const ChildSummary({
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
    required this.totalStars,
    required this.pendingTasksCount,
    required this.completedTasksCount,
  });

  factory ChildSummary.fromJson(Map<String, dynamic> j) => ChildSummary(
        childId: j['childId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        profileImageUrl: j['profileImageUrl'] as String?,
        totalStars: j['totalStars'] as int? ?? 0,
        pendingTasksCount: j['pendingTasksCount'] as int? ?? 0,
        completedTasksCount: j['completedTasksCount'] as int? ?? 0,
      );
}

// ─── Task item (used in list + mini-previews) ─────────────────────────────────

class TaskItem {
  final String taskId;
  final String title;
  final String? taskImageUrl;
  final String? recordingUrl;
  final int stars;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String? recurrenceSummary;
  final List<AssignedChild> assignedChildren;

  const TaskItem({
    required this.taskId,
    required this.title,
    this.taskImageUrl,
    this.recordingUrl,
    required this.stars,
    required this.isCompleted,
    this.completedAt,
    this.dueDate,
    this.recurrenceSummary,
    required this.assignedChildren,
  });

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        taskId: j['taskId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        taskImageUrl: j['taskImageUrl'] as String?,
        recordingUrl: j['recordingUrl'] as String?,
        stars: j['stars'] as int? ?? 0,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
        dueDate: j['dueDate'] != null
            ? DateTime.tryParse(j['dueDate'] as String)
            : null,
        recurrenceSummary: j['recurrenceSummary'] as String?,
        assignedChildren: (j['assignedChildren'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AssignedChild.fromJson)
            .toList(),
      );

  TaskItem copyWith({bool? isCompleted}) => TaskItem(
        taskId: taskId,
        title: title,
        taskImageUrl: taskImageUrl,
        recordingUrl: recordingUrl,
        stars: stars,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt,
        dueDate: dueDate,
        recurrenceSummary: recurrenceSummary,
        assignedChildren: assignedChildren,
      );
}

class AssignedChild {
  final String childId;
  final String fullName;
  final String? profileImageUrl;
  final bool isCompleted;
  final DateTime? completedAt;

  const AssignedChild({
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
    required this.isCompleted,
    this.completedAt,
  });

  factory AssignedChild.fromJson(Map<String, dynamic> j) => AssignedChild(
        childId: j['childId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        profileImageUrl: j['profileImageUrl'] as String?,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
      );
}

// ─── Child tasks response (for full list page) ────────────────────────────────

class ChildTasksResponse {
  final ChildTasksChildInfo child;
  final int totalStars;
  final List<TaskItem> pendingTasks;
  final List<TaskItem> completedTasks;

  const ChildTasksResponse({
    required this.child,
    required this.totalStars,
    required this.pendingTasks,
    required this.completedTasks,
  });

  factory ChildTasksResponse.fromJson(Map<String, dynamic> j) =>
      ChildTasksResponse(
        child: ChildTasksChildInfo.fromJson(
            j['child'] as Map<String, dynamic>? ?? {}),
        totalStars: j['totalStars'] as int? ?? 0,
        pendingTasks: (j['pendingTasks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TaskItem.fromJson)
            .toList(),
        completedTasks: (j['completedTasks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TaskItem.fromJson)
            .toList(),
      );
}

class ChildTasksChildInfo {
  final String childId;
  final String fullName;
  final String? profileImageUrl;

  const ChildTasksChildInfo({
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
  });

  factory ChildTasksChildInfo.fromJson(Map<String, dynamic> j) =>
      ChildTasksChildInfo(
        childId: j['childId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        profileImageUrl: j['profileImageUrl'] as String?,
      );
}

// ─── Task detail (for detail page) ───────────────────────────────────────────

class TaskDetail {
  final String taskId;
  final String title;
  final String? taskImageUrl;
  final String? recordingUrl;
  final int stars;
  final DateTime? startDate;
  final DateTime? dueDate;
  final TaskRecurrence? recurrence;
  final List<AssignedChild> assignedChildren;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskDetail({
    required this.taskId,
    required this.title,
    this.taskImageUrl,
    this.recordingUrl,
    required this.stars,
    this.startDate,
    this.dueDate,
    this.recurrence,
    required this.assignedChildren,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> j) => TaskDetail(
        taskId: j['taskId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        taskImageUrl: j['taskImageUrl'] as String?,
        recordingUrl: j['recordingUrl'] as String?,
        stars: j['stars'] as int? ?? 0,
        startDate: j['startDate'] != null
            ? DateTime.tryParse(j['startDate'] as String)
            : null,
        dueDate: j['dueDate'] != null
            ? DateTime.tryParse(j['dueDate'] as String)
            : null,
        recurrence: j['recurrence'] != null
            ? TaskRecurrence.fromJson(j['recurrence'] as Map<String, dynamic>)
            : null,
        assignedChildren: (j['assignedChildren'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AssignedChild.fromJson)
            .toList(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String)
            : null,
      );
}

class TaskRecurrence {
  final bool isRecurring;
  final List<String> repeatDays;
  final String? repeatTime;

  const TaskRecurrence({
    required this.isRecurring,
    required this.repeatDays,
    this.repeatTime,
  });

  factory TaskRecurrence.fromJson(Map<String, dynamic> j) => TaskRecurrence(
        isRecurring: j['isRecurring'] as bool? ?? false,
        repeatDays: (j['repeatDays'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        repeatTime: j['repeatTime'] as String?,
      );

  /// Arabic short labels for day names returned by the API.
  String get arabicDays {
    const map = {
      'saturday': 'س',
      'sunday': 'ح',
      'monday': 'إ',
      'tuesday': 'ث',
      'wednesday': 'أ',
      'thursday': 'خ',
      'friday': 'ج',
    };
    return repeatDays.map((d) => map[d.toLowerCase()] ?? d).join('، ');
  }
}
