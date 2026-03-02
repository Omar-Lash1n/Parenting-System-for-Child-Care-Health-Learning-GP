// --- lib/vaccinations/additional_vaccination_survey_page.dart ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Ajial/vaccinations/additional_vaccination_provider.dart';
import 'package:Ajial/vaccinations/widgets/vaccination_group_card.dart';

// ─────────────────────── Design Tokens ───────────────────────────────────────
const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// AdditionalVaccinationSurveyPage
///
/// Allows the parent to select which **additional** (school-age) vaccination
/// groups their child has already received. Follows the same sequential
/// selection pattern as [VaccinationSurveySelectPage].
///
/// Route: '/additional-vaccination-survey'
///
/// Route arguments (optional Map<String, dynamic>):
///   • 'childName' — overrides the value from SharedPreferences
class AdditionalVaccinationSurveyPage extends StatefulWidget {
  const AdditionalVaccinationSurveyPage({super.key});

  @override
  State<AdditionalVaccinationSurveyPage> createState() =>
      _AdditionalVaccinationSurveyPageState();
}

class _AdditionalVaccinationSurveyPageState
    extends State<AdditionalVaccinationSurveyPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Parse optional route arguments.
    final args = ModalRoute.of(context)?.settings.arguments;
    String? childName;
    String? childId;
    List<Map<String, dynamic>>? milestoneSelections;
    if (args is Map<String, dynamic>) {
      childName = args['childName'] as String?;
      childId = args['childId'] as String?;
      if (args['milestoneSelections'] is List) {
        milestoneSelections =
            (args['milestoneSelections'] as List).cast<Map<String, dynamic>>();
      }
    }

    // Load data once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdditionalVaccinationProvider>().loadData(
            childName: childName,
            childId: childId,
            milestoneSelections: milestoneSelections,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AdditionalVaccinationProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Top spacing ──────────────────────────────────────────
                  const SizedBox(height: 25),

                  // ── Close (×) button — top right ─────────────────────────
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

/// Close (×) button row, aligned to the visual right (start in RTL).
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

/// Page header — title with "الاضافية" colored in primary red, plus subtitle.
class _HeaderSection extends StatelessWidget {
  final String childName;

  const _HeaderSection({required this.childName});

  @override
  Widget build(BuildContext context) {
    final String displayName = childName.isNotEmpty ? childName : 'طفلك';

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
          // Title — "الاضافية" colored in primary red
          RichText(
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: baseTitle,
              children: [
                const TextSpan(text: 'حدد التطعيمات '),
                TextSpan(
                  text: 'الاضافية ',
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

/// Bottom action buttons: "التالي" (primary red pill) and "الغاء" (outlined).
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
        // ── Primary: "التالي" ────────────────────────────────────────────
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
                    'التالي',
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
