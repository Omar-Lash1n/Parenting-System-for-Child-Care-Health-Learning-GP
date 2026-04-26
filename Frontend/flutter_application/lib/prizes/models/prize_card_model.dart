// lib/prizes/models/prize_card_model.dart
//
// Light-weight prize card returned by GET /api/Prize/child/{childId}.

class PrizeCard {
  final String prizeId;
  final String title;
  final String? imageUrl;
  final int requiredStars;
  final int currentStars;
  final int remainingStars;
  final int completedTasksCount;
  final int totalRequiredTasks;
  final String status;
  final bool canDeliver;

  const PrizeCard({
    required this.prizeId,
    required this.title,
    this.imageUrl,
    required this.requiredStars,
    required this.currentStars,
    required this.remainingStars,
    required this.completedTasksCount,
    required this.totalRequiredTasks,
    required this.status,
    required this.canDeliver,
  });

  factory PrizeCard.fromJson(Map<String, dynamic> j) => PrizeCard(
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
      );

  bool get isActive => status == 'Active';
  bool get isReady => status == 'Ready';
  bool get isDelivered => status == 'Delivered';

  int get progressPercent {
    if (totalRequiredTasks == 0) return 0;
    return ((completedTasksCount / totalRequiredTasks) * 100).round();
  }
}
