// --- forgetpassword.dart ---

import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/verifyemail.dart';
// import 'package:ajial/login_screen.dart'; // كمثال

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // --- تعديل: متغير لمتابعة حالة الإيميل (للحد الأخضر) ---
  bool _isEmailValid = false;

  // --- تعديل: دالة للتحقق من الإيميل ---
  bool _validateEmail(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    // --- تعديل: مراقبة حقل الإيميل لزر X والحد الأخضر ---
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

  /// دالة للـ Validation والـ Submit
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // --- هنا يتم إرسال الإيميل للـ Backend ---
      print('Sending password reset email to: ${_emailController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري إرسال رابط استعادة كلمة المرور...')),
      );

      // --- *** مكان الانتقال لصفحة (ادخال الكود) أو (اعادة التعيين) *** ---
      // شيل الكومنت وحط اسم الصفحة اللي عاوز تروحها

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(email: _emailController.text),
        ), // كمثال
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  // --- أيقونة الرجوع المطلوبة ---
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: kPrimaryColor,
                        size: 30,
                      ),
                      onPressed: () {
                        // --- لوجيك الرجوع للصفحة السابقة ---
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- اللوجو ---
                  Center(
                    child: Image.asset(
                      'images/main-logo.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.group,
                        size: 120,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 16),

                  // --- العناوين ---
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 40),

                  // --- حقل البريد الالكتروني ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildLabel('البريد الالكتروني *'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    // --- تعديل: إجباري LTR ---
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: _buildInputDecoration(
                      hintText: 'اكتب بريدك الالكتروني هنا...',
                      // --- تعديل: زر X للمسح ---
                      suffixIcon: _emailController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => _emailController.clear(),
                            )
                          : null,
                      // --- تعديل: لوجيك الحد الأخضر ---
                      borderColor: _isEmailValid ? Colors.green : null,
                      focusedBorderColor: _isEmailValid
                          ? Colors.green
                          : kPrimaryColor,
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
                  const SizedBox(height: 270),

                  // --- زر "تأكيد" ---
                  ElevatedButton(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// دالة لإنشاء الـ Label فوق كل حقل
  Widget _buildLabel(String text) {
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

  /// دالة لتوحيد شكل الـ InputDecoration (مستخدمة من الكود السابق)
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorColor,
  }) {
    final defaultBorderColor = borderColor ?? Colors.grey[400]!;
    final defaultFocusedBorderColor = focusedBorderColor ?? kPrimaryColor;
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
