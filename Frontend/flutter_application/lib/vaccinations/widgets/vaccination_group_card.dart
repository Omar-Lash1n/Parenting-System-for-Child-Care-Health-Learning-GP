// --- lib/vaccinations/widgets/vaccination_group_card.dart ---

import 'package:flutter/material.dart';
import 'package:Ajial/vaccinations/vaccination_survey_provider.dart';

// ─────────────────────── Design Tokens ───────────────────────────────────────
const Color _kPrimaryColor = Color(0xFFBF092F);
const Color _kPrimaryBg = Color(0x0DBF092F); // rgba(191, 9, 47, 0.05)
const Color _kGreyBorder = Color(0xFFD9D9D9);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// VaccinationGroupCard
///
/// A single row in the vaccination survey checklist. Renders three distinct
/// visual states driven by [GroupCardState]:
///
/// | State     | Background        | Border          | Checkbox        | Opacity |
/// |-----------|-------------------|-----------------|-----------------|---------|
/// | selected  | light red tint    | red #BF092F     | filled red + ✓  | 1.0     |
/// | enabled   | white             | grey #D9D9D9    | empty grey box  | 1.0     |
/// | disabled  | white             | grey #D9D9D9    | empty grey box  | 0.25    |
///
/// Disabled cards are still tappable — the provider auto-fills all groups
/// above when any unselected card is tapped.
class VaccinationGroupCard extends StatelessWidget {
  /// The Arabic heading (bold 16 px).
  final String title;

  /// The Arabic vaccine description (regular 12 px).
  final String subtitle;

  /// Controls the card's visual appearance.
  final GroupCardState state;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  const VaccinationGroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.state,
    this.onTap,
  });

  // ──────────────────────────────── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isSelected = state == GroupCardState.selected;
    final bool isDisabled = state == GroupCardState.disabled;

    final Color cardBackground = isSelected ? _kPrimaryBg : Colors.white;
    final Color borderColor = isSelected ? _kPrimaryColor : _kGreyBorder;

    return Opacity(
      opacity: isDisabled ? 0.25 : 1.0,
      child: GestureDetector(
        // All cards tappable — provider handles auto-fill above on selection
        onTap: onTap,
        child: Directionality(
          // Force RTL inside the card so the Row and text both render RTL
          textDirection: TextDirection.rtl,
          child: Container(
            width: double.infinity,
            height: 88,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBackground,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            // In RTL: first child → rendered on the RIGHT.
            // So checkbox (first) sits on the right, text expands left.
            child: Row(
              children: [
                // ── Checkbox (right side in RTL) ─────────────────────────
                _CheckboxWidget(isSelected: isSelected),

                const SizedBox(width: 12),

                // ── Text block (fills remaining space to the left) ────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title — rendered RTL by inherited Directionality
                      Text(
                        title,
                        textAlign: TextAlign.start, // start = right in RTL
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 28 / 16,
                          color: Color(0xFF000000),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Subtitle
                      Text(
                        subtitle,
                        textAlign: TextAlign.start, // start = right in RTL
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 15 / 12,
                          color: isSelected
                              ? _kPrimaryColor
                              : const Color(0xBF000000), // rgba(0,0,0,0.75)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Private sub-widget ──────────────────────────────────

/// Renders the 32×32 checkbox icon in either selected or unselected state.
///
/// Selected: red filled rounded square with a white ✓ icon.
/// Unselected: white rounded square with a 2 px grey border.
class _CheckboxWidget extends StatelessWidget {
  final bool isSelected;

  const _CheckboxWidget({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return isSelected ? _SelectedCheckbox() : _UnselectedCheckbox();
  }
}

/// Red filled 32×32 rounded box with a white check mark icon.
class _SelectedCheckbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _kPrimaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 17.45,
        ),
      ),
    );
  }
}

/// Grey outlined empty 32×32 rounded box (unselected state).
class _UnselectedCheckbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kGreyBorder, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
