import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_auth_provider.dart';
import '../widgets/step_indicator.dart';

const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Helper to build a label with a red asterisk if the text ends with *
Widget buildSpecLabel(String text) {
  final hasAsterisk = text.endsWith('*');
  final cleanText = hasAsterisk ? text.substring(0, text.length - 1) : text;

  return SizedBox(
    width: double.infinity,
    child: RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: _kFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: cleanText),
          if (hasAsterisk)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFBF092F)),
            ),
        ],
      ),
    ),
  );
}

/// Step 1: Personal Information
class StepPersonalInfo extends StatelessWidget {
  const StepPersonalInfo({super.key});

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
              // Title
              const Text(
                'إنشاء حسابك المهني',
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
                'ابدأ بانشاء حسابك لتتمكن من الدخول لاحقاً.',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Full Name
              buildSpecLabel('الاسم رباعي*'),
              const SizedBox(height: 8),
              _buildTextField(
                hint: 'مثل : Mohammed Ibrahim',
                onChanged: (v) => prov.fullName = v,
              ),
              const SizedBox(height: 16),

              // Username
              buildSpecLabel('اسم المستخدم*'),
              const SizedBox(height: 8),
              _buildTextField(
                hint: 'مثل : MohammedIbrahim22',
                onChanged: (v) => prov.username = v,
              ),
              const SizedBox(height: 16),

              // Email
              buildSpecLabel('البريد الالكتروني*'),
              const SizedBox(height: 8),
              _buildTextField(
                hint: 'مثل : MohammedIbrahim22@gmail.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => prov.email = v,
              ),
              const SizedBox(height: 16),

              // Phone
              buildSpecLabel('رقم الهاتف*'),
              const SizedBox(height: 8),
              _buildPhoneField(onChanged: (v) => prov.phone = v),
              const SizedBox(height: 16),

              // Password
              buildSpecLabel('كلمة المرور*'),
              const SizedBox(height: 8),
              _buildPasswordField(
                hint: 'كلمة المرور',
                obscure: prov.passwordObscure,
                onToggle: prov.togglePasswordVisibility,
                onChanged: (v) => prov.password = v,
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTextField({
    required String hint,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
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
          contentPadding: const EdgeInsets.only(right: 16, left: 10, top: 14, bottom: 14),
        ),
      ),
    );
  }

  static Widget _buildPhoneField({required ValueChanged<String> onChanged}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          // Phone field (RIGHT side in RTL = first child)
          Expanded(
            child: TextField(
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.phone,
              onChanged: onChanged,
              style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
              decoration: InputDecoration(
                hintText: '0020123456897',
                hintStyle: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(right: 16, left: 10, top: 14, bottom: 14),
              ),
            ),
          ),
          // Left side in RTL: Egypt flag + dropdown arrow (last child)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_down,
                    size: 20, color: Colors.black.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                const Text('🇪🇬', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPasswordField({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          // Password field (RIGHT side in RTL = first child)
          Expanded(
            child: TextField(
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              obscureText: obscure,
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
                contentPadding: const EdgeInsets.only(right: 16, left: 10, top: 14, bottom: 14),
              ),
            ),
          ),
          // Eye icon (LEFT side in RTL = last child)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: onToggle,
              child: Opacity(
                opacity: 0.5,
                child: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 24,
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
