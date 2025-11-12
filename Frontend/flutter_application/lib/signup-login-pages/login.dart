// --- login.dart ---

import 'package:flutter/material.dart';
import 'package:flutter_application/homepage/homepage.dart';
import 'package:flutter_application/signup-login-pages/forgetpassword.dart';
import 'package:flutter_application/signup-login-pages/signup.dart';

// import 'package:ajial/signup_screen.dart'; // كمثال لصفحة التسجيل
// import 'package:ajial/home_screen.dart'; // كمثال للصفحة الرئيسية
// import 'package:ajial/forgot_password_screen.dart'; // كمثال لصفحة نسيت كلمة المرور

// --- Global Constants ---
// اللون الأساسي للمشروع
const Color kPrimaryColor = Color(0xFFBF092F);
// اسم الخط الأساسي
const String kFontFamily = 'IBM Plex Sans Arabic';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // مفتاح الفورم للـ Validation
  final _formKey = GlobalKey<FormState>();

  // Controllers لمتابعة النص في الحقول
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // متغير لإدارة إظهار/إخفاء كلمة المرور
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // التخلص من الـ Controllers
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// دالة للـ Validation والـ Submit
  void _submitForm() {
    // عمل validate للفورم
    if (_formKey.currentState!.validate()) {
      // --- هنا يتم إرسال البيانات للـ Backend للتحقق ---
      print('Form is valid and ready to login!');
      print('Username: ${_usernameController.text}');
      print('Password: ${_passwordController.text}');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('جاري تسجيل الدخول...')));

      // --- *** مكان الانتقال للصفحة الرئيسية بعد تسجيل الدخول *** ---
      // شيل الكومنت وحط اسم الصفحة اللي عاوز تروحها (زي HomeScreen مثلاً)

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
              // تفعيل الـ validation بمجرد الكتابة
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                // محاذاة كل شيء لليمين (العناوين)
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 40),
                  // --- اللوجو ---
                  Center(
                    child: Image.asset(
                      'images/main-logo.png', // لينك الصورة المؤقت
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.group,
                        size: 120,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 6),

                  // --- العناوين ---
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 40),

                  // --- حقل اسم المستخدم ---
                  _buildLabel('اسم المستخدم *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration(
                      hintText: 'اكتب اسم المستخدم بدون مسافات...',
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

                  // --- حقل كلمة المرور ---
                  _buildLabel('كلمة المرور *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText:
                        !_isPasswordVisible, // للتحكم في إظهار/إخفاء النص
                    decoration: _buildInputDecoration(
                      hintText: 'كلمة المرور',
                      // أيقونة العين (في البداية حسب التصميم)
                      prefixIcon: IconButton(
                        padding: EdgeInsets.only(left: 15),
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- رابط "نسيت كلمة المرور؟" ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // --- *** مكان الانتقال لصفحة نسيت كلمة المرور *** ---
                        // شيل الكومنت وحط اسم صفحة استعادة كلمة المرور

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );

                        print('Navigate to Forgot Password');
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
                  const SizedBox(height: 24),

                  // --- زر "تسجيل الدخول" ---
                  ElevatedButton(
                    onPressed: _submitForm, // دالة الـ Submit
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      minimumSize: const Size(double.infinity, 50), // عرض كامل
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
                  const SizedBox(height: 24),

                  // --- رابط "انشاء حساب جديد" ---
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // --- *** مكان الانتقال لصفحة انشاء حساب جديد *** ---
                        // شيل الكومنت وحط اسم صفحة التسجيل (SignUpScreen)

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );

                        print('Navigate to Sign Up Screen');
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
                  const SizedBox(height: 20),
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
