// --- forgetpassword.dart (Refactored with Provider Pattern) ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/forgot_password_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    context.read<ForgotPasswordProvider>().onEmailChanged(_emailController.text);
    setState(() {}); // For clear button visibility
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    context.read<ForgotPasswordProvider>().reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final Color lightPink = kPrimaryColor.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ForgotPasswordProvider>(
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
                            horizontal: screenWidth > 600 ? 40.0 : 24.0,
                            vertical: 20.0,
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // --- Back Button ---
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
                                      onPressed: provider.isLoading ? null : () {
                                        Navigator.pop(context);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),

                                // --- Logo ---
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

                                // --- Headers ---
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

                                // --- Email Field ---
                                _buildLabel('البريد الالكتروني *'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !provider.isLoading,
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
                                        provider.isEmailValid ? Colors.green : null,
                                    focusedBorderColor:
                                        provider.isEmailValid ? Colors.green : null,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'البريد الالكتروني مطلوب';
                                    }
                                    if (!provider.validateEmail(value)) {
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
                
                // --- 2. Sticky Button at Bottom ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: SizedBox(
                    height: 55,
                    child: provider.isLoading 
                      ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                      : ElevatedButton(
                        onPressed: () {
                          provider.submitForgotPassword(
                            email: _emailController.text,
                            formKey: _formKey,
                            context: context,
                          );
                        },
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
            );
          },
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