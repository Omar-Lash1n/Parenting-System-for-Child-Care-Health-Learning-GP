// --- login.dart (Updated with API Connection & Sticky Buttons) ---

import 'package:flutter/material.dart';
import 'package:flutter_application/homepage/homepage.dart';
import 'package:flutter_application/signup-login-pages/forgetpassword.dart';
import 'package:flutter_application/signup-login-pages/signup.dart';

// --- 1. إضافة import لخدمة الـ API ---
import 'package:flutter_application/api/auth_service.dart'; // (تأكد من المسار)

// --- (Global Constants & FadePageRoute Helper Class ... كما هي) ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
// --- نهاية الإضافة ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isUsernameValid = false;

  // --- 2. إضافة متغيرات الـ API ---
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  // --- نهاية التعديل ---

  bool _validateUsername(String value) {
    return value.isNotEmpty && !value.contains(' ');
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      if (mounted) {
        setState(() {
          _isUsernameValid = _validateUsername(_usernameController.text);
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 3. دالة للـ Validation والـ Submit (مربوطة بالـ API)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // إذا كانت الحقول غير صالحة، لا تكمل
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // استدعاء الخدمة
      final (String? token, String? errorMessage) = await _authService
          .loginParent(
            username: _usernameController.text,
            password: _passwordController.text,
          );

      // التعامل مع الرد
      if (token != null) {
        // --- نجاح ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الدخول بنجاح!',
              style: TextStyle(fontFamily: kFontFamily),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // الانتقال إلى الهوم (بتأثير التلاشي 700ms)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = 0.0;
                  const end = 1.0;
                  const curve = Curves.ease;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return FadeTransition(
                    opacity: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      } else {
        // --- خطأ من السيرفر ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage ?? 'بيانات الدخول غير صحيحة',
              style: TextStyle(fontFamily: kFontFamily),
            ),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      // --- خطأ غير متوقع ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
            style: TextStyle(fontFamily: kFontFamily),
          ),
          backgroundColor: kPrimaryColor,
        ),
      );
    } finally {
      // إخفاء التحميل (حتى لو فشل)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // --- تعديل: استخدام Column لتقسيم الشاشة (محتوى + أزرار) ---
        child: Column(
          children: [
            // --- 1. المحتوى القابل للـ Scroll ---
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
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
                            SizedBox(height: screenHeight * 0.03),
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
                            const Center(
                              child: Text(
                                'تسجيل الدخول',
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
                                'سجل الدخول لتستمر في رحلتك',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.04),
                            _buildLabel('اسم المستخدم *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              enabled: !_isLoading, // (تعطيل أثناء التحميل)
                              decoration: _buildInputDecoration(
                                hintText: 'اكتب اسم المستخدم بدون مسافات...',
                                suffixIcon: _usernameController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _usernameController.clear(),
                                      )
                                    : null,
                                borderColor: _isUsernameValid
                                    ? Colors.green
                                    : null,
                                focusedBorderColor: _isUsernameValid
                                    ? Colors.green
                                    : null,
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'اسم المستخدم مطلوب';
                                }
                                if (value.contains(' ')) {
                                  return 'اسم المستخدم لا يحتوي على مسافات';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('كلمة المرور *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              enabled: !_isLoading, // (تعطيل أثناء التحميل)
                              decoration: _buildInputDecoration(
                                hintText: 'كلمة المرور',
                                prefixIcon: IconButton(
                                  padding: const EdgeInsets.only(left: 15),
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'كلمة المرور مطلوبة';
                                }
                                // --- *** بداية التعديل المطلوب *** ---
                                // (إضافة التحقق من الطول قبل الإرسال للـ API)
                                if (value.length < 8) {
                                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                                }
                                // --- *** نهاية التعديل المطلوب *** ---
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        // (تعطيل أثناء التحميل)
                                        Navigator.push(
                                          context,
                                          FadePageRoute(
                                            child: const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                child: const Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- 2. الأزرار الثابتة في الأسفل ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // (إظهار التحميل أو الزر)
                  SizedBox(
                    height: 55,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryColor,
                            ),
                          )
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
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // (تعطيل أثناء التحميل)
                              Navigator.push(
                                context,
                                FadePageRoute(child: const SignUpScreen()),
                              );
                            },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(text: 'ليس لديك حساب؟ '),
                            TextSpan(
                              text: 'انشاء حساب جديد',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
