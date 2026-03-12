import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_auth_provider.dart';
import '../widgets/step_indicator.dart';
import 'step_personal_info.dart'; // for buildSpecLabel

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Step 2: Identity Proof — Front & Back ID image pickers
class StepIdentity extends StatelessWidget {
  const StepIdentity({super.key});

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
                'اثبات الهوية',
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
                'نحتاج لتأكيد هويتك الشخصية لضمان أمان المنصة',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Front ID
              buildSpecLabel('صورة بطاقة (الوجه الامامى)*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.idFrontImagePath,
                onTap: () {
                  prov.setIdFrontImage('front_id.png');
                },
              ),
              const SizedBox(height: 16),

              // Back ID
              buildSpecLabel('صورة بطاقة (الوجه الخلفي)*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.idBackImagePath,
                onTap: () {
                  prov.setIdBackImage('back_id.png');
                },
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
          // Text hint (RIGHT in RTL visual — first in Row)
          Expanded(
            child: Text(
              fileName ?? 'اضغط تحميل الصورة',
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
          // Upload button (LEFT in RTL visual — last in Row)
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
