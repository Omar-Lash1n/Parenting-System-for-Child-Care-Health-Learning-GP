// --- lib/vaccinations/additional_vaccination_provider.dart ---

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/vaccinations/models/vaccination_group_model.dart';
import 'package:Ajial/vaccinations/vaccination_survey_provider.dart';
import 'package:Ajial/vaccinations/widgets/cancel_survey_dialog.dart';
import 'package:Ajial/vaccinations/widgets/confirm_survey_dialog.dart';

/// AdditionalVaccinationProvider
///
/// Manages all state for the Additional Vaccination Survey page.
///
/// Fetches school-age milestones from the API
/// (`GET /api/Vaccination/additional-survey/{childId}`).
/// Each milestone carries [isDisabled] and [isTaken] flags:
///
/// - **isTaken = true** → group is pre-selected.
/// - **isDisabled = true** → group cannot be toggled (future milestone).
///
/// Selection is independent — each vaccine can be toggled individually.
/// Falls back to hardcoded data when no childId or API fails.
class AdditionalVaccinationProvider extends ChangeNotifier {
  // ──────────────────────── Dependencies ─────────────────────────────────────

  final AuthService _authService = AuthService();

  // ──────────────────────── State Variables ──────────────────────────────────

  /// The ordered list of additional vaccination groups.
  List<VaccinationGroupModel> _groups = [];

  /// IDs of groups the parent has confirmed as received.
  final Set<String> _selectedGroupIds = {};

  /// Child's name shown in the page header.
  String _childName = '';

  /// The child ID used for API calls.
  String? _childId;

  /// Milestone selections from the basic survey page (passed via route args).
  List<Map<String, dynamic>> _milestoneSelections = [];

  /// True while async data is loading.
  bool _isLoading = false;

  // ──────────────────────── SharedPreferences Key ────────────────────────────

  static const String _childNameKey = 'ajial_child_name';

  // ──────────────────────── Getters ──────────────────────────────────────────

  List<VaccinationGroupModel> get groups => List.unmodifiable(_groups);
  String get childName => _childName;
  bool get isLoading => _isLoading;

  // ──────────────────────── Derived State ────────────────────────────────────

  /// Computes the [GroupCardState] for the group at [index].
  ///
  /// - **selected** : in the selected set.
  /// - **disabled** : `isDisabled` is true (future milestone from API).
  /// - **enabled**  : ready to tap.
  GroupCardState getGroupState(int index) {
    final group = _groups[index];

    if (_selectedGroupIds.contains(group.id)) {
      return GroupCardState.selected;
    }

    if (group.isDisabled) {
      return GroupCardState.disabled;
    }

    return GroupCardState.enabled;
  }

  // ──────────────────────── Methods ──────────────────────────────────────────

  /// Loads additional vaccination groups from the API.
  ///
  /// When [childId] is provided, calls
  /// `GET /api/Vaccination/additional-survey/{childId}`.
  /// Falls back to hardcoded [VaccinationGroupModel.additionalGroups()].
  Future<void> loadData({
    String? childName,
    String? childId,
    List<Map<String, dynamic>>? milestoneSelections,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _childId = childId;
      _milestoneSelections = milestoneSelections ?? [];

      // ── 1. Try fetching from the additional survey API ─────────────────
      if (childId != null && childId.isNotEmpty) {
        final data = await _authService.getAdditionalSurvey(childId);

        if (data != null) {
          _childName = data['childName']?.toString() ?? '';

          final List<dynamic> milestones = data['milestones'] ?? [];
          _groups = milestones
              .map((m) =>
                  VaccinationGroupModel.fromJson(m as Map<String, dynamic>))
              .toList();

          // Auto-select milestones where isTaken == true.
          _selectedGroupIds.clear();
          for (final group in _groups) {
            if (group.isTaken) {
              _selectedGroupIds.add(group.id);
            }
          }

          _isLoading = false;
          notifyListeners();
          return; // API succeeded.
        }
        debugPrint(
            'AdditionalVaccinationProvider: API call failed, falling back.');
      }

      // ── 2. Fallback: hardcoded data ────────────────────────────────────
      _groups = VaccinationGroupModel.additionalGroups();

      if (childName != null && childName.isNotEmpty) {
        _childName = childName;
      } else {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _childName = prefs.getString(_childNameKey) ?? '';
      }
    } catch (e) {
      debugPrint('AdditionalVaccinationProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the selected state of the group identified by [id].
  ///
  /// Each additional vaccine is independent — no cascading.
  /// Disabled groups (future milestones) cannot be toggled.
  void toggleGroup(String id) {
    // Find the group and prevent toggling disabled ones.
    final idx = _groups.indexWhere((g) => g.id == id);
    if (idx == -1) return;
    if (_groups[idx].isDisabled) return;

    if (_selectedGroupIds.contains(id)) {
      _selectedGroupIds.remove(id);
    } else {
      _selectedGroupIds.add(id);
    }
    notifyListeners();
  }

  /// Called when the parent taps "التالي" (Next / Confirm).
  ///
  /// Shows the confirmation dialog. If confirmed, submits both the basic
  /// survey selections AND the additional survey selections, then
  /// navigates to the success page.
  Future<void> onConfirm(BuildContext context) async {
    if (_isLoading) return;

    // Build additional milestone selections.
    final List<Map<String, dynamic>> additionalSelections = _groups.map((g) {
      return {
        'milestoneId': int.tryParse(g.id) ?? g.id,
        'isTaken': _selectedGroupIds.contains(g.id),
      };
    }).toList();

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Additional Survey — Selections:');
    for (final s in additionalSelections) {
      debugPrint('  $s');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    final confirmed = await showConfirmSurveyDialog(context);
    if (confirmed && context.mounted) {
      if (_childId != null) {
        // Submit basic survey selections.
        await _authService.submitVaccinationSurvey(
          childId: _childId!,
          selections: _milestoneSelections,
        );
        // Submit additional survey selections.
        await _authService.submitAdditionalSurvey(
          childId: _childId!,
          selections: additionalSelections,
        );
      }
      if (context.mounted) {
        Navigator.pushNamed(context, '/vaccination-success');
      }
    }
  }

  /// Called when the parent taps "الغاء" (Cancel / Skip).
  Future<void> onCancel(BuildContext context) async {
    if (_isLoading) return;
    final confirmed = await showCancelSurveyDialog(context);
    if (confirmed && context.mounted) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == '/profile');
    }
  }

  /// Called when the parent taps the close (×) button.
  Future<void> onClose(BuildContext context) async {
    if (_isLoading) return;
    final confirmed = await showCancelSurveyDialog(context);
    if (confirmed && context.mounted) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == '/profile');
    }
  }

  /// Resets all state back to initial values.
  void reset() {
    _groups = [];
    _selectedGroupIds.clear();
    _childName = '';
    _childId = null;
    _milestoneSelections = [];
    _isLoading = false;
    notifyListeners();
  }
}
