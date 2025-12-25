// --- lib/profile/change_email_page.dart ---
// Change Email Page - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFBF092F);
const Color kOrange = Color(0xFFFE8401);
const String kFontFamily = 'IBM Plex Sans Arabic';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<ParentProfileProvider>(
        context,
        listen: false,
      );

      final (success, message) = await provider.updateProfile(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(fontFamily: kFontFamily),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ غير متوقع';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 48),

                        // Header with Icon and Title
                        _buildHeader(),

                        const SizedBox(height: 34),

                        // Error Message
                        if (_errorMessage != null) ...[
                          _buildErrorMessage(),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        _buildEmailField(),

                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: 10,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),

              // Save Button at Bottom
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      disabledBackgroundColor: kPrimaryColor.withOpacity(0.6),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Email Icon in Circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: kOrange.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.email,
            color: kOrange,
            size: 50,
          ),
        ),
        const SizedBox(height: 12),
        // Title
        const Text(
          'تغيير البريد الالكترونى',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kPrimaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: kFontFamily,
                color: kPrimaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with asterisk
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'البريد الالكترونى الجديد',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Input Field
        TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: kFontFamily),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'البريد الالكترونى مطلوب';
            }
            // Simple email validation
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'البريد الالكترونى غير صالح';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'اكتب البريد الالكترونى الجديد هنا...',
            hintStyle: TextStyle(
              fontFamily: kFontFamily,
              color: Colors.black.withOpacity(0.5),
              fontSize: 14,
            ),
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: kOrange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
