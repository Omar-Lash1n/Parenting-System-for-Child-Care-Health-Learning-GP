// lib/prizes/models/prize_task_model.dart
//
// Required-task entry inside a prize detail.

class PrizeTask {
  final String taskId;
  final String title;
  final String? taskImageUrl;
  final int stars;
  final bool isCompleted;
  final DateTime? completedAt;

  const PrizeTask({
    required this.taskId,
    required this.title,
    this.taskImageUrl,
    required this.stars,
    required this.isCompleted,
    this.completedAt,
  });

  factory PrizeTask.fromJson(Map<String, dynamic> j) => PrizeTask(
        taskId: j['taskId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        taskImageUrl: j['taskImageUrl'] as String?,
        stars: j['stars'] as int? ?? 0,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
      );
}
