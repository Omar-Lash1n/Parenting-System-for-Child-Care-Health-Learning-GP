// --- enternewpassword.dart (Updated with Strength Logic) ---

import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/login.dart';
// import 'package:ajial/login_screen.dart'; // كمثال

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class EnterNewPasswordScreen extends StatefulWidget {
  const EnterNewPasswordScreen({Key? key}) : super(key: key);

  @override
  _EnterNewPasswordScreenState createState() => _EnterNewPasswordScreenState();
}

class _EnterNewPasswordScreenState extends State<EnterNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // متغيرات إظهار/إخفاء كلمة المرور
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // --- تعديل: إضافة متغيرات قوة كلمة المرور ---
  bool _has8Chars = false;
  bool _hasNumber = false;
  bool _hasSymbol = false; // هنستخدم نفس الرموز &*/
  double _passwordStrength = 0.0; // القيمة من 0.0 إلى 1.0
  // --- نهاية التعديل ---

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// دالة للـ Validation والـ Submit
  void _submitForm() {
    // التحقق من الفورم (أن الحقول مش فاضية + متطابقة)
    if (_formKey.currentState!.validate()) {
      // --- تعديل: التحقق من قوة كلمة المرور قبل الإرسال ---
      if (_has8Chars && _hasNumber && _hasSymbol) {
        // --- هنا يتم إرسال كلمة المرور الجديدة للـ Backend ---
        print('New password set: ${_passwordController.text}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تغيير كلمة المرور بنجاح!',
              style: TextStyle(fontFamily: kFontFamily),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // --- *** مكان الانتقال لصفحة (تسجيل الدخول) أو (الرئيسية) *** ---
        // شيل الكومنت وحط اسم الصفحة اللي عاوز تروحها

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false, // حذف كل الصفحات السابقة
        );
      } else {
        // --- لو كلمة المرور ضعيفة ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى اختيار كلمة مرور أقوى لاستكمال العملية',
              style: TextStyle(fontFamily: kFontFamily),
            ),
            backgroundColor: kPrimaryColor, // لون أحمر للخطأ
          ),
        );
      }
      // --- نهاية التعديل ---
    }
  }

  // --- تعديل: إضافة دالة تحديث قوة كلمة المرور ---
  /// دالة لتحديث مؤشر قوة كلمة المرور
  void _updatePasswordStrength(String password) {
    setState(() {
      _has8Chars = password.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      // الرموز المطلوبة (مثل &*/)
      _hasSymbol = RegExp(r'[&*/]').hasMatch(password);

      int conditionsMet = 0;
      if (_has8Chars) conditionsMet++;
      if (_hasNumber) conditionsMet++;
      if (_hasSymbol) conditionsMet++;

      // تحديث قيمة المؤشر (0, 0.33, 0.66, 1.0)
      _passwordStrength = conditionsMet / 3.0;
    });
  }
  // --- نهاية التعديل ---

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
                // محاذاة العناوين لليمين
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 40), // مسافة إضافية بدل السهم
                  // --- اللوجو ---
                  Center(
                    child: Image.network(
                      'https://via.placeholder.com/100x100.png?text=Ajial+Logo',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.group,
                        size: 80,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- العناوين ---
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 40),

                  // --- حقل كلمة المرور الجديدة ---
                  _buildLabel('كلمة المرور الجديدة *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    // --- تعديل: إضافة onChanged ---
                    onChanged: _updatePasswordStrength,
                    // --- نهاية التعديل ---
                    decoration: _buildInputDecoration(
                      hintText: 'كلمة المرور الجديدة',
                      prefixIcon: IconButton(
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
                      // هنا شيلنا التحقق من 8 حروف لإنه بقى مرئي للمستخدم
                      return null;
                    },
                  ),
                  // const SizedBox(height: 20), // --- تعديل: هنشيل دي ونحط الودجت بدالها

                  // --- تعديل: إضافة مؤشر قوة كلمة المرور (بدل الـ SizedBox) ---
                  if (_passwordController.text.isNotEmpty)
                    Padding(
                      // ضفنا Padding عشان نفصلها عن الحقل اللي تحتها
                      padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: Colors.grey[300],
                              color: _passwordStrength <= 0.33
                                  ? kPrimaryColor // أحمر
                                  : _passwordStrength <= 0.66
                                  ? Colors.yellow[700] // أصفر
                                  : Colors.green, // أخضر
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // --- شروط قوة كلمة المرور ---
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
                  // لو حقل الباسورد فاضي، حط مسافة بديلة
                  if (_passwordController.text.isEmpty)
                    const SizedBox(height: 20),
                  // --- نهاية التعديل ---

                  // --- حقل تأكيد كلمة المرور ---
                  _buildLabel('تأكيد كلمة المرور الجديدة *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: _buildInputDecoration(
                      hintText: 'تأكيد كلمة المرور الجديدة',
                      prefixIcon: IconButton(
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
                  const SizedBox(height: 40),

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

  // --- تعديل: إضافة ودجت التحقق من قوة كلمة المرور ---
  /// دالة لإنشاء عنصر في قائمة شروط قوة كلمة المرور
  Widget _buildStrengthCheck({required String text, required bool met}) {
    // تحديد اللون بناءً على الشرط (أخضر أو أحمر)
    final color = met ? Colors.green : kPrimaryColor; // kPrimaryColor (أحمر)
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // محاذاة لليمين
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
  // --- نهاية التعديل ---

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
