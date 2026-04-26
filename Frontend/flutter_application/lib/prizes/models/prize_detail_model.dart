// lib/prizes/models/prize_detail_model.dart
//
// Full prize detail including required tasks and child info.
// Returned by POST /api/Prize, GET /api/Prize/{prizeId}, PUT, PATCH deliver,
// and inside data.prizes for GET /api/Prize/parent/{parentId}.

import 'package:Ajial/prizes/models/prize_card_model.dart';
import 'package:Ajial/prizes/models/prize_task_model.dart';

class PrizeDetail extends PrizeCard {
  final String childId;
  final String childFullName;
  final String? childProfileImageUrl;
  final List<PrizeTask> requiredTasks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  const PrizeDetail({
    required super.prizeId,
    required super.title,
    super.imageUrl,
    required super.requiredStars,
    required super.currentStars,
    required super.remainingStars,
    required super.completedTasksCount,
    required super.totalRequiredTasks,
    required super.status,
    required super.canDeliver,
    required this.childId,
    required this.childFullName,
    this.childProfileImageUrl,
    required this.requiredTasks,
    this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  factory PrizeDetail.fromJson(Map<String, dynamic> j) => PrizeDetail(
        prizeId: j['prizeId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        requiredStars: j['requiredStars'] as int? ?? 0,
        currentStars: j['currentStars'] as int? ?? 0,
        remainingStars: j['remainingStars'] as int? ?? 0,
        completedTasksCount: j['completedTasksCount'] as int? ?? 0,
        totalRequiredTasks: j['totalRequiredTasks'] as int? ?? 0,
        status: j['status'] as String? ?? 'Active',
        canDeliver: j['canDeliver'] as bool? ?? false,
        childId: j['childId'] as String? ?? '',
        childFullName: j['childFullName'] as String? ?? '',
        childProfileImageUrl: j['childProfileImageUrl'] as String?,
        requiredTasks: (j['requiredTasks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PrizeTask.fromJson)
            .toList(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String)
            : null,
        deliveredAt: j['deliveredAt'] != null
            ? DateTime.tryParse(j['deliveredAt'] as String)
            : null,
      );
}
