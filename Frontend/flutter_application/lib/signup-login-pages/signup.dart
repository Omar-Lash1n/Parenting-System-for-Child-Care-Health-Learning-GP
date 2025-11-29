// --- signup.dart (Updated with Fade Transition & Sticky Buttons) ---

import 'package:flutter/material.dart';
import 'package:Ajial/signup-login-pages/continuesignup.dart';
import 'package:Ajial/signup-login-pages/login.dart';

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

// --- تعديل: إضافة كلاس مساعد لتأثير التلاشي (للانتقالات الأخرى) ---
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
          transitionDuration: const Duration(milliseconds: 300), // سرعة تلاشي عادية
        );
}
// --- نهاية الإضافة ---

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  bool _isFullNameValid = false;
  bool _isUsernameValid = false;
  bool _isEmailValid = false;

  bool _has8Chars = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  double _passwordStrength = 0.0;

  bool _validateName(String value) {
    if (value.isEmpty) return false;
    return !RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(value);
  }

  bool _validateUsername(String value) {
    return value.length > 4 && !value.contains(' ');
  }

  bool _validateEmail(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (mounted) {
        setState(() {
          _isFullNameValid = _validateName(_nameController.text);
        });
      }
    });
    _usernameController.addListener(() {
      if (mounted) {
        setState(() {
          _isUsernameValid = _validateUsername(_usernameController.text);
        });
      }
    });
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
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  /// دالة للـ Validation والـ Submit
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_has8Chars && _hasNumber && _hasSymbol) {
        print('Form is valid and ready to submit!');
        
      // --- *** بداية التعديل المطلوب *** ---
    Navigator.push( 
      context,
      PageRouteBuilder(
        // 1. تمرير البيانات التي جمعناها هنا
        pageBuilder: (context, animation, secondaryAnimation) =>
            DataEntryPage(
          fullName: _nameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),

        // (الحفاظ على تأثير التلاشي كما طلبت)
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.ease;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
    // --- *** نهاية التعديل المطلوب *** ---

      } else {
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
                            SizedBox(height: screenHeight * 0.02),

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

                            // --- العناوين (كما هي) ---
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
                            SizedBox(height: screenHeight * 0.04),

                            // --- حقل الاسم كامل ---
                            _buildLabel('الاسم كامل *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildInputDecoration(
                                hintText: 'اكتب اسمك هنا...',
                                suffixIcon: _nameController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _nameController.clear(),
                                      )
                                    : null,
                                borderColor:
                                    _isFullNameValid ? Colors.green : null,
                                focusedBorderColor:
                                    _isFullNameValid ? Colors.green : null,
                              ),
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الاسم الكامل مطلوب';
                                }
                                if (!_validateName(value)) {
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
                                suffixIcon: _usernameController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _usernameController.clear(),
                                      )
                                    : null,
                                borderColor:
                                    _isUsernameValid ? Colors.green : null,
                                focusedBorderColor:
                                    _isUsernameValid ? Colors.green : null,
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'اسم المستخدم مطلوب';
                                }
                                if (value.contains(' ')) {
                                  return 'يجب ألا يحتوي على مسافات';
                                }
                                if (!_validateUsername(value)) {
                                  return 'يجب أن يكون أكثر من 4 حروف';
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
                                suffixIcon: _emailController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        onPressed: () {
                                          _emailController.clear();
                                        },
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
                            const SizedBox(height: 20),

                            // --- حقل كلمة المرور (كما هو) ---
                            _buildLabel('كلمة المرور *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: _buildInputDecoration(
                                hintText: 'اكتب كلمة مرور لا تقل عن 8 حروف...',
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
                              onChanged: _updatePasswordStrength,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'كلمة المرور مطلوبة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // --- مؤشر قوة كلمة المرور (كما هو) ---
                            if (_passwordController.text.isNotEmpty)
                              Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
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
                                      met: _has8Chars),
                                  const SizedBox(height: 4),
                                  _buildStrengthCheck(
                                      text: 'يحتوي على رموز &*/',
                                      met: _hasSymbol),
                                  const SizedBox(height: 4),
                                  _buildStrengthCheck(
                                      text: 'يحتوي على ارقام',
                                      met: _hasNumber),
                                ],
                              ),
                            // --- تعديل: تم حذف المسافة الكبيرة من هنا ---
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
                  // --- زر "التالي" ---
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
                        Icon(Icons.arrow_back_outlined, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- رابط "تسجيل الدخول" ---
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // --- تعديل: استخدام FadePageRoute للانتقال ---
                        Navigator.push(
                          context,
                          FadePageRoute(child: const LoginScreen()),
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

  /// (دالة _buildStrengthCheck كما هي)
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