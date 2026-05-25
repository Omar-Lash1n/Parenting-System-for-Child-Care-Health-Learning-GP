// --- signup.dart (Refactored with Provider Pattern) ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/signup_provider.dart';
import 'package:Ajial/signup-login-pages/continuesignup.dart';
import 'package:Ajial/signup-login-pages/login.dart';

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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers stay in widget for proper disposal
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Cache screen dimensions to avoid rebuilds on keyboard
  late double _screenHeight;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    // Set up listeners for field validation
    _nameController.addListener(_onNameChanged);
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _screenHeight = size.height;
    _screenWidth = size.width;
  }

  void _onNameChanged() {
    context.read<SignupProvider>().onFullNameChanged(_nameController.text);
    setState(() {}); // For clear button visibility
  }

  void _onUsernameChanged() {
    context.read<SignupProvider>().onUsernameChanged(_usernameController.text);
    setState(() {}); // For clear button visibility
  }

  void _onEmailChanged() {
    context.read<SignupProvider>().onEmailChanged(_emailController.text);
    setState(() {}); // For clear button visibility
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Reset provider state when leaving screen
    context.read<SignupProvider>().reset();
    super.dispose();
  }

  void _submitForm() {
    final provider = context.read<SignupProvider>();

    if (_formKey.currentState!.validate()) {
      if (provider.isPasswordStrong()) {
        print('Form is valid and ready to submit!');

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DataEntryPage(
              fullName: _nameController.text,
              username: _usernameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = 0.0;
              const end = 1.0;
              const curve = Curves.ease;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                opacity: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<SignupProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // --- 1. Scrollable Content ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 600,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _screenWidth > 600 ? 40.0 : 24.0,
                              vertical: 20.0,
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: _screenHeight * 0.02),

                                  // --- Logo ---
                                  Center(
                                    child: Image.asset(
                                      'images/main-logo.png',
                                      width: _screenHeight * 0.15,
                                      height: _screenHeight * 0.15,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.group,
                                        size: _screenHeight * 0.15,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ),

                                  // --- Headers ---
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
                                  SizedBox(height: _screenHeight * 0.04),

                                  // --- Full Name Field ---
                                  _buildLabel('الاسم كامل *'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    decoration: _buildInputDecoration(
                                      hintText: 'اكتب اسمك الكامل (الأول والأخير)...',
                                      suffixIcon:
                                          _nameController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.grey),
                                                  onPressed: () =>
                                                      _nameController.clear(),
                                                )
                                              : null,
                                      borderColor: provider.isFullNameValid
                                          ? Colors.green
                                          : null,
                                      focusedBorderColor:
                                          provider.isFullNameValid
                                              ? Colors.green
                                              : null,
                                    ),
                                    keyboardType: TextInputType.name,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'الاسم الكامل مطلوب';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                                      }
                                      if (value.trim().length > 100) {
                                        return 'الاسم يجب ألا يتجاوز 100 حرف';
                                      }
                                      if (value != value.trim()) {
                                        return 'يجب ألا يحتوي على مسافات في البداية أو النهاية';
                                      }
                                      if (!provider.validateName(value)) {
                                        return 'يجب أن يحتوي على أحرف ومسافات فقط بدون أرقام أو رموز';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // --- Username Field ---
                                  _buildLabel('اسم المستخدم *'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _usernameController,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.right,
                                    decoration: _buildInputDecoration(
                                      hintText:
                                          'اكتب اسم المستخدم (3-50 حرف)...',
                                      suffixIcon: _usernameController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.grey),
                                              onPressed: () =>
                                                  _usernameController.clear(),
                                            )
                                          : null,
                                      borderColor: provider.isUsernameValid
                                          ? Colors.green
                                          : null,
                                      focusedBorderColor:
                                          provider.isUsernameValid
                                              ? Colors.green
                                              : null,
                                    ),
                                    keyboardType: TextInputType.text,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'اسم المستخدم مطلوب';
                                      }
                                      if (value.contains(' ')) {
                                        return 'يجب ألا يحتوي على مسافات';
                                      }
                                      if (value.length < 3) {
                                        return 'يجب أن يكون 3 أحرف على الأقل';
                                      }
                                      if (value.length > 50) {
                                        return 'يجب ألا يتجاوز 50 حرف';
                                      }
                                      if (!provider.validateUsername(value)) {
                                        return 'يجب أن يحتوي فقط على أحرف وأرقام وشرطة سفلية (_)';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // --- Email Field ---
                                  _buildLabel('البريد الالكتروني *'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    decoration: _buildInputDecoration(
                                      hintText: 'اكتب بريدك الالكتروني هنا...',
                                      suffixIcon:
                                          _emailController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.grey),
                                                  onPressed: () {
                                                    _emailController.clear();
                                                  },
                                                )
                                              : null,
                                      borderColor: provider.isEmailValid
                                          ? Colors.green
                                          : null,
                                      focusedBorderColor: provider.isEmailValid
                                          ? Colors.green
                                          : null,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'البريد الالكتروني مطلوب';
                                      }
                                      if (value.length > 100) {
                                        return 'البريد الالكتروني يجب ألا يتجاوز 100 حرف';
                                      }
                                      if (!provider.validateEmail(value)) {
                                        return 'صيغة بريد الكتروني غير صحيحة';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // --- Password Field ---
                                  _buildLabel('كلمة المرور *'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    obscureText: !provider.isPasswordVisible,
                                    decoration: _buildInputDecoration(
                                      hintText:
                                          'اكتب كلمة مرور لا تقل عن 8 حروف...',
                                      suffixIcon: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12),
                                        child: IconButton(
                                          icon: Icon(
                                            provider.isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed:
                                              provider.togglePasswordVisibility,
                                        ),
                                      ),
                                    ),
                                    onChanged: provider.updatePasswordStrength,
                                    validator: provider.validatePassword,
                                  ),
                                  const SizedBox(height: 12),

                                  // --- Password Strength Indicator ---
                                  if (_passwordController.text.isNotEmpty)
                                    Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: provider.passwordStrength,
                                            backgroundColor: Colors.grey[300],
                                            color: provider.passwordStrength <=
                                                    0.25
                                                ? kPrimaryColor
                                                : provider.passwordStrength <=
                                                        0.5
                                                    ? Colors.orange
                                                    : provider.passwordStrength <=
                                                            0.75
                                                        ? Colors.yellow[700]
                                                        : Colors.green,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildStrengthCheck(
                                            text: 'يحتوي على 8 أحرف على الأقل',
                                            met: provider.has8Chars),
                                        const SizedBox(height: 4),
                                        _buildStrengthCheck(
                                            text: 'يحتوي على حرف كبير (A-Z)',
                                            met: provider.hasUppercase),
                                        const SizedBox(height: 4),
                                        _buildStrengthCheck(
                                            text: 'يحتوي على حرف صغير (a-z)',
                                            met: provider.hasLowercase),
                                        const SizedBox(height: 4),
                                        _buildStrengthCheck(
                                            text: 'يحتوي على أرقام (0-9)',
                                            met: provider.hasNumber),
                                        const SizedBox(height: 4),
                                        _buildStrengthCheck(
                                            text: 'يحتوي على رموز خاصة (@!%*?&#)',
                                            met: provider.hasSymbol),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- 2. Sticky Buttons at Bottom ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      children: [
                        // --- Next Button ---
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
                              Icon(Icons.arrow_back_outlined,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Login Link ---
                        Center(
                          child: TextButton(
                            onPressed: () {
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
              );
            },
          ),
        ),
      ),
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
      contentPadding: const EdgeInsetsDirectional.only(
          start: 20, end: 16, top: 16, bottom: 16),
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
