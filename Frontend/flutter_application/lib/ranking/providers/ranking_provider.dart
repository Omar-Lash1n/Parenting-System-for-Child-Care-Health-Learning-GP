import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/ranking/models/ranking_models.dart';
import 'package:Ajial/ranking/repositories/ranking_repository.dart';

class RankingProvider extends ChangeNotifier {
  final _repo = RankingRepository();

  // Cycle metadata (from the last fetched page)
  PagedRanking? _pagedRanking;

  // Accumulated entries across all loaded pages
  List<RankingEntry> entries = [];

  // Badges
  List<ParentBadge> myBadges = [];

  // State flags
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isBadgesLoading = false;
  String? error;
  String? currentParentId;

  // Pagination state
  int _currentPage = 0;
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  PagedRanking? get pagedRanking => _pagedRanking;

  // Countdown
  Duration? _countdownRemaining;
  Timer? _timer;
  Duration? get countdownRemaining => _countdownRemaining;

  /// Initial load — resets everything and fetches page 1.
  Future<void> loadRanking() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    entries = [];
    _currentPage = 0;
    _hasMore = true;
    _timer?.cancel();
    notifyListeners();

    try {
      final result = await _repo.fetchPublishedRanking(page: 1, pageSize: 20);
      _pagedRanking = result;
      entries = List.of(result.entries);
      _currentPage = 1;
      _hasMore = result.hasNextPage;
      currentParentId = await AuthService().getSavedParentId();
      _startCountdown();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page — called by infinite scroll.
  Future<void> loadMoreRanking() async {
    if (!_hasMore || isLoadingMore || isLoading) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repo.fetchPublishedRanking(
        page: _currentPage + 1,
        pageSize: 20,
      );
      _pagedRanking = result;
      entries.addAll(result.entries);
      _currentPage = result.page;
      _hasMore = result.hasNextPage;
    } catch (_) {
      // silently ignore — user can scroll up and retry
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMyBadges() async {
    isBadgesLoading = true;
    notifyListeners();
    try {
      myBadges = await _repo.fetchMyBadges();
    } catch (_) {
      myBadges = [];
    } finally {
      isBadgesLoading = false;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_pagedRanking == null) return;
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    if (_pagedRanking == null) return;
    final remaining = _pagedRanking!.nextPublishAt.difference(DateTime.now());
    _countdownRemaining = remaining.isNegative ? Duration.zero : remaining;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
