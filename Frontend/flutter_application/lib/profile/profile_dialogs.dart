// --- lib/profile/profile_dialogs.dart ---
// Profile Edit Dialogs - UI Implementation (Phase 1)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/api/auth_service.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class ProfileDialogs {
  // --- Edit Name Dialog ---
  static void showEditNameDialog(
    BuildContext context,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    _showEditDialog(
      context: context,
      title: 'تغيير الأسم',
      icon: Icons.edit,
      iconColor: kPrimaryColor,
      content: _buildTextField(controller, 'الاسم الكامل'),
      onSave: () {
        onSave(controller.text);
        Navigator.pop(context);
      },
    );
  }

  // --- Edit Username Dialog ---
  static void showEditUsernameDialog(
    BuildContext context,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    _showEditDialog(
      context: context,
      title: 'تغيير اسم المستخدم',
      icon: Icons.alternate_email,
      iconColor: kPrimaryColor,
      content: _buildTextField(controller, 'اسم المستخدم'),
      onSave: () {
        onSave(controller.text);
        Navigator.pop(context);
      },
    );
  }

  // --- Edit Role Dialog ---
  // Role codes: 1=أب (Father), 2=أم (Mother), 3=مربي (Educator)
  static void showEditRoleDialog(
    BuildContext context,
    int currentRoleCode,
    Function(int) onSave,
  ) {
    int selectedRoleCode = currentRoleCode;

    // Role options with their codes
    final roles = [
      {'code': 1, 'name': 'أب'},
      {'code': 2, 'name': 'أم'},
      {'code': 3, 'name': 'مربي'},
    ];

    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                      ),
                      const Text(
                        'تغيير الدور',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people,
                            color: kPrimaryColor, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: kPrimaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontFamily: kFontFamily,
                                color: kPrimaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Role options
                  ...roles
                      .map((roleData) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => setState(() => selectedRoleCode =
                                      roleData['code'] as int),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedRoleCode == roleData['code']
                                      ? kPrimaryColor.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: selectedRoleCode == roleData['code']
                                        ? kPrimaryColor
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    roleData['name'] as String,
                                    style: TextStyle(
                                      fontFamily: kFontFamily,
                                      fontWeight:
                                          selectedRoleCode == roleData['code']
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          selectedRoleCode == roleData['code']
                                              ? kPrimaryColor
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: kPrimaryColor),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              if (selectedRoleCode == currentRoleCode) {
                                Navigator.pop(context);
                                return;
                              }

                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              try {
                                final provider =
                                    Provider.of<ParentProfileProvider>(
                                  context,
                                  listen: false,
                                );

                                final (success, message) =
                                    await provider.updateProfile(
                                  role: selectedRoleCode,
                                );

                                if (!context.mounted) return;

                                if (success) {
                                  onSave(selectedRoleCode);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        message,
                                        style: const TextStyle(
                                            fontFamily: kFontFamily),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    isLoading = false;
                                    errorMessage = message;
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  isLoading = false;
                                  errorMessage = 'حدث خطأ غير متوقع';
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'حفظ',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
    );
  }

  // --- Edit Birthday Dialog ---
  static void showEditBirthdayDialog(
    BuildContext context,
    String currentValue,
    Function(String) onSave,
  ) {
    // Parse current date value (format: yyyy-MM-ddT00:00:00 or yyyy-MM-dd)
    DateTime initialDate = DateTime(1990, 1, 1);
    if (currentValue.isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentValue);
      } catch (e) {
        // If parsing fails, use default date
        initialDate = DateTime(1990, 1, 1);
      }
    }

    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                      ),
                      const Text(
                        'تغيير تاريخ الميلاد',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cake,
                            color: kPrimaryColor, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: kPrimaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontFamily: kFontFamily,
                                color: kPrimaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Selected Date Display
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(1920),
                              lastDate: DateTime.now(),
                              locale: const Locale('ar'),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: kPrimaryColor,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                initialDate = picked;
                              });
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.calendar_month,
                              color: kPrimaryColor),
                          Text(
                            '${initialDate.day}/${initialDate.month}/${initialDate.year}',
                            style: const TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'اضغط لاختيار التاريخ',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: kPrimaryColor),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              try {
                                // Format date as yyyy-MM-dd for API
                                final formattedDate =
                                    '${initialDate.year}-${initialDate.month.toString().padLeft(2, '0')}-${initialDate.day.toString().padLeft(2, '0')}';

                                final provider =
                                    Provider.of<ParentProfileProvider>(
                                  context,
                                  listen: false,
                                );

                                final (success, message) =
                                    await provider.updateProfile(
                                  dateOfBirth: formattedDate,
                                );

                                if (!context.mounted) return;

                                if (success) {
                                  onSave(formattedDate);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        message,
                                        style: const TextStyle(
                                            fontFamily: kFontFamily),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    isLoading = false;
                                    errorMessage = message;
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  isLoading = false;
                                  errorMessage = 'حدث خطأ غير متوقع';
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'حفظ',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
    );
  }

  // --- Edit City Dialog ---
  static void showEditCityDialog(
    BuildContext context,
    String currentValue,
    Function(int) onSave, // Changed to accept cityId
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CitySelectionDialog(
        currentCityName: currentValue,
        onSave: onSave,
      ),
    );
  }

  // --- Change Email Dialog ---
  static void showChangeEmailDialog(
    BuildContext context,
    String currentEmail,
    Function(String) onSave,
  ) {
    final controller = TextEditingController();
    _showEditDialog(
      context: context,
      title: 'تغيير البريد الإلكتروني',
      icon: Icons.email,
      iconColor: Colors.green,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'البريد الإلكتروني الجديد *',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(controller, 'اكتب البريد الإلكتروني الجديد هنا'),
        ],
      ),
      onSave: () {
        onSave(controller.text);
        Navigator.pop(context);
      },
    );
  }

  // --- Change Password Dialog ---
  static void showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed:
                                isLoading ? null : () => Navigator.pop(context),
                          ),
                          const Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.vpn_key,
                                color: Colors.green, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Error message
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: kPrimaryColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontFamily: kFontFamily,
                                    color: kPrimaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Current Password
                      _buildPasswordFieldWithVisibility(
                        label: 'كلمة المرور الحالية *',
                        controller: currentPasswordController,
                        hint: 'اكتب كلمة المرور الحالية',
                        isVisible: showCurrentPassword,
                        onToggle: () => setState(
                            () => showCurrentPassword = !showCurrentPassword),
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'كلمة المرور الحالية مطلوبة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      _buildPasswordFieldWithVisibility(
                        label: 'كلمة المرور الجديدة *',
                        controller: newPasswordController,
                        hint: 'اكتب كلمة المرور الجديدة',
                        isVisible: showNewPassword,
                        onToggle: () =>
                            setState(() => showNewPassword = !showNewPassword),
                        enabled: !isLoading,
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

                      // Confirm New Password
                      _buildPasswordFieldWithVisibility(
                        label: 'تأكيد كلمة المرور الجديدة *',
                        controller: confirmPasswordController,
                        hint: 'تأكيد كلمة المرور الجديدة',
                        isVisible: showConfirmPassword,
                        onToggle: () => setState(
                            () => showConfirmPassword = !showConfirmPassword),
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'تأكيد كلمة المرور مطلوب';
                          }
                          if (value != newPasswordController.text) {
                            return 'كلمتا المرور غير متطابقتين';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.green),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    final provider =
                                        Provider.of<ParentProfileProvider>(
                                      context,
                                      listen: false,
                                    );

                                    final (success, message) =
                                        await provider.changePassword(
                                      currentPassword:
                                          currentPasswordController.text,
                                      newPassword: newPasswordController.text,
                                      confirmNewPassword:
                                          confirmPasswordController.text,
                                    );

                                    if (!context.mounted) return;

                                    if (success) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            message,
                                            style: const TextStyle(
                                                fontFamily: kFontFamily),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        isLoading = false;
                                        errorMessage = message;
                                      });
                                    }
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                      errorMessage = 'حدث خطأ غير متوقع';
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'حفظ',
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
    );
  }

  // Helper for password field with visibility toggle
  static Widget _buildPasswordFieldWithVisibility({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required bool enabled,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          enabled: enabled,
          validator: validator,
          style: const TextStyle(fontFamily: kFontFamily),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: kFontFamily,
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // --- Delete Account Dialog ---
  static void showDeleteAccountDialog(BuildContext context) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _buildDialogContainer(
        context: context,
        title: 'حذف الحساب',
        icon: Icons.delete_forever,
        iconColor: kPrimaryColor,
        content: Column(
          children: [
            Text(
              'اكتب كلمة "حذف" لتأكيد العملية',
              style: TextStyle(
                fontFamily: kFontFamily,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(confirmController, 'حذف'),
          ],
        ),
        saveButtonText: 'حذف الحساب',
        saveButtonColor: kPrimaryColor,
        onSave: () {
          if (confirmController.text == 'حذف') {
            Navigator.pop(context);
            // TODO: Delete account logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('تم حذف الحساب',
                      style: TextStyle(fontFamily: kFontFamily))),
            );
          }
        },
        showCancelButton: true,
        footerText: 'واجهت مشكلة؟ تواصل معنا',
      ),
    );
  }

  static void showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.email, color: Colors.orange[700], size: 35),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'تأكيد الحساب',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: kFontFamily,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  'سنرسل لك رابط التفعيل على بريدك الإلكتروني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم إرسال رابط التفعيل',
                                    style: TextStyle(fontFamily: kFontFamily))),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'إرسال',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  static void _showEditDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _buildDialogContainer(
        context: context,
        title: title,
        icon: icon,
        iconColor: iconColor,
        content: content,
        onSave: onSave,
      ),
    );
  }

  static Widget _buildDialogContainer({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    required VoidCallback onSave,
    String saveButtonText = 'حفظ',
    Color? saveButtonColor,
    bool showCancelButton = false,
    String? footerText,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: kFontFamily,
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                content,
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: saveButtonColor ?? kPrimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: Text(
                      saveButtonText,
                      style: const TextStyle(
                        fontFamily: kFontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Cancel button (optional)
                if (showCancelButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],

                // Footer text (optional)
                if (footerText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    footerText,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: kFontFamily, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}

// --- City Selection Dialog Widget ---
class _CitySelectionDialog extends StatefulWidget {
  final String currentCityName;
  final Function(int) onSave;

  const _CitySelectionDialog({
    required this.currentCityName,
    required this.onSave,
  });

  @override
  State<_CitySelectionDialog> createState() => _CitySelectionDialogState();
}

class _CitySelectionDialogState extends State<_CitySelectionDialog> {
  List<City> cities = [];
  City? selectedCity;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final authService = AuthService();
      final loadedCities = await authService.getCities();

      if (mounted) {
        setState(() {
          cities = loadedCities;
          isLoading = false;

          // Try to find the current city by name
          if (widget.currentCityName.isNotEmpty) {
            selectedCity = cities.firstWhere(
              (city) =>
                  city.nameAr == widget.currentCityName ||
                  city.name == widget.currentCityName,
              orElse: () => cities.isNotEmpty
                  ? cities.first
                  : City(id: 0, name: '', nameAr: ''),
            );
          } else if (cities.isNotEmpty) {
            selectedCity = cities.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'حدث خطأ في تحميل المدن';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                  ),
                  const Text(
                    'تغيير المدينة',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on,
                        color: kPrimaryColor, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error message
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            color: kPrimaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Loading or content
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: kPrimaryColor),
                )
              else if (cities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد مدن متاحة',
                    style: TextStyle(fontFamily: kFontFamily),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<City>(
                      value: selectedCity,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: cities
                          .map((city) => DropdownMenuItem<City>(
                                value: city,
                                child: Text(
                                  city.nameAr,
                                  style:
                                      const TextStyle(fontFamily: kFontFamily),
                                ),
                              ))
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => selectedCity = val);
                              }
                            },
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: isSaving
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                    : ElevatedButton(
                        onPressed: cities.isEmpty || selectedCity == null
                            ? null
                            : () async {
                                setState(() {
                                  isSaving = true;
                                  errorMessage = null;
                                });

                                try {
                                  final provider =
                                      Provider.of<ParentProfileProvider>(
                                    context,
                                    listen: false,
                                  );

                                  final (success, message) =
                                      await provider.updateProfile(
                                    cityId: selectedCity!.id,
                                  );

                                  if (!context.mounted) return;

                                  if (success) {
                                    widget.onSave(selectedCity!.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          message,
                                          style: const TextStyle(
                                              fontFamily: kFontFamily),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      isSaving = false;
                                      errorMessage = message;
                                    });
                                  }
                                } catch (e) {
                                  setState(() {
                                    isSaving = false;
                                    errorMessage = 'حدث خطأ غير متوقع';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'حفظ',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
