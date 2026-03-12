import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_auth_provider.dart';
import '../widgets/step_indicator.dart';
import '../steps/step_personal_info.dart';
import '../steps/step_identity.dart';
import '../steps/step_license.dart';
import '../steps/step_syndicate.dart';
import '../steps/step_success.dart';

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Specialist Registration Screen — hosts the 4-step indicator + PageView
/// Success page is a separate screen navigated to after submission.
class SpecialistRegistrationScreen extends StatelessWidget {
  const SpecialistRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpecialistAuthProvider(),
      child: const _RegistrationBody(),
    );
  }
}

class _RegistrationBody extends StatelessWidget {
  const _RegistrationBody();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<SpecialistAuthProvider>(
            builder: (context, prov, _) {
              // When submission completes → navigate to success screen
              if (prov.submissionComplete) {
                // Reset the flag and navigate after this frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  prov.submissionComplete = false;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SpecialistSuccessScreen(),
                    ),
                  );
                });
              }

              return Column(
                children: [
                  // PageView — only 4 form steps
                  Expanded(
                    child: PageView(
                      controller: prov.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        StepPersonalInfo(),
                        StepIdentity(),
                        StepLicense(),
                        StepSyndicate(),
                      ],
                    ),
                  ),

                  // Bottom buttons
                  _buildBottomButtons(context, prov),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, SpecialistAuthProvider prov) {
    final isFirstStep = prov.currentStep == 0;
    final isLastFormStep = prov.currentStep == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary button: Next / Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: prov.isSubmitting
                  ? null
                  : () {
                      if (isLastFormStep) {
                        prov.submit();
                      } else {
                        prov.nextStep();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: prov.isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastFormStep ? 'انشاء حساب' : 'التالي',
                      style: const TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary button: Back (shown on steps 2,3,4)
          if (!isFirstStep)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => prov.previousStep(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'السابق',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Navigate to login link
          GestureDetector(
            onTap: () {
              // Pop back to Login screen
              Navigator.of(context).pop();
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(text: 'لديك حساب بالفعل؟ '),
                  TextSpan(
                    text: 'تسجيل الدخول',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _kGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone Success screen — completely separate from the PageView
class SpecialistSuccessScreen extends StatelessWidget {
  const SpecialistSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StepSuccess(),
        ),
      ),
    );
  }
}
