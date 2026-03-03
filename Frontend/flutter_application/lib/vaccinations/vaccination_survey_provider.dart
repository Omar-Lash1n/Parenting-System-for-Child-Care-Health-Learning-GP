// --- lib/vaccinations/vaccination_survey_provider.dart ---

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/vaccinations/models/vaccination_group_model.dart';
import 'package:Ajial/vaccinations/widgets/cancel_survey_dialog.dart';
import 'package:Ajial/vaccinations/widgets/confirm_survey_dialog.dart';

// ─────────────────────────── Enums ───────────────────────────────────────────

/// The visual and interactive state of a single vaccination group card.
enum GroupCardState {
  /// Already confirmed — red tinted card, filled red checkbox with white ✓.
  selected,

  /// The next available group to tap — white card, grey border, full opacity.
  enabled,

  /// Not yet reachable — white card, grey border, 0.25 opacity.
  disabled,
}

// ─────────────────────────────────────────────────────────────────────────────

/// VaccinationSurveyProvider
///
/// Manages all state for the Vaccination Survey Select page.
///
/// When a [childId] is provided, fetches milestone data from the API
/// (`GET /api/Vaccination/survey/{childId}`). Each milestone carries
/// [isDisabled] and [isAutoSelected] flags from the backend:
///
/// - **isAutoSelected = true** → group is pre-selected (past milestones).
/// - **isDisabled = true** → group cannot be toggled (future milestones).
///
/// Falls back to hardcoded [VaccinationGroupModel.defaultGroups] when no
/// childId is provided or the API call fails.
class VaccinationSurveyProvider extends ChangeNotifier {
  // ──────────────────────── Dependencies ─────────────────────────────────────

  final AuthService _authService = AuthService();

  // ──────────────────────── State Variables ──────────────────────────────────

  /// The ordered list of vaccination groups (from API or hardcoded).
  List<VaccinationGroupModel> _groups = [];

  /// IDs of groups the parent has confirmed as received.
  final Set<String> _selectedGroupIds = {};

  /// Child's name shown in the page header.
  String _childName = '';

  /// The child ID used for API calls.
  String? _childId;

  /// The child's age in months from the API (used to decide flow).
  int _ageMonths = 0;

  /// Loading guard for API calls.
  bool _isLoading = false;

  // ──────────────────────── SharedPreferences Key ────────────────────────────

  static const String _childNameKey = 'ajial_child_name';

  // ──────────────────────── Getters ──────────────────────────────────────────

  List<VaccinationGroupModel> get groups => List.unmodifiable(_groups);
  String get childName => _childName;
  String? get childId => _childId;
  int get ageMonths => _ageMonths;
  bool get isLoading => _isLoading;

  /// Returns `true` if [id] is in the selected set.
  bool isGroupSelected(String id) => _selectedGroupIds.contains(id);

  // ──────────────────────── Derived State ────────────────────────────────────

  /// Computes the [GroupCardState] for the group at [index].
  ///
  /// - **selected** : in the selected set (auto or manual).
  /// - **disabled** : `isDisabled` is true (future milestone from API).
  /// - **enabled**  : everything else (ready to tap).
  GroupCardState getGroupState(int index) {
    final group = _groups[index];

    // If already selected (auto or manual).
    if (_selectedGroupIds.contains(group.id)) {
      return GroupCardState.selected;
    }

    // If the API says this milestone is disabled (future).
    if (group.isDisabled) {
      return GroupCardState.disabled;
    }

    return GroupCardState.enabled;
  }

  // ──────────────────────── Methods ──────────────────────────────────────────

  /// Loads groups and child name.
  ///
  /// When [childId] is provided, calls the API
  /// `GET /api/Vaccination/survey/{childId}` and builds groups from the
  /// milestones response. Auto-selects any milestones where
  /// `isAutoSelected == true`.
  ///
  /// Falls back to hardcoded [VaccinationGroupModel.defaultGroups] and
  /// [SharedPreferences] when no childId or API fails.
  Future<void> loadData({String? childId, String? childName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _childId = childId;

      // ── 1. Try fetching from the Vaccination survey API ───────────────
      if (childId != null && childId.isNotEmpty) {
        final data = await _authService.getVaccinationSurvey(childId);

        if (data != null) {
          // Parse child name from API response.
          _childName = data['childName']?.toString() ?? '';

          // Parse ageMonths from API response.
          _ageMonths = data['ageMonths'] ?? 0;

          // Parse milestones into groups — only include basic milestones
          // (ageInMonths < 48, i.e. under 4 years). Additional (school-age)
          // milestones are handled separately by AdditionalVaccinationProvider.
          final List<dynamic> milestones = data['milestones'] ?? [];
          _groups = milestones
              .where((m) =>
                  m is Map<String, dynamic> &&
                  !m.containsKey('ageInYears') &&
                  (m['ageInMonths'] == null || (m['ageInMonths'] as int) < 48))
              .map((m) =>
                  VaccinationGroupModel.fromJson(m as Map<String, dynamic>))
              .toList();

          // Auto-select milestones where isAutoSelected == true.
          _selectedGroupIds.clear();
          for (final group in _groups) {
            if (group.isAutoSelected) {
              _selectedGroupIds.add(group.id);
            }
          }

          _isLoading = false;
          notifyListeners();
          return; // API succeeded — done.
        }
        debugPrint('VaccinationSurveyProvider: API call failed, falling back.');
      }

      // ── 2. Fallback: hardcoded groups + route arg / SharedPreferences ──
      _groups = VaccinationGroupModel.defaultGroups();

      if (childName != null && childName.isNotEmpty) {
        _childName = childName;
      } else {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _childName = prefs.getString(_childNameKey) ?? '';
      }
    } catch (e) {
      debugPrint('VaccinationSurveyProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the selected state of the group identified by [id].
  ///
  /// Groups with [isDisabled] = true cannot be toggled.
  ///
  /// **Cascading rules (always apply):**
  /// - **Select**: auto-selects ALL non-disabled groups from index 0 up to
  ///   and including the tapped group.
  /// - **Deselect**: removes the tapped group AND cascades downward —
  ///   all non-disabled groups after it are also deselected.
  void toggleGroup(String id) {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return;

    final group = _groups[index];

    // Cannot toggle disabled groups.
    if (group.isDisabled) return;

    if (_selectedGroupIds.contains(id)) {
      // ── Deselect: cascade all non-disabled groups from this index down ──
      for (int i = index; i < _groups.length; i++) {
        if (!_groups[i].isDisabled) {
          _selectedGroupIds.remove(_groups[i].id);
        }
      }
    } else {
      // ── Select: auto-fill all non-disabled groups from 0 up to this ────
      for (int i = 0; i <= index; i++) {
        if (!_groups[i].isDisabled) {
          _selectedGroupIds.add(_groups[i].id);
        }
      }
    }

    notifyListeners();
  }

  /// Called when the parent taps "التالى" (Next / Confirm).
  ///
  /// Builds a list of milestone selections, prints them, then:
  /// - If ageMonths < 48: shows the confirmation dialog directly
  ///   (skips additional vaccination survey).
  /// - If ageMonths >= 48: navigates to the additional vaccination survey.
  Future<void> onConfirm(BuildContext context) async {
    if (_isLoading) return;

    // Build milestone selection list.
    final List<Map<String, dynamic>> milestoneSelections = _groups.map((g) {
      return {
        'milestoneId': int.tryParse(g.id) ?? g.id,
        'isTaken': _selectedGroupIds.contains(g.id),
      };
    }).toList();

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint(
        'Vaccination Survey — Milestone Selections (ageMonths=$_ageMonths):');
    for (final selection in milestoneSelections) {
      debugPrint('  $selection');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    if (_ageMonths < 48) {
      // Child is under 4 years — skip additional survey, confirm directly.
      final confirmed = await showConfirmSurveyDialog(context);
      if (confirmed && context.mounted) {
        if (_childId != null) {
          await _authService.submitVaccinationSurvey(
            childId: _childId!,
            selections: milestoneSelections,
          );
        }
        if (context.mounted) {
          Navigator.pushNamed(context, '/vaccination-success');
        }
      }
    } else {
      // Child is 4+ years — go to additional survey page.
      Navigator.pushNamed(
        context,
        '/additional-vaccination-survey',
        arguments: {
          'childName': _childName,
          'childId': _childId,
          'milestoneSelections': milestoneSelections,
        },
      );
    }
  }

  /// Called when the parent taps "الغاء" (Cancel / Skip).
  ///
  /// Shows the cancel confirmation dialog. If confirmed, navigates
  /// back to the profile page.
  Future<void> onCancel(BuildContext context) async {
    if (_isLoading) return;
    final confirmed = await showCancelSurveyDialog(context);
    if (confirmed && context.mounted) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == '/profile');
    }
  }

  /// Called when the parent taps the close (×) button.
  ///
  /// Shows the cancel confirmation dialog. If confirmed, navigates
  /// back to the profile page.
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
    _ageMonths = 0;
    _isLoading = false;
    notifyListeners();
  }
}
