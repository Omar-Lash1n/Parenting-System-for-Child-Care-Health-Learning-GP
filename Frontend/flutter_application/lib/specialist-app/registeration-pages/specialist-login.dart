import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'specialist-registration.dart';
import '../providers/specialist_auth_provider.dart';
import '../steps/step_personal_info.dart'; // for buildSpecLabel
import '../specialist_home.dart';

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Specialist Login Screen
class SpecialistLoginScreen extends StatelessWidget {
  const SpecialistLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpecialistAuthProvider(),
      child: const _SpecialistLoginBody(),
    );
  }
}

class _SpecialistLoginBody extends StatelessWidget {
  const _SpecialistLoginBody();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<SpecialistAuthProvider>(
            builder: (context, prov, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Logo
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
                          const SizedBox(height: 16),
                          // Title
                          const Text(
                            'تسجيل دخول المتخصص',
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'من فضلك ادخل البيانات بعناية',
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Colors.black.withValues(alpha: 0.75),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Username
                          buildSpecLabel('اسم المستخدم*'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            hint: 'مثل : MohammedIbrahim22',
                            onChanged: (v) => prov.loginUsername = v,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          buildSpecLabel('كلمة المرور*'),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            hint: 'كلمة المرور',
                            obscure: prov.loginObscure,
                            onToggle: prov.toggleLoginVisibility,
                            onChanged: (v) => prov.loginPassword = v,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error message
                  if (prov.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFBF092F)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                prov.errorMessage!,
                                style: const TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 13,
                                  color: Color(0xFFBF092F),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => prov.clearError(),
                              child: const Icon(Icons.close,
                                  size: 18, color: Color(0xFFBF092F)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bottom section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: prov.isLoggingIn
                                ? null
                                : () async {
                                    final result = await prov.login();
                                    if (result != null && result.success) {
                                      if (!context.mounted) return;
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SpecialistHomePage(),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: prov.isLoggingIn
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Navigate to registration
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SpecialistRegistrationScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              children: [
                                const TextSpan(text: 'ليس لديك حساب؟ '),
                                TextSpan(
                                  text: 'انشاء حساب جديد',
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
                  ),
                ],
              );
            },
          ),
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
          contentPadding:
              const EdgeInsets.only(right: 16, left: 10, top: 14, bottom: 14),
        ),
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
                contentPadding: const EdgeInsets.only(
                    right: 16, left: 10, top: 14, bottom: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: onToggle,
              child: Opacity(
                opacity: 0.5,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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
