// --- lib/profile/change_password_page.dart ---
// Change Password Page - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFBF092F);
const Color kGreen = Color(0xFF01A449);
const String kFontFamily = 'IBM Plex Sans Arabic';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

      final (success, message) = await provider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
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
            backgroundColor: kGreen,
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

                        // Password Fields
                        _buildPasswordField(
                          label: 'كلمة المرور القديمة*',
                          controller: _currentPasswordController,
                          hint: 'كلمة المرور القديمة',
                          isVisible: _showCurrentPassword,
                          onToggle: () => setState(() =>
                              _showCurrentPassword = !_showCurrentPassword),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'كلمة المرور الحالية مطلوبة';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'كلمة المرور الجديدة*',
                          controller: _newPasswordController,
                          hint: 'كلمة المرور الجديدة',
                          isVisible: _showNewPassword,
                          onToggle: () => setState(
                              () => _showNewPassword = !_showNewPassword),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'كلمة المرور الجديدة مطلوبة';
                            }
                            if (value.length < 8) {
                              return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'تأكيد كلمة المرور الجديدة*',
                          controller: _confirmPasswordController,
                          hint: 'تأكيد كلمة المرور الجديدة',
                          isVisible: _showConfirmPassword,
                          onToggle: () => setState(() =>
                              _showConfirmPassword = !_showConfirmPassword),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'تأكيد كلمة المرور مطلوب';
                            }
                            if (value != _newPasswordController.text) {
                              return 'كلمتا المرور غير متطابقتين';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to forgot password
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ),

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
        // Key Icon in Circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.vpn_key,
            color: kGreen,
            size: 50,
          ),
        ),
        const SizedBox(height: 12),
        // Title
        const Text(
          'تغيير كلمة المرور',
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with asterisk
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label.replaceAll('*', ''),
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const TextSpan(
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
          controller: controller,
          obscureText: !isVisible,
          enabled: !_isLoading,
          validator: validator,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: kFontFamily),
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(color: kGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black.withOpacity(0.5),
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
