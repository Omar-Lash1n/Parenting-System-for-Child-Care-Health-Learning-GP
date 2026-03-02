// --- login.dart (Refactored with Provider Pattern) ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/login_provider.dart';
import 'package:Ajial/signup-login-pages/forgetpassword.dart';
import 'package:Ajial/signup-login-pages/signup.dart';

// --- Global Constants ---
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers stay in widget for proper disposal
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Cache screen dimensions to avoid rebuilds on keyboard
  late double _screenHeight;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    // Set up listener for username validation
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache these once to avoid MediaQuery rebuilds on keyboard
    final size = MediaQuery.of(context).size;
    _screenHeight = size.height;
    _screenWidth = size.width;
  }

  void _onUsernameChanged() {
    // Use read since we're calling from a listener (not build)
    context.read<LoginProvider>().onUsernameChanged(_usernameController.text);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    // Reset provider state when leaving screen
    context.read<LoginProvider>().reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Note: resizeToAvoidBottomInset defaults to true
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<LoginProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // --- 1. Scrollable Content ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
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
                                  SizedBox(height: _screenHeight * 0.03),
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
                                  SizedBox(height: _screenHeight * 0.04),
                                  _buildLabel('اسم المستخدم *'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _usernameController,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    enabled: !provider.isLoading,
                                    decoration: _buildInputDecoration(
                                      hintText:
                                          'اكتب اسم المستخدم بدون مسافات...',
                                      suffixIcon: _usernameController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.grey,
                                              ),
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
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    obscureText: !provider.isPasswordVisible,
                                    enabled: !provider.isLoading,
                                    decoration: _buildInputDecoration(
                                      hintText: 'كلمة المرور',
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
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'كلمة المرور مطلوبة';
                                      }
                                      if (value.length < 8) {
                                        return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: provider.isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                FadePageRoute(
                                                  child:
                                                      const ForgotPasswordScreen(),
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

                  // --- 2. Sticky Buttons at Bottom ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 55,
                          child: provider.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: kPrimaryColor,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    provider.login(
                                      username: _usernameController.text,
                                      password: _passwordController.text,
                                      formKey: _formKey,
                                      context: context,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
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
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      FadePageRoute(
                                          child: const SignUpScreen()),
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
