// --- lib/profile/delete_account_page.dart ---
// Delete Account Page - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/signup-login-pages/login.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _isDeleteEnabled => _confirmationController.text.trim() == 'حذف';

  Future<void> _handleDelete() async {
    if (!_isDeleteEnabled) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<ParentProfileProvider>(
        context,
        listen: false,
      );

      final (success, message) = await provider.deleteAccount(
        _confirmationController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Navigate to login and clear all routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
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

                      // Confirmation Field
                      _buildConfirmationField(),

                      const SizedBox(height: 200), // Space for bottom buttons
                    ],
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

              // Bottom Buttons
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isDeleteEnabled
                            ? null
                            : _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          disabledBackgroundColor:
                              kPrimaryColor.withOpacity(0.4),
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
                                'حذف الحساب',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side:
                              BorderSide(color: Colors.black.withOpacity(0.25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'الغاء',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contact Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to contact/support page
                          },
                          child: const Text(
                            'تواصل معنا',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                        const Text(
                          ' تواجه مشكلة ما؟',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
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
        // Trash Icon in Circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline,
            color: kPrimaryColor,
            size: 50,
          ),
        ),
        const SizedBox(height: 12),
        // Title
        const Text(
          'حذف الحساب',
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

  Widget _buildConfirmationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with instruction
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'اكتب كلمة ',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'حذف',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryColor,
                ),
              ),
              TextSpan(
                text: ' هنا لتأكيد العملية',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Input Field
        TextField(
          controller: _confirmationController,
          enabled: !_isLoading,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: kFontFamily),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'حذف',
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
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
