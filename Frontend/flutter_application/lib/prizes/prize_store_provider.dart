// lib/prizes/prize_store_provider.dart
//
// State for the prize store list page.

import 'package:flutter/foundation.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';
import 'package:Ajial/prizes/repositories/prize_repository.dart';

enum PrizeStoreStatus { initial, loading, loaded, error }

class PrizeStoreProvider extends ChangeNotifier {
  final PrizeRepository _repo;

  PrizeStoreProvider({PrizeRepository? repo})
      : _repo = repo ?? PrizeRepository();

  PrizeStoreStatus _status = PrizeStoreStatus.initial;
  String? _error;
  List<PrizeDetail> _prizes = const [];

  // Per-prize busy flags so only the affected card spins.
  final Set<String> _deliveringIds = {};
  final Set<String> _deletingIds = {};

  PrizeStoreStatus get status => _status;
  String? get error => _error;
  List<PrizeDetail> get prizes => _prizes;

  bool get isLoading => _status == PrizeStoreStatus.loading;
  bool get hasError => _status == PrizeStoreStatus.error;
  bool get isEmpty =>
      _status == PrizeStoreStatus.loaded && _prizes.isEmpty;

  bool isDelivering(String prizeId) => _deliveringIds.contains(prizeId);
  bool isDeleting(String prizeId) => _deletingIds.contains(prizeId);

  /// Returns prizes grouped by childId in first-seen order.
  Map<String, List<PrizeDetail>> get prizesByChild {
    final map = <String, List<PrizeDetail>>{};
    for (final p in _prizes) {
      map.putIfAbsent(p.childId, () => []).add(p);
    }
    return map;
  }

  Future<void> loadPrizes() async {
    if (_status != PrizeStoreStatus.loaded) {
      _status = PrizeStoreStatus.loading;
    }
    _error = null;
    notifyListeners();

    try {
      final res = await _repo.fetchParentPrizes();
      _prizes = res.prizes;
      _status = PrizeStoreStatus.loaded;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = PrizeStoreStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => loadPrizes();

  /// Returns the updated detail on success. Throws on failure (caller shows
  /// the appropriate error modal).
  Future<PrizeDetail> deliverPrize(String prizeId) async {
    _deliveringIds.add(prizeId);
    notifyListeners();
    try {
      final updated = await _repo.deliverPrize(prizeId);
      final idx = _prizes.indexWhere((p) => p.prizeId == prizeId);
      if (idx != -1) {
        final next = [..._prizes];
        next[idx] = updated;
        _prizes = next;
      }
      return updated;
    } finally {
      _deliveringIds.remove(prizeId);
      notifyListeners();
    }
  }

  Future<void> deletePrize(String prizeId) async {
    _deletingIds.add(prizeId);
    notifyListeners();
    try {
      await _repo.deletePrize(prizeId);
      _prizes = _prizes.where((p) => p.prizeId != prizeId).toList();
    } finally {
      _deletingIds.remove(prizeId);
      notifyListeners();
    }
  }

  /// Replace a single prize in the local list (e.g. after edit).
  void replacePrize(PrizeDetail updated) {
    final idx = _prizes.indexWhere((p) => p.prizeId == updated.prizeId);
    if (idx == -1) {
      _prizes = [updated, ..._prizes];
    } else {
      final next = [..._prizes];
      next[idx] = updated;
      _prizes = next;
    }
    notifyListeners();
  }
}
