// --- signup.dart ---

import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/login.dart';

// --- Global Constants ---
// اللون الأساسي للمشروع
const Color kPrimaryColor = Color(0xFFBF092F);
// اسم الخط الأساسي
const String kFontFamily = 'IBM Plex Sans Arabic';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // مفتاح الفورم للـ Validation
  final _formKey = GlobalKey<FormState>();

  // Controllers لمتابعة النص في الحقول
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // متغير لإدارة إظهار/إخفاء كلمة المرور
  bool _isPasswordVisible = false;

  // متغيرات لمتابعة حالة اسم المستخدم (عشان الحد الأخضر)
  bool _isUsernameValid = false;

  bool _isEmailValid = false;
  bool _isFullNameValid  = false;

  // متغيرات لمتابعة قوة كلمة المرور
  bool _has8Chars = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  double _passwordStrength = 0.0; // القيمة من 0.0 إلى 1.0

  @override
  void initState() {
    super.initState();
    // متابعة التغييرات في حقل الإيميل عشان نظهر/نخفي أيقونة المسح
    _emailController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // التخلص من الـ Controllers عشان منع تسريب الذاكرة
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// دالة لتحديث مؤشر قوة كلمة المرور
  void _updatePasswordStrength(String password) {
    setState(() {
      _has8Chars = password.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      // الرموز المطلوبة حسب الصورة (&*/)
      _hasSymbol = RegExp(r'[&*/]').hasMatch(password);

      int conditionsMet = 0;
      if (_has8Chars) conditionsMet++;
      if (_hasNumber) conditionsMet++;
      if (_hasSymbol) conditionsMet++;

      // تحديث قيمة المؤشر (0, 0.33, 0.66, 1.0)
      _passwordStrength = conditionsMet / 3.0;
    });
  }

  /// دالة للـ Validation والـ Submit
  void _submitForm() {
    // عمل validate للفورم
    if (_formKey.currentState!.validate()) {
      // التأكد من أن كلمة المرور قوية
      if (_has8Chars && _hasNumber && _hasSymbol) {
        // --- هنا يتم إرسال البيانات للـ Backend ---
        print('Form is valid and ready to submit!');
        print('Name: ${_nameController.text}');
        print('Username: ${_usernameController.text}');
        print('Email: ${_emailController.text}');
        print('Password: ${_passwordController.text}');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('جاري إنشاء الحساب...')));
      } else {
        // إظهار رسالة إذا كانت كلمة المرور ضعيفة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار كلمة مرور أقوى لاستكمال التسجيل'),
          ),
        );
      }
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
                  const SizedBox(height: 20),
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
                  // const SizedBox(height: 12),

                  // --- العناوين ---
                  const Center(
                    child: Text(
                      'أنشئ حسابك الجديد',
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
                  const SizedBox(height: 32),

                  // --- حقل الاسم كامل ---
                  _buildLabel('الاسم كامل *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                      hintText: 'اكتب اسمك هنا...',
                      // لون الحد يتغير للأحمر في حالة الخطأ
                     // --- تعديل: لوجيك الحد الأخضر ---
                      borderColor: _isFullNameValid ? Colors.green : null,
                      focusedBorderColor: _isFullNameValid
                          ? Colors.green
                          : kPrimaryColor,
                    ),
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الاسم الكامل مطلوب';
                      }
                      // Validation من الصورة الثانية (لا يحتوي على رموز)
                      if (RegExp(
                        r'[0-9!@#\$%^&*(),.?":{}|<>]',
                      ).hasMatch(value)) {
                        return 'يرجى ادخال اسم صحيح لا يحتوي على رموز';
                      }
                      return null;
                    },
                     
                  ),
                  const SizedBox(height: 20),

                  // --- حقل اسم المستخدم ---
                  _buildLabel('اسم المستخدم *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration(
                      hintText: 'اكتب اسم المستخدم بدون مسافات...',
                      // تحديد لون الحد بناءً على حالة الـ Validation
                      borderColor: _isUsernameValid ? Colors.green : null,
                      focusedBorderColor: _isUsernameValid
                          ? Colors.green
                          : kPrimaryColor,
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      // لوجيك بسيط لتحديد إذا كان اسم المستخدم صالح (لإظهار الحد الأخضر)
                      setState(() {
                        _isUsernameValid =
                            value.length > 4 && !value.contains(' ');
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اسم المستخدم مطلوب';
                      }
                      if (value.contains(' ')) {
                        return 'يجب ألا يحتوي على مسافات';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- حقل البريد الالكتروني ---
                  _buildLabel('البريد الالكتروني *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      hintText: 'اكتب بريدك الالكتروني هنا...',
                      // أيقونة المسح (X)
                      suffixIcon: _emailController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                _emailController.clear();
                              },
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
                      // Validation بسيط لصيغة الإيميل
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'صيغة بريد الكتروني غير صحيحة';
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
                      hintText: 'اكتب كلمة مرور لا تقل عن 8 حروف...',
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
                    onChanged:
                        _updatePasswordStrength, // تحديث قوة الباسورد مع كل حرف
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'كلمة المرور مطلوبة';
                      }
                      // الـ validation يتم عبر المؤشر البصري
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- مؤشر قوة كلمة المرور ---
                  if (_passwordController.text.isNotEmpty)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: Colors.grey[300],
                            // تحديد اللون بناءً على القوة
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
                  const SizedBox(height: 32),

                  // --- زر "التالي" ---
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'التالي',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        // السهم الخلفي (حسب التصميم)
                        Icon(Icons.arrow_back_outlined, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- رابط "تسجيل الدخول" ---
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // --- هنا يتم توجيه المستخدم لصفحة تسجيل الدخول ---
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
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
                            TextSpan(text: 'لديك حساب بالفعل؟ '),
                            TextSpan(
                              text: 'تسجيل الدخول',
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

  /// دالة لتوحيد شكل الـ InputDecoration
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorColor,
  }) {
    // لون الحد الافتراضي
    final defaultBorderColor = borderColor ?? Colors.grey[400]!;
    // لون الحد عند الـ focus
    final defaultFocusedBorderColor = focusedBorderColor ?? kPrimaryColor;
    // لون الحد عند الخطأ
    final defaultErrorBorderColor = errorColor ?? kPrimaryColor;

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontFamily: kFontFamily, color: Colors.grey),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      // محاذاة النص والـ hint لليمين
      hintTextDirection: TextDirection.rtl,
      // إخفاء الـ padding الافتراضي للأيقونات لضمان المحاذاة
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      // ملء الخلفية
      filled: true,
      fillColor: Colors.white,
      // --- ستايل الحدود ---
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
      // --- ستايل رسالة الخطأ ---
      errorStyle: const TextStyle(
        fontFamily: kFontFamily,
        color: kPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
