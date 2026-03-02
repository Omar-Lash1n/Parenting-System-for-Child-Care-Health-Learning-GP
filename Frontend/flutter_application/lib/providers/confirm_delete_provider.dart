// --- lib/providers/confirm_delete_provider.dart ---
// Provider for Confirm Delete Child Screen

import 'package:flutter/material.dart';

/// All Arabic strings for the confirm-delete flow
class ConfirmDeleteStrings {
  // Popup
  static const String popupTitle = 'حذف نهائى لملف انس';
  static const String popupSubtitle =
      'سيتم مسح جميع بيانات الطفل و لايمكن استعادتها مرة اخرى';
  static const String popupOkay = 'استمرار';
  static const String popupCancel = 'رجوع';

  // Confirm Delete Screen
  static String screenTitle(String name) => 'حذف ملف $name';
  static const String inputLabel = 'اكتب كلمة حذف هنا لتاكيد العملية';
  static const String inputHint = 'اسم المستخدم';
  static const String confirmWord = 'حذف';
  static const String deleteButton = 'زر اساسى';
  static const String skipButton = 'تخطى';
  static const String footerText = 'تواجه مشكلة ما؟ تواصل معنا';
}

class ConfirmDeleteProvider extends ChangeNotifier {
  final TextEditingController inputController = TextEditingController();
  String _inputText = '';

  ConfirmDeleteProvider() {
    inputController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _inputText = inputController.text;
    notifyListeners();
  }

  /// True only when user typed the confirmation word
  bool get isDeleteEnabled =>
      _inputText.trim() == ConfirmDeleteStrings.confirmWord;

  @override
  void dispose() {
    inputController.removeListener(_onTextChanged);
    inputController.dispose();
    super.dispose();
  }
}
