import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_auth_provider.dart';
import '../widgets/step_indicator.dart';
import 'step_personal_info.dart'; // for buildSpecLabel

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Step 4: Syndicate Proof — Syndicate card front/back + Personal photo
class StepSyndicate extends StatelessWidget {
  const StepSyndicate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpecialistAuthProvider>(
      builder: (context, prov, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Step Indicator — scrolls with content
              Center(
                child: StepIndicator(currentStep: prov.currentStep),
              ),
              const SizedBox(height: 16),
              // Logo — bigger + black tint
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'images/specialist-ajial-logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'إثبات النقابة',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'هذه البيانات تساعدنا في توثيق تخصصك',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Syndicate Front
              buildSpecLabel('صورة كارنيه النقابه (الوجه الامامى)*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.syndicateFrontImagePath,
                onTap: () => prov.setSyndicateFrontImage('syndicate_front.png'),
              ),
              const SizedBox(height: 16),

              // Syndicate Back
              buildSpecLabel('صورة كارنيه النقابه (الوجه الخلفي)*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.syndicateBackImagePath,
                onTap: () => prov.setSyndicateBackImage('syndicate_back.png'),
              ),
              const SizedBox(height: 16),

              // Personal Photo
              buildSpecLabel('صورة شخصية*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.personalPhotoPath,
                placeholder: '.png / .jpg',
                onTap: () => prov.setPersonalPhoto('personal_photo.png'),
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildImagePicker({
    String? fileName,
    String placeholder = 'اضغط تحميل الصورة',
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(right: 8, left: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          // Text hint (RIGHT in RTL — first in Row)
          Expanded(
            child: Text(
              fileName ?? placeholder,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                color: fileName != null
                    ? Colors.black
                    : Colors.black.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // Upload button (LEFT in RTL — last in Row)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'تحميل صورة',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
