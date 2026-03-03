// --- lib/vaccinations/vaccination_welcome_page.dart ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Ajial/vaccinations/vaccination_welcome_provider.dart';
import 'package:Ajial/vaccinations/widgets/child_profile_frame.dart';
import 'package:Ajial/vaccinations/widgets/vaccination_welcome_buttons.dart';

// ─────────────────────── Design Tokens ──────────────────────────────────────
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// VaccinationWelcomePage
///
/// The landing page that introduces the Vaccination Survey flow to the parent.
/// Shows the selected child's photo in a decorative frame, a brief call-to-
/// action headline/subtitle, and two action buttons.
///
/// Route: '/vaccination-welcome'
///
/// Route arguments (optional Map<String, dynamic>):
///   • 'childName'            — overrides the value from SharedPreferences
///   • 'childProfileImageUrl' — overrides the value from SharedPreferences
class VaccinationWelcomePage extends StatefulWidget {
  const VaccinationWelcomePage({super.key});

  @override
  State<VaccinationWelcomePage> createState() => _VaccinationWelcomePageState();
}

class _VaccinationWelcomePageState extends State<VaccinationWelcomePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Parse optional route arguments.
    final args = ModalRoute.of(context)?.settings.arguments;
    String? childId;
    String? childName;
    String? childProfileImageUrl;

    if (args is Map<String, dynamic>) {
      childId = args['childId'] as String?;
      childName = args['childName'] as String?;
      childProfileImageUrl = args['childProfileImageUrl'] as String?;
    }

    // Load data once after the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VaccinationWelcomeProvider>().loadChildData(
            childId: childId,
            childName: childName,
            childProfileImageUrl: childProfileImageUrl,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea handles both the status bar (top) and home indicator (bottom).
      body: SafeArea(
        child: Consumer<VaccinationWelcomeProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Top spacing from status bar ──────────────────────────
                  const SizedBox(height: 46),

                  // ── Header: title + subtitle ─────────────────────────────
                  _HeaderSection(childName: provider.childName),

                  // ── Middle: child profile photo (expands to fill space) ──
                  Expanded(
                    child: Center(
                      child: ChildProfileFrame(
                        imageUrl: provider.childProfileImageUrl,
                        // size defaults to 280 — bigger on screen.
                        // photoRatio defaults to 0.44 — photo fully inside ring.
                      ),
                    ),
                  ),

                  // ── Bottom: action buttons ───────────────────────────────
                  VaccinationWelcomeButtons(
                    isLoading: provider.isLoading,
                    onStart: () => provider.onStartVaccinations(context),
                    onBack: () => provider.onSkip(context),
                  ),

                  // ── Bottom padding so buttons breathe above home bar ─────
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────── Private sub-widgets ────────────────────────────────────

/// Renders the title and subtitle at the top of the page.
///
/// Extracted as a private widget so it can be pumped independently in tests.
class _HeaderSection extends StatelessWidget {
  /// The child's name inserted into the subtitle string.
  final String childName;

  const _HeaderSection({required this.childName});

  @override
  Widget build(BuildContext context) {
    // Build the subtitle with the child name interpolated. Falls back to a
    // generic placeholder if no name has loaded yet.
    final String displayName = childName.isNotEmpty ? childName : 'طفلك';

    return SizedBox(
      width: 302,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          const Text(
            'تجهيز سجل التطعيمات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 33 / 22, // line-height: 33px from Figma
              color: Color(0xFF000000),
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle
          Text(
            'حدد التطعيمات التي تلقاها $displayName حتى الان لتخصيص جدول زمني دقيق',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontWeight: FontWeight.w300,
              fontSize: 16,
              height: 24 / 16, // line-height: 24px from Figma
              color: Color(0xBF000000), // rgba(0, 0, 0, 0.75)
            ),
          ),
        ],
      ),
    );
  }
}
