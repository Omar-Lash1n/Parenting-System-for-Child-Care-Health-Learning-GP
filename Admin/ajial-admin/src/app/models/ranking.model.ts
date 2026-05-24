export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  errors: string[] | null;
}

export interface AdminCurrentRankingEntry {
  parentId: string;
  fullName: string;
  profileImageUrl: string | null;
  childrenCount: number;
  stars: number;
  rank: number;
  projectedBadge: 'Gold' | 'Silver' | 'Bronze' | null;
}

export interface AdminCurrentRanking {
  totalParents: number;
  generatedAt: string;
  entries: AdminCurrentRankingEntry[];
}

export interface PagedAdminCurrentRanking extends AdminCurrentRanking {
  page: number;
  pageSize: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface RankingEntry {
  parentId: string;
  fullName: string;
  profileImageUrl: string | null;
  childrenCount: number;
  stars: number;
  rank: number;
  badge: 'Gold' | 'Silver' | 'Bronze' | null;
}

export interface PublishedRanking {
  cycleId: string;
  seasonName: string;
  publishedAt: string;
  nextPublishAt: string;
  entries: RankingEntry[];
}

export interface PublishRankingRequest {
  seasonName: string;
  nextPublishAt: string;
}

export interface AdminPublishedRanking {
  cycleId: string;
  seasonName: string;
  publishedAt: string;
  nextPublishAt: string;
  totalParents: number;
  topThree: RankingEntry[];
}
