// --- lib/vaccinations/vaccination_welcome_provider.dart ---

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ajial/api/auth_service.dart';

/// VaccinationWelcomeProvider
///
/// Manages the state for the Vaccination Survey Welcome Page.
/// When a [childId] is provided, fetches the child's name and profile image
/// from the Vaccination welcome API. Falls back to route arguments or
/// [SharedPreferences] when no child ID is available.
class VaccinationWelcomeProvider extends ChangeNotifier {
  // ─────────────────────────── Dependencies ──────────────────────────────

  final AuthService _authService = AuthService();

  // ─────────────────────────── State Variables ───────────────────────────

  /// The child's display name shown in the subtitle.
  String _childName = '';

  /// The child's remote profile image URL (may be null if no photo was set).
  String? _childProfileImageUrl;

  /// The child ID used for API calls and forward navigation.
  String? _childId;

  /// True while async data is being loaded.
  bool _isLoading = false;

  // ─────────────────────────── SharedPreferences Keys ────────────────────

  static const String _childNameKey = 'ajial_child_name';
  static const String _childImageKey = 'ajial_child_image_url';

  // ─────────────────────────── Getters ───────────────────────────────────

  String get childName => _childName;
  String? get childProfileImageUrl => _childProfileImageUrl;
  bool get isLoading => _isLoading;

  // ─────────────────────────── Methods ───────────────────────────────────

  /// Loads child data for the vaccination welcome page.
  ///
  /// When [childId] is provided, calls the API
  /// `GET /api/Vaccination/welcome/{childId}` and uses the response's
  /// `fullName` and `profileImageUrl` fields.
  ///
  /// Falls back to [childName] / [childProfileImageUrl] route arguments,
  /// then to [SharedPreferences] if the API call is not made or fails.
  Future<void> loadChildData({
    String? childId,
    String? childName,
    String? childProfileImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Store childId for forward navigation.
      _childId = childId;

      // ── 1. Try fetching from the Vaccination welcome API ──────────────
      if (childId != null && childId.isNotEmpty) {
        final data = await _authService.getVaccinationWelcome(childId);

        if (data != null) {
          _childName = data['fullName']?.toString() ?? '';
          _childProfileImageUrl = data['profileImageUrl']?.toString();
          _isLoading = false;
          notifyListeners();
          return; // API succeeded — done.
        }
        // API failed — fall through to route args / SharedPreferences.
        debugPrint(
            'VaccinationWelcomeProvider: API call failed, falling back.');
      }

      // ── 2. Fallback: route-argument values ────────────────────────────
      if (childName != null && childName.isNotEmpty) {
        _childName = childName;
      } else {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _childName = prefs.getString(_childNameKey) ?? '';
      }

      if (childProfileImageUrl != null) {
        _childProfileImageUrl = childProfileImageUrl;
      } else {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _childProfileImageUrl = prefs.getString(_childImageKey);
      }
    } catch (e) {
      debugPrint('VaccinationWelcomeProvider.loadChildData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called when the parent taps "بدء تسجيل التطعيمات".
  ///
  /// Navigates forward to the vaccination survey checklist page.
  void onStartVaccinations(BuildContext context) {
    if (_isLoading) return;

    Navigator.pushNamed(context, '/vaccination-survey', arguments: {
      'childId': _childId,
      'childName': _childName,
    });
  }

  /// Called when the parent taps "رجوع" (back / skip).
  void onSkip(BuildContext context) {
    if (_isLoading) return;
    Navigator.pop(context);
  }

  /// Resets provider back to its initial state.
  /// Useful when the user leaves and returns to this flow.
  void reset() {
    _childName = '';
    _childProfileImageUrl = null;
    _childId = null;
    _isLoading = false;
    notifyListeners();
  }
}
