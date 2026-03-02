// --- lib/vaccinations/widgets/vaccination_welcome_buttons.dart ---

import 'package:flutter/material.dart';

// ─────────────────────── Design Tokens (local) ──────────────────────────────
const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// VaccinationWelcomeButtons
///
/// The two-button column at the bottom of the Vaccination Welcome Page:
///   • Primary  — "بدء تسجيل التطعيمات"  (red filled pill)
///   • Secondary — "رجوع"                  (white outlined pill)
///
/// All interaction logic is lifted via callbacks so this widget stays
/// purely presentational and easy to unit/widget test.
class VaccinationWelcomeButtons extends StatelessWidget {
  /// Called when the user taps the primary "بدء تسجيل التطعيمات" button.
  final VoidCallback onStart;

  /// Called when the user taps the secondary "رجوع" button.
  final VoidCallback onBack;

  /// When true both buttons are disabled (e.g., during loading).
  final bool isLoading;

  const VaccinationWelcomeButtons({
    super.key,
    required this.onStart,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Primary button ───────────────────────────────────────────────
        _PrimaryButton(
          onPressed: isLoading ? null : onStart,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'بدء تسجيل التطعيمات',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // ── Secondary (back / skip) button ───────────────────────────────
        _SecondaryButton(
          onPressed: isLoading ? null : onBack,
          label: 'رجوع',
        ),
      ],
    );
  }
}

// ─────────────────── Private sub-widgets ────────────────────────────────────

/// Red filled pill button — matches Figma: 343×50, bg #BF092F, radius 50.
class _PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          disabledBackgroundColor: _kPrimaryColor.withOpacity(0.6),
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: child,
      ),
    );
  }
}

/// White outlined pill button — matches Figma: 343×50, border rgba(0,0,0,0.5).
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.black.withOpacity(0.5)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
