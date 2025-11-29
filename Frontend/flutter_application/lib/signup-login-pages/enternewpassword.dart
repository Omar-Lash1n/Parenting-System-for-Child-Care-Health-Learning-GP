// --- enternewpassword.dart (Updated with API, Sticky Button & All Features) ---

import 'package:flutter/material.dart';
import 'package:Ajial/signup-login-pages/login.dart';

// --- تعديل: إضافة import لخدمة الـ API ---
import 'package:Ajial/api/auth_service.dart';

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

class EnterNewPasswordScreen extends StatefulWidget {
  // --- *** بداية التعديل المطلوب *** ---
  // (تم حذف الإيميل، الـ API لا يحتاجه)
  final String otpCode; // (الرمز الذي تم إدخاله في الصفحة السابقة)

  const EnterNewPasswordScreen({Key? key, required this.otpCode})
    : super(key: key);
  // --- *** نهاية التعديل المطلوب *** ---

  @override
  _EnterNewPasswordScreenState createState() => _EnterNewPasswordScreenState();
}

class _EnterNewPasswordScreenState extends State<EnterNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _has8Chars = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  double _passwordStrength = 0.0;
  bool _isConfirmValid = false;

  // --- تعديل: إضافة متغيرات الـ API ---
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  // --- نهاية التعديل ---

  // (دوال التحقق من التطابق كما هي)
  void _validateConfirmation() {
    if (mounted) {
      setState(() {
        _isConfirmValid =
            _confirmPasswordController.text == _passwordController.text &&
            _confirmPasswordController.text.isNotEmpty;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateConfirmation);
    _confirmPasswordController.addListener(_validateConfirmation);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validateConfirmation);
    _confirmPasswordController.removeListener(_validateConfirmation);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// دالة للـ Validation والـ Submit (تم تعديلها بالكامل)
  Future<void> _submitForm() async {
    // 1. التحقق من الحقول الحالية (التطابق وقوة كلمة المرور)
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!(_has8Chars && _hasNumber && _hasSymbol)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار كلمة مرور أقوى لاستكمال العملية',
            style: TextStyle(fontFamily: kFontFamily),
          ),
          backgroundColor: kPrimaryColor,
        ),
      );
      return;
    }

    // 2. إظهار التحميل
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. استدعاء الخدمة (Service)
      final (bool success, String message) = await _authService.resetPassword(
        token: widget.otpCode, // (تمرير الرمز من الصفحة السابقة)
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      // 4. التعامل مع الرد
      if (success) {
        // --- نجاح ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: TextStyle(fontFamily: kFontFamily)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(child: const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // --- خطأ من السيرفر (مثل: الرمز غلط) ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: TextStyle(fontFamily: kFontFamily)),
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
      // 5. إخفاء التحميل
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// دالة تحديث قوة كلمة المرور (كما هي)
  void _updatePasswordStrength(String password) {
    setState(() {
      _has8Chars = password.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSymbol = RegExp(r'[&*/]').hasMatch(password);
      int conditionsMet = 0;
      if (_has8Chars) conditionsMet++;
      if (_hasNumber) conditionsMet++;
      if (_hasSymbol) conditionsMet++;
      _passwordStrength = conditionsMet / 3.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // (باقي كود الـ build كما هو، مع إضافة تعطيل للحقول والأزرار أثناء التحميل)
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'اعادة تعيين كلمة المرور',
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
                                'يرجى كتابة كلمة مرور قوية وسهلة التذكر',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.04),
                            _buildLabel('كلمة المرور الجديدة *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              enabled: !_isLoading, // (تعطيل أثناء التحميل)
                              onChanged: (value) {
                                _updatePasswordStrength(value);
                                _validateConfirmation();
                              },
                              decoration: _buildInputDecoration(
                                hintText: 'كلمة المرور الجديدة',
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
                                return null;
                              },
                            ),
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 12.0,
                                  bottom: 20.0,
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        backgroundColor: Colors.grey[300],
                                        color: _passwordStrength <= 0.33
                                            ? kPrimaryColor
                                            : _passwordStrength <= 0.66
                                            ? Colors.yellow[700]
                                            : Colors.green,
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStrengthCheck(
                                      text: 'يحتوي على 8 احرف',
                                      met: _has8Chars,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildStrengthCheck(
                                      text: 'يحتوي على رموز &*/',
                                      met: _hasSymbol,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildStrengthCheck(
                                      text: 'يحتوي على ارقام',
                                      met: _hasNumber,
                                    ),
                                  ],
                                ),
                              ),
                            if (_passwordController.text.isEmpty)
                              const SizedBox(height: 20),
                            _buildLabel('تأكيد كلمة المرور الجديدة *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              enabled: !_isLoading, // (تعطيل أثناء التحميل)
                              decoration: _buildInputDecoration(
                                hintText: 'تأكيد كلمة المرور الجديدة',
                                prefixIcon: IconButton(
                                  padding: const EdgeInsets.only(left: 15),
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                borderColor: _isConfirmValid
                                    ? Colors.green
                                    : null,
                                focusedBorderColor: _isConfirmValid
                                    ? Colors.green
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'تأكيد كلمة المرور مطلوب';
                                }
                                if (value != _passwordController.text) {
                                  return 'كلمتا المرور غير متطابقتين';
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
              child: SizedBox(
                height: 55, // (الحفاظ على الارتفاع)
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                    : ElevatedButton(
                        onPressed: _submitForm, // (استدعاء دالة الـ API)
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

  // (باقي دوال المساعدة كما هي)
  Widget _buildStrengthCheck({required String text, required bool met}) {
    final color = met ? Colors.green : kPrimaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: TextStyle(fontFamily: kFontFamily, fontSize: 14, color: color),
        ),
        const SizedBox(width: 8),
        Icon(
          met ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: color,
          size: 18,
        ),
      ],
    );
  }

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

//ان شاء الله اضافة رمز * بعد النص
// وان شاء الله اضافة زر مثبت في الاسفل
// وان شاء الله جعل حدود التركيز سوداء بدل الاحمر
// وان شاء الله جعل لون مؤشر قوة كلمة المرور اخضر اصفر احمر
// وان شاء الله جعل زر التاكيد في الاسفل بعرض الشاشة بالكامل مع حواف دائرية
// وان شاء الله جعل الصفحة تدعم التابلت عن طريق تحديد اقصى عرض للمحتوى
// وان شاء الله جعل الصفحة قابلة للتمرير عند تصغير الشاشة
// وان شاء الله جعل زر التاكيد في اسفل الصفحة مثبت عند التمرير
// وان شاء الله جعل الخط الافتراضي في التطبيق بالكامل هو IBM Plex Sans Arabic
// وان شاء الله جعل لون زر التاكيد هو اللون الاساسي للتطبيق
// وان شاء الله جعل رسالة نجاح تغيير كلمة المرور تظهر باللون الاخضر
// وان شاء الله جعل رسالة ضعف كلمة المرور تظهر بلون اللون الاساسي للتطبيق
