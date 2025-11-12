// --- verifyemail.dart ---

import 'dart:async'; // ضروري عشان الـ Timer
import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/enternewpassword.dart';
import 'package:pinput/pinput.dart'; // لجلب مربعات الـ OTP
// import 'package:ajial/forgetpassword.dart'; // كمثال

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class VerifyEmailScreen extends StatefulWidget {
  // الصفحة دي محتاجة الإيميل عشان تعرضه
  final String email;

  const VerifyEmailScreen({
    Key? key,
    // هنفترض إن الإيميل بيجيلها من الصفحة اللي قبلها
    required this.email,
  }) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  String _otpCode = ""; // لتخزين الرمز المدخل

  // --- متغيرات الـ Timer ---
  Timer? _timer;
  int _start = 30; // مدة الـ Timer بالثواني
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    // (اختياري) ممكن تبدأ الـ Timer أول ما الصفحة تفتح لو حابب
    // startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // ضروري نلغي الـ Timer عشان منع تسريب الذاكرة
    _pinController.dispose();
    super.dispose();
  }

  /// دالة لبدء الـ Timer
  void startTimer() {
    if (_isTimerActive) return; // منع تشغيل أكتر من Timer

    setState(() {
      _isTimerActive = true;
      _start = 30; // إعادة تعيين العداد
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

  /// دالة لإخفاء الإيميل (للعرض فقط)
  String _maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email; // لو الإيميل مش مظبوط

      final name = parts[0];
      final domain = parts[1];

      if (name.length <= 4) {
        return '${name.substring(0, 1)}****@$domain';
      }
      return '${name.substring(0, 3)}****@$domain';
    } catch (e) {
      return '****@****.com'; // في حالة أي خطأ
    }
  }

  /// دالة لـ Submit الرمز
  void _submitCode() {
    // التحقق من أن الـ 6 أرقام تم إدخالها
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

    // --- هنا يتم إرسال الرمز (_otpCode) للـ Backend للتحقق ---
    print('Verifying code: $_otpCode');

    // --- *** مكان الانتقال لصفحة "ادخال كلمة المرور الجديدة" *** ---
    // شيل الكومنت وحط اسم الصفحة اللي عاوز تروحها
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EnterNewPasswordScreen()),
    );
    

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم التحقق بنجاح!',
          style: TextStyle(fontFamily: kFontFamily),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- ستايل مربعات الـ Pinput ---
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
    // --- نهاية الستايل ---

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
              child: Column(
                children: [
                  // --- زر "X" للرجوع ---
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        // --- لوجيك الرجوع للصفحة السابقة ---
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- الأيقونة (استخدمت أيقونة جاهزة) ---
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: kPrimaryColor,
                    size: 100,
                  ),
                  const SizedBox(height: 24),

                  // --- العناوين (تم تعديلها) ---
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
                    _maskEmail(widget.email), // عرض الإيميل المخفي
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- مربعات الـ 6 أرقام (OTP) ---
                  Directionality(
                    textDirection: TextDirection.ltr, // عشان الأرقام تظهر LTR
                    child: Pinput(
                      length: 6,
                      controller: _pinController,
                      defaultPinTheme: defaultPinTheme,
                      // ستايل المربع وهو Focused
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: kPrimaryColor, width: 2),
                        ),
                      ),
                      // ستايل المربع بعد الإدخال
                      submittedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                      ),
                      validator: (s) {
                        return s?.length == 6 ? null : 'الرمز غير مكتمل';
                      },
                      onCompleted: (pin) {
                        setState(() {
                          _otpCode = pin; // تخزين الرمز
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
                  const SizedBox(height: 32),

                  // --- زر "تأكيد" (Primary) ---
                  ElevatedButton(
                    onPressed: _submitCode, // دالة الـ Submit
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
                  const SizedBox(height: 16),

                  // --- زر "اعادة الارسال" (Secondary) ---
                  // هيعرض الزر العادي أو زر الـ Timer
                  _isTimerActive ? _buildTimerButton() : _buildResendButton(),

                  const SizedBox(height: 16),

                  // --- رابط "تواصل معنا" ---
                  TextButton(
                    onPressed: () {
                      // --- لوجيك التواصل معنا ---
                    },
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ودجت زر "اعادة الارسال" (الافتراضي)
  Widget _buildResendButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // --- هنا يتم طلب إرسال الرمز مرة أخرى من الـ Backend ---
        print('Resending code to ${widget.email}...');
        // --- *** بداية التعديل المطلوب *** ---
        // إظهار الـ SnackBar لتأكيد الإرسال
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم اعادة ارسال الرمز يرجى التأكد من بريدك الإلكتروني',
              style: TextStyle(fontFamily: kFontFamily, color: Colors.white),
            ),
            backgroundColor: Colors.green, // لون أخضر للنجاح
            behavior: SnackBarBehavior.floating, // يجعله يطفو فوق (شكل أشيك)
            duration: Duration(seconds: 3),
          ),
        );
        // --- *** نهاية التعديل المطلوب *** ---
        startTimer(); // بدء الـ Timer
      },
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
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: Colors.grey[400]!, width: 1.5), // حد رمادي
        ),
        elevation: 0, // بدون ظل
      ),
    );
  }

  /// ودجت زر "الـ Timer" (الرمادي)
  Widget _buildTimerButton() {
    return ElevatedButton(
      onPressed: null, // تعطيل الزر
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
}
