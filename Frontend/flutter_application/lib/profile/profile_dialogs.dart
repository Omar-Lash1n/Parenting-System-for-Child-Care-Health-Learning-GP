// --- lib/profile/profile_dialogs.dart ---
// Profile Edit Dialogs - UI Implementation (Phase 1)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static void showEditRoleDialog(
    BuildContext context,
    String currentValue,
    Function(String) onSave,
  ) {
    String selectedRole = currentValue;
    final roles = ['ولي أمر', 'أب', 'أم'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => _buildDialogContainer(
          context: context,
          title: 'تغيير الدور',
          icon: Icons.people,
          iconColor: kPrimaryColor,
          content: Column(
            children: roles
                .map((role) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = role),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedRole == role
                                ? kPrimaryColor.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: selectedRole == role
                                  ? kPrimaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              role,
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontWeight: selectedRole == role
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selectedRole == role
                                    ? kPrimaryColor
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          onSave: () {
            onSave(selectedRole);
            Navigator.pop(context);
          },
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
    final dayController = TextEditingController(text: '1990');
    final yearController = TextEditingController();

    String? selectedMonth;
    final months = [
      {'val': '01', 'label': 'يناير'},
      {'val': '02', 'label': 'فبراير'},
      {'val': '03', 'label': 'مارس'},
      {'val': '04', 'label': 'أبريل'},
      {'val': '05', 'label': 'مايو'},
      {'val': '06', 'label': 'يونيو'},
      {'val': '07', 'label': 'يوليو'},
      {'val': '08', 'label': 'أغسطس'},
      {'val': '09', 'label': 'سبتمبر'},
      {'val': '10', 'label': 'أكتوبر'},
      {'val': '11', 'label': 'نوفمبر'},
      {'val': '12', 'label': 'ديسمبر'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => _buildDialogContainer(
          context: context,
          title: 'تغيير تاريخ الميلاد',
          icon: Icons.cake,
          iconColor: kPrimaryColor,
          content: Row(
            children: [
              // Day
              Expanded(
                child: TextField(
                  controller: dayController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'يوم',
                    hintStyle: TextStyle(
                        fontFamily: kFontFamily, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Month dropdown
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMonth,
                      hint: Text('شهر',
                          style: TextStyle(
                              fontFamily: kFontFamily,
                              color: Colors.grey[400])),
                      isExpanded: true,
                      items: months
                          .map((m) => DropdownMenuItem(
                                value: m['val'],
                                child: Text(m['label']!,
                                    style: const TextStyle(
                                        fontFamily: kFontFamily)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedMonth = val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Year
              Expanded(
                child: TextField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'سنة',
                    hintStyle: TextStyle(
                        fontFamily: kFontFamily, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          onSave: () {
            final result =
                '${dayController.text}/${selectedMonth ?? '01'}/${yearController.text}';
            onSave(result);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // --- Edit City Dialog ---
  static void showEditCityDialog(
    BuildContext context,
    String currentValue,
    Function(String) onSave,
  ) {
    String selectedCity = currentValue;
    final cities = [
      'القاهرة',
      'الإسكندرية',
      'الجيزة',
      'الأقصر',
      'أسوان',
      'المنصورة',
      'طنطا'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => _buildDialogContainer(
          context: context,
          title: 'تغيير المدينة',
          icon: Icons.location_on,
          iconColor: kPrimaryColor,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(25),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCity,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: cities
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(city,
                              style: const TextStyle(fontFamily: kFontFamily)),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedCity = val ?? currentValue),
              ),
            ),
          ),
          onSave: () {
            onSave(selectedCity);
            Navigator.pop(context);
          },
        ),
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

    showDialog(
      context: context,
      builder: (ctx) => _buildDialogContainer(
        context: context,
        title: 'تغيير كلمة المرور',
        icon: Icons.vpn_key,
        iconColor: Colors.green,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordField('كلمة المرور القديمة *',
                currentPasswordController, 'اكتب كلمة المرور القديمة'),
            const SizedBox(height: 16),
            _buildPasswordField('كلمة المرور الجديدة *', newPasswordController,
                'اكتب كلمة المرور الجديدة'),
            const SizedBox(height: 16),
            _buildPasswordField('تأكيد كلمة المرور الجديدة *',
                confirmPasswordController, 'تأكيد كلمة المرور الجديدة'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to forgot password
                },
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    color: kPrimaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        onSave: () {
          // TODO: Validate and save
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم تغيير كلمة المرور بنجاح',
                    style: TextStyle(fontFamily: kFontFamily))),
          );
        },
      ),
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

  static Widget _buildPasswordField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label.replaceAll(' *', ''),
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              if (label.contains('*'))
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(fontFamily: kFontFamily, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            suffixIcon: const Icon(Icons.visibility_off, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
