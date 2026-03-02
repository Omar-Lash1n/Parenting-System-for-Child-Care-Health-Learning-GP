// lib/providers/family_provider.dart
//
// ChangeNotifier that drives the Family (Children List) page.
// Responsible for fetching children data from the API and exposing
// state (loading / loaded / error / empty) to the UI.

import 'package:flutter/material.dart';
import 'package:Ajial/family/models/child_model.dart';
import 'package:Ajial/family/repositories/parent_repository.dart';
import 'package:Ajial/family/repositories/auth_repository.dart';

/// Possible states for the Family page.
enum FamilyStatus {
  initial, // Before any fetch
  loading, // Fetch in progress
  loaded, // Fetch succeeded (may have 0 or more children)
  error, // Fetch failed
}

/// [FamilyProvider] — State management for the "My Family" children list page.
///
/// Usage in `main.dart`:
/// ```dart
/// ChangeNotifierProvider(create: (_) => FamilyProvider()),
/// ```
///
/// Usage in the widget tree:
/// ```dart
/// Consumer<FamilyProvider>(
///   builder: (context, provider, _) { ... },
/// )
/// ```
class FamilyProvider extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────────────────────
  final ParentRepository _parentRepo;
  final AuthRepository _authRepo;

  FamilyProvider({
    ParentRepository? parentRepository,
    AuthRepository? authRepository,
  })  : _parentRepo = parentRepository ?? ParentRepository(),
        _authRepo = authRepository ?? AuthRepository();

  // ── State ─────────────────────────────────────────────────────────────────
  FamilyStatus _status = FamilyStatus.initial;
  List<ChildModel> _children = [];
  String? _errorMessage;
  bool _isLogoutLoading = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  FamilyStatus get status => _status;
  List<ChildModel> get children => List.unmodifiable(_children);
  String? get errorMessage => _errorMessage;
  bool get isLogoutLoading => _isLogoutLoading;
  bool get isLoading => _status == FamilyStatus.loading;
  bool get hasChildren => _children.isNotEmpty;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Fetches the children list from the API.
  ///
  /// Updates [status] to [FamilyStatus.loading] while in progress,
  /// then either [FamilyStatus.loaded] or [FamilyStatus.error].
  Future<void> loadChildren() async {
    _status = FamilyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _parentRepo.fetchChildren();
      _children = fetched;
      _status = FamilyStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = FamilyStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Removes a child from the local list by [childId].
  ///
  /// This is a **local-only** operation — it does not call a delete API
  /// (no delete endpoint was specified). If a delete endpoint is added
  /// in the future, call it here before mutating [_children].
  void removeChild(String childId) {
    _children = _children.where((c) => c.childId != childId).toList();
    notifyListeners();
  }

  /// Logs out the currently active child session.
  ///
  /// - Calls `POST /Auth/logout/child` via [AuthRepository].
  /// - Clears local child tokens regardless of API result.
  /// - Returns `true` on success.
  /// - On failure, sets [errorMessage] and returns `false`.
  Future<bool> logoutChild(BuildContext context) async {
    _isLogoutLoading = true;
    notifyListeners();

    try {
      final success = await _authRepo.logoutChild();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLogoutLoading = false;
      notifyListeners();
    }
  }

  /// Resets provider to initial state. Call when the user navigates away.
  void reset() {
    _status = FamilyStatus.initial;
    _children = [];
    _errorMessage = null;
    _isLogoutLoading = false;
    notifyListeners();
  }
}
