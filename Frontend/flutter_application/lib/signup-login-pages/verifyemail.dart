// --- verifyemail.dart (Updated with API Verification Logic) ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // (لإدخال الأرقام فقط)
import 'package:flutter_application/signup-login-pages/enternewpassword.dart';
import 'package:pinput/pinput.dart';

// --- تعديل: إضافة import لخدمة الـ API ---
import 'package:flutter_application/api/auth_service.dart';

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

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  String _otpCode = "";

  Timer? _timer;
  int _start = 30;
  bool _isTimerActive = false;

  // --- تعديل: إضافة متغيرات الـ API ---
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  // --- نهاية التعديل ---

  @override
  void initState() {
    super.initState();
    // startTimer(); // (يمكنك تفعيل هذا لبدء الـ Timer تلقائياً)
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  /// دالة لبدء الـ Timer (كما هي)
  void startTimer() {
    if (_isTimerActive) return;
    setState(() {
      _isTimerActive = true;
      _start = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          _isTimerActive = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  /// دالة إخفاء الإيميل (كما هي)
  String _maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final name = parts[0];
      final domain = parts[1];
      if (name.length <= 4) {
        return '${name.substring(0, 1)}****@$domain';
      }
      return '${name.substring(0, 3)}****@$domain';
    } catch (e) {
      return '****@****.com';
    }
  }

  // --- *** بداية التعديل المطلوب *** ---
  /// دالة لـ Submit الرمز (مربوطة بالـ API)
  Future<void> _submitCode() async {
    // 1. التحقق من أن الـ 6 أرقام تم إدخالها
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء ادخال الرمز المكون من 6 أرقام',
            style: TextStyle(fontFamily: kFontFamily),
          ),
          backgroundColor: kPrimaryColor,
        ),
      );
      return;
    }

    // 2. إظهار التحميل
    setState(() { _isLoading = true; });

    try {
      // 3. استدعاء الخدمة
      final (bool success, String message) = await _authService.verifyOtp(
        otpCode: _otpCode,
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
        
        // (الانتقال لصفحة "إعادة التعيين" وتمرير الرمز الناجح)
        Navigator.pushReplacement(
          context,
          FadePageRoute(
            child: EnterNewPasswordScreen(
              // (ملاحظة: سنقوم بتعديل الصفحة التالية لتستقبل الرمز فقط)
              otpCode: _otpCode, 
            ),
          ),
        );
      } else {
        // --- خطأ (الرمز غير صحيح) ---
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
          content: Text('حدث خطأ: $e', style: TextStyle(fontFamily: kFontFamily)),
          backgroundColor: kPrimaryColor,
        ),
      );
    } finally {
      // 5. إخفاء التحميل
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  // --- *** نهاية التعديل المطلوب *** ---


  @override
  Widget build(BuildContext context) {
    // (باقي كود الـ build كما هو)
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final Color mainRed = kPrimaryColor;
    final Color lightPink = kPrimaryColor.withOpacity(0.1);

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: kFontFamily,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                        child: Column(
                          children: [
                            // --- زر الرجوع (معطل أثناء التحميل) ---
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
                                  onPressed: _isLoading ? null : () {
                                    Navigator.pop(context);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),

                            // (الأيقونة والعناوين كما هي)
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: kPrimaryColor,
                              size: screenHeight * 0.15,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'تحقق من بريدك!',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'تم ارسال رمز التحقق على البريد الالكتروني',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _maskEmail(widget.email),
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.04),

                            // --- مربعات الـ 6 أرقام (OTP) ---
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Pinput(
                                length: 6,
                                controller: _pinController,
                                // --- تعديل: تعطيل الحقل أثناء التحميل ---
                                enabled: !_isLoading, 
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration:
                                      defaultPinTheme.decoration!.copyWith(
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                ),
                                submittedPinTheme: defaultPinTheme.copyWith(
                                  decoration:
                                      defaultPinTheme.decoration!.copyWith(
                                    border: Border.all(
                                        color: Colors.green, width: 2),
                                  ),
                                ),
                                validator: (s) {
                                  return s?.length == 6
                                      ? null
                                      : 'الرمز غير مكتمل';
                                },
                                onCompleted: (pin) {
                                  setState(() {
                                    _otpCode = pin;
                                  });
                                  print('Completed: $pin');
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'يرجى التحقق من وجود الرسالة\nفي inbox او في spam',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // --- 2. الأزرار الثابتة في الأسفل (مع لوجيك التحميل) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // --- زر "تأكيد" (Primary) ---
                  SizedBox(
                    height: 55, // (للحفاظ على الارتفاع)
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: kPrimaryColor))
                        : ElevatedButton(
                            onPressed: _submitCode, // (استدعاء دالة الـ API)
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'تأكيد الرمز',
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

                  // --- زر "اعادة الارسال" (Secondary) ---
                  // (تعطيل أثناء التحميل الرئيسي)
                  _isTimerActive
                      ? _buildTimerButton()
                      : _buildResendButton(isEnabled: !_isLoading),
                  
                  const SizedBox(height: 16),
                  _buildContactUsButton(isEnabled: !_isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ودجت زر "اعادة الارسال" (معدل ليدعم التعطيل)
  Widget _buildResendButton({bool isEnabled = true}) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? () { // (تفعيل/تعطيل)
        print('Resending code to ${widget.email}...');
        // (يفضل استدعاء API إعادة الإرسال هنا)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم اعادة ارسال الرمز يرجى التأكد من بريدك الإلكتروني',
              style: TextStyle(fontFamily: kFontFamily, color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        startTimer();
      } : null, // (تعطيل الزر)
      icon: const Icon(Icons.refresh, color: Colors.black),
      label: const Text(
        'اعادة ارسال الرمز',
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[100], // (لون التعطيل)
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: Colors.grey[400]!, width: 1.5),
        ),
        elevation: 0,
      ),
    );
  }

  /// ودجت زر "الـ Timer" (كما هو)
  Widget _buildTimerButton() {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.grey[600],
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 0,
      ),
      child: Text(
        'إعادة الارسال بعد ($_start) ثانية',
        style: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// ودجت زر "تواصل معنا" (معدل ليدعم التعطيل)
  Widget _buildContactUsButton({bool isEnabled = true}) {
    return TextButton(
      onPressed: isEnabled ? () { // (تفعيل/تعطيل)
        // --- لوجيك التواصل معنا ---
      } : null,
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 15,
            color: Colors.grey,
          ),
          children: [
            TextSpan(text: 'تواجه مشكلة ما؟ '),
            TextSpan(
              text: 'تواصل معنا',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}