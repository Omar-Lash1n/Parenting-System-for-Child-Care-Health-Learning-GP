// lib/prizes/models/parent_prizes_response_model.dart
//
// Wrapper for: GET /api/Prize/parent/{parentId}
// The backend returns a flat list — we group it by childId on the frontend.

import 'package:Ajial/prizes/models/prize_detail_model.dart';

class ParentPrizesResponse {
  final String parentId;
  final int totalPrizes;
  final List<PrizeDetail> prizes;

  const ParentPrizesResponse({
    required this.parentId,
    required this.totalPrizes,
    required this.prizes,
  });

  factory ParentPrizesResponse.fromJson(Map<String, dynamic> j) =>
      ParentPrizesResponse(
        parentId: j['parentId'] as String? ?? '',
        totalPrizes: j['totalPrizes'] as int? ?? 0,
        prizes: (j['prizes'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PrizeDetail.fromJson)
            .toList(),
      );

  /// Groups prizes by childId (preserves first-seen order).
  Map<String, List<PrizeDetail>> get prizesByChild {
    final map = <String, List<PrizeDetail>>{};
    for (final p in prizes) {
      map.putIfAbsent(p.childId, () => []).add(p);
    }
    return map;
  }
}
