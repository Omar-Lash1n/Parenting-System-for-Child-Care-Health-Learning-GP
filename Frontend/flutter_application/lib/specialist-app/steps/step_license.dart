import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_auth_provider.dart';
import '../widgets/step_indicator.dart';
import 'step_personal_info.dart'; // for buildSpecLabel

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Step 3: Profession License — Specialty dropdown, certificate, license number, license image
class StepLicense extends StatelessWidget {
  const StepLicense({super.key});

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
                'ترخيص مزاولة المهنة',
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

              // Specialty dropdown
              buildSpecLabel('التخصص*'),
              const SizedBox(height: 8),
              _buildDropdown(prov),
              const SizedBox(height: 16),

              // Certificate Image
              buildSpecLabel('صورة شهادة التخصص*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.certificateImagePath,
                onTap: () => prov.setCertificateImage('certificate.png'),
              ),
              const SizedBox(height: 16),

              // License Number
              buildSpecLabel('رقم الترخيص المهنى*'),
              const SizedBox(height: 8),
              _buildTextField(
                hint: 'مثل : *****-*******-7859',
                onChanged: (v) => prov.licenseNumber = v,
              ),
              const SizedBox(height: 16),

              // License Image
              buildSpecLabel('صورة الترخيص المهنى*'),
              const SizedBox(height: 8),
              _buildImagePicker(
                fileName: prov.licenseImagePath,
                onTap: () => prov.setLicenseImage('license.png'),
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildDropdown(SpecialistAuthProvider prov) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(right: 8, left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: prov.selectedSpecialty,
          isExpanded: true,
          icon: Opacity(
            opacity: 0.5,
            child: const Icon(Icons.keyboard_arrow_down, size: 24),
          ),
          hint: Text(
            'متخصص تربوى/طبيب أطفال ...',
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.right,
          ),
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color: Colors.black,
          ),
          items: prov.specialties.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(s),
              ),
            );
          }).toList(),
          onChanged: prov.setSpecialty,
        ),
      ),
    );
  }

  static Widget _buildTextField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(right: 8, left: 10, top: 14, bottom: 14),
        ),
      ),
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
          // Text hint (RIGHT in RTL — first in Row)
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
