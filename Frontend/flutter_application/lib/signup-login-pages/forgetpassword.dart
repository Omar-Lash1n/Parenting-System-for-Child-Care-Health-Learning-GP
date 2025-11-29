// --- forgetpassword.dart (Updated with New Back Button Style) ---

import 'package:flutter/material.dart';
import 'package:Ajial/signup-login-pages/verifyemail.dart';
import 'package:Ajial/api/auth_service.dart'; // (تأكد من المسار)
// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
// --- نهاية الإضافة ---
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isEmailValid = false;

  // --- تعديل: إضافة متغيرات الـ API ---
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  // --- نهاية التعديل ---

  bool _validateEmail(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (mounted) {
        setState(() {
          _isEmailValid = _validateEmail(_emailController.text);
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

 /// دالة للـ Validation والـ Submit (تم تعديلها بالكامل)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // لا تكمل إذا كان الإيميل غير صالح
    }

    // 1. إظهار التحميل
    setState(() { _isLoading = true; });

    try {
      // 2. استدعاء الخدمة
      final (bool success, String message) = await _authService.forgotPassword(
        email: _emailController.text,
      );

      // 3. التعامل مع الرد
      if (success) {
        // --- نجاح ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: TextStyle(fontFamily: kFontFamily)),
            backgroundColor: Colors.green, // (أخضر للنجاح)
          ),
        );
        
        // (الانتقال لصفحة إدخال الرمز)
        Navigator.push(
          context,
          FadePageRoute(
            child: VerifyEmailScreen(email: _emailController.text),
          ),
        );
      } else {
        // --- خطأ من السيرفر (مثل: الإيميل غير موجود) ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: TextStyle(fontFamily: kFontFamily)),
            backgroundColor: kPrimaryColor, // (أحمر للفشل)
          ),
        );
      }
    } catch (e) {
      // --- خطأ غير متوقع ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e', style: TextStyle(fontFamily: kFontFamily)),
          backgroundColor: kPrimaryColor,
        ),
      );
    } finally {
      // 4. إخفاء التحميل
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  // --- نهاية لوجيك الـ API ---

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final Color mainRed = kPrimaryColor;
    final Color lightPink = kPrimaryColor.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // (الهيكل بالـ Column والـ Expanded كما هو)
        child: Column(
          children: [
            // --- 1. المحتوى القابل للـ Scroll ---
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 40.0 : 24.0,
                        vertical: 20.0,
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // --- زر الرجوع (معطل أثناء التحميل) ---
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: lightPink,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    color: kPrimaryColor,
                                    size: 24,
                                  ),
                                  onPressed: _isLoading ? null : () {
                                    Navigator.pop(context);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),

                            // --- اللوجو (كما هو) ---
                            Center(
                              child: Image.asset(
                                'images/main-logo.png',
                                width: screenHeight * 0.15,
                                height: screenHeight * 0.15,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.group,
                                  size: screenHeight * 0.15,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // --- العناوين (كما هي) ---
                            const Center(
                              child: Text(
                                'نسيت كلمة المرور!',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'من فضلك ادخل البيانات بعناية',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.04),

                            // --- حقل البريد الالكتروني ---
                            _buildLabel('البريد الالكتروني *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading, // (تعطيل أثناء التحميل)
                              decoration: _buildInputDecoration(
                                hintText: 'اكتب بريدك الالكتروني هنا...',
                                suffixIcon: _emailController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _emailController.clear(),
                                      )
                                    : null,
                                borderColor:
                                    _isEmailValid ? Colors.green : null,
                                focusedBorderColor:
                                    _isEmailValid ? Colors.green : null,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'البريد الالكتروني مطلوب';
                                }
                                if (!_validateEmail(value)) {
                                  return 'صيغة بريد الكتروني غير صحيحة';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // --- 2. الزر الثابت في الأسفل ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              // --- تعديل: إظهار التحميل أو الزر ---
              child: SizedBox(
                height: 55, // (للحفاظ على الارتفاع)
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (دالة _buildLabel مع النجمة الحمراء كما هي)
  Widget _buildLabel(String text) {
    if (text.endsWith(' *')) {
      final String label = text.substring(0, text.length - 2);
      final String asterisk = ' *';
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: asterisk,
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        text,
        style: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      );
    }
  }

  /// (دالة _buildInputDecoration مع التركيز الأسود كما هي)
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorColor,
  }) {
    final defaultBorderColor = borderColor ?? Colors.grey[400]!;
    final defaultFocusedBorderColor = focusedBorderColor ?? Colors.black;
    final defaultErrorBorderColor = errorColor ?? kPrimaryColor;
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontFamily: kFontFamily, color: Colors.grey),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintTextDirection: TextDirection.rtl,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: defaultBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: defaultBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: defaultFocusedBorderColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: defaultErrorBorderColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: defaultErrorBorderColor, width: 2.0),
      ),
      errorStyle: const TextStyle(
        fontFamily: kFontFamily,
        color: kPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}