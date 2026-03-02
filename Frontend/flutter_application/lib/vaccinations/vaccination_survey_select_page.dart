// --- lib/vaccinations/vaccination_survey_select_page.dart ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Ajial/vaccinations/vaccination_survey_provider.dart';
import 'package:Ajial/vaccinations/widgets/vaccination_group_card.dart';

// ─────────────────────── Design Tokens ───────────────────────────────────────
const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// VaccinationSurveySelectPage
///
/// Allows the parent to select which vaccination age-groups their child has
/// already received, in sequential order. The provider enforces the rule
/// that groups must be selected one-by-one from the top downward.
///
/// Route: '/vaccination-survey'
///
/// Route arguments (optional Map<String, dynamic>):
///   • 'childName' — overrides the value from SharedPreferences
class VaccinationSurveySelectPage extends StatefulWidget {
  const VaccinationSurveySelectPage({super.key});

  @override
  State<VaccinationSurveySelectPage> createState() =>
      _VaccinationSurveySelectPageState();
}

class _VaccinationSurveySelectPageState
    extends State<VaccinationSurveySelectPage> {
  bool _dataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataLoaded) return;
    _dataLoaded = true;

    // Parse optional route arguments.
    final args = ModalRoute.of(context)?.settings.arguments;
    String? childId;
    String? childName;
    if (args is Map<String, dynamic>) {
      childId = args['childId'] as String?;
      childName = args['childName'] as String?;
    }

    // Load data once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VaccinationSurveyProvider>().loadData(
            childId: childId,
            childName: childName,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<VaccinationSurveyProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Top spacing ──────────────────────────────────────────
                  const SizedBox(height: 25),

                  // ── Close button row ─────────────────────────────────────
                  // In RTL the close button sits on the far left (leading side
                  // in visual terms is end in RTL — Figma shows it top-right
                  // which is the logical "start" in RTL = visual left).
                  _CloseButtonRow(
                    onClose: () => provider.onClose(context),
                  ),

                  const SizedBox(height: 26),

                  // ── Header: title + subtitle ─────────────────────────────
                  _HeaderSection(childName: provider.childName),

                  const SizedBox(height: 26),

                  // ── Scrollable list of vaccination group cards ───────────
                  Expanded(
                    child: provider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _kPrimaryColor,
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: provider.groups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final group = provider.groups[index];
                              final state = provider.getGroupState(index);
                              return VaccinationGroupCard(
                                title: group.title,
                                subtitle: group.subtitle,
                                state: state,
                                onTap: () => provider.toggleGroup(group.id),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  // ── Action buttons ───────────────────────────────────────
                  _SurveyButtons(
                    isLoading: provider.isLoading,
                    onConfirm: () => provider.onConfirm(context),
                    onCancel: () => provider.onCancel(context),
                  ),

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

// ─────────────────────── Private Sub-Widgets ─────────────────────────────────

/// Top row containing only the close (×) button, aligned to the end of the
/// row which in RTL layout visually renders on the left — matching Figma.
class _CloseButtonRow extends StatelessWidget {
  final VoidCallback onClose;

  const _CloseButtonRow({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.start, // start = visual RIGHT in RTL
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered column with the bold title (interpolates child name) and a lighter
/// subtitle. Matches the two-text group in Frame 15041 from the Figma export.
class _HeaderSection extends StatelessWidget {
  final String childName;

  const _HeaderSection({required this.childName});

  @override
  Widget build(BuildContext context) {
    final String displayName = childName.isNotEmpty ? childName : 'طفلك';

    // Base style shared by all title spans
    const TextStyle baseTitle = TextStyle(
      fontFamily: _kFontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 33 / 22,
      color: Color(0xFF000000),
    );

    return SizedBox(
      width: 264,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title — "الاساسية" colored in primary red
          RichText(
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: baseTitle,
              children: [
                const TextSpan(text: 'حدد التطعيمات '),
                TextSpan(
                  text: 'الاساسية ',
                  style: baseTitle.copyWith(color: _kPrimaryColor),
                ),
                TextSpan(text: 'التي تلقاها $displayName حتى الان'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle
          const Text(
            'لتخصيص جدول زمنى دقيق',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontWeight: FontWeight.w300,
              fontSize: 16,
              height: 24 / 16,
              color: Color(0xBF000000), // rgba(0, 0, 0, 0.75)
            ),
          ),
        ],
      ),
    );
  }
}

/// The two bottom action buttons: "التالى" (primary red pill) and "الغاء"
/// (secondary white outlined pill). Matches Frame 202 from the Figma export.
class _SurveyButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SurveyButtons({
    required this.isLoading,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Primary: "التالى" ────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              disabledBackgroundColor: _kPrimaryColor.withOpacity(0.6),
              shape: const StadiumBorder(),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
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
                    'التالى',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Secondary: "الغاء" ──────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.black.withOpacity(0.5)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'الغاء',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
