// lib/prizes/models/child_prizes_response_model.dart
//
// Wrapper for: GET /api/Prize/child/{childId}

import 'package:Ajial/prizes/models/prize_card_model.dart';

class ChildPrizesResponse {
  final String childId;
  final String childFullName;
  final int totalStars;
  final List<PrizeCard> prizes;

  const ChildPrizesResponse({
    required this.childId,
    required this.childFullName,
    required this.totalStars,
    required this.prizes,
  });

  factory ChildPrizesResponse.fromJson(Map<String, dynamic> j) =>
      ChildPrizesResponse(
        childId: j['childId'] as String? ?? '',
        childFullName: j['childFullName'] as String? ?? '',
        totalStars: j['totalStars'] as int? ?? 0,
        prizes: (j['prizes'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PrizeCard.fromJson)
            .toList(),
      );
}
