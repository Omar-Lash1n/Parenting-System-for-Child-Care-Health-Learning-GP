// --- verifyemail.dart (Refactored with Provider Pattern) ---

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:Ajial/providers/verify_email_provider.dart';

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

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

  @override
  void dispose() {
    _pinController.dispose();
    context.read<VerifyEmailProvider>().reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
        child: Consumer<VerifyEmailProvider>(
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
                            child: Column(
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

                                // --- Icon and Headers ---
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
                                  provider.maskEmail(widget.email),
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: screenHeight * 0.04),

                                // --- PIN Input ---
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Pinput(
                                    length: 6,
                                    controller: _pinController,
                                    enabled: !provider.isLoading,
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
                                      provider.setOtpCode(pin);
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
                
                // --- 2. Sticky Buttons at Bottom ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      // --- Confirm Button ---
                      SizedBox(
                        height: 55,
                        child: provider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: kPrimaryColor))
                            : ElevatedButton(
                                onPressed: () {
                                  provider.submitOtp(context: context);
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

                      // --- Resend Button ---
                      provider.isTimerActive
                          ? _buildTimerButton(provider)
                          : _buildResendButton(provider, isEnabled: !provider.isLoading),
                      
                      const SizedBox(height: 16),
                      _buildContactUsButton(isEnabled: !provider.isLoading),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResendButton(VerifyEmailProvider provider, {bool isEnabled = true}) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? () {
        print('Resending code to ${widget.email}...');
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
        provider.startTimer();
      } : null,
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
        disabledBackgroundColor: Colors.grey[100],
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: Colors.grey[400]!, width: 1.5),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildTimerButton(VerifyEmailProvider provider) {
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
        'إعادة الارسال بعد (${provider.timerStart}) ثانية',
        style: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContactUsButton({bool isEnabled = true}) {
    return TextButton(
      onPressed: isEnabled ? () {
        // Contact us logic
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