class RankingEntry {
  final String parentId;
  final String fullName;
  final String? profileImageUrl;
  final int childrenCount;
  final int stars;
  final int rank;
  final String? badge;

  RankingEntry({
    required this.parentId,
    required this.fullName,
    this.profileImageUrl,
    required this.childrenCount,
    required this.stars,
    required this.rank,
    this.badge,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      parentId: json['parentId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      childrenCount: (json['childrenCount'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      badge: json['badge'] as String?,
    );
  }
}

/// Paginated wrapper returned by GET /api/ranking?page=&pageSize=
class PagedRanking {
  final String cycleId;
  final String seasonName;
  final DateTime publishedAt;
  final DateTime nextPublishAt;
  final List<RankingEntry> entries;
  final int totalEntries;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PagedRanking({
    required this.cycleId,
    required this.seasonName,
    required this.publishedAt,
    required this.nextPublishAt,
    required this.entries,
    required this.totalEntries,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedRanking.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'] as List<dynamic>? ?? [];
    return PagedRanking(
      cycleId: json['cycleId']?.toString() ?? '',
      seasonName: json['seasonName']?.toString() ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      nextPublishAt: DateTime.tryParse(json['nextPublishAt']?.toString() ?? '') ?? DateTime.now(),
      entries: entriesRaw
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}

class ParentBadge {
  final String cycleId;
  final String seasonName;
  final String badge;
  final int rank;
  final int stars;
  final DateTime awardedAt;

  ParentBadge({
    required this.cycleId,
    required this.seasonName,
    required this.badge,
    required this.rank,
    required this.stars,
    required this.awardedAt,
  });

  factory ParentBadge.fromJson(Map<String, dynamic> json) {
    return ParentBadge(
      cycleId: json['cycleId']?.toString() ?? '',
      seasonName: json['seasonName']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      awardedAt: DateTime.tryParse(json['awardedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
