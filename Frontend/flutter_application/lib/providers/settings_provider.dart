// --- lib/providers/settings_provider.dart ---
// Settings Provider - State Management for Settings Page

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // --- State ---
  bool _childLoginVerification = true;
  bool _notificationsEnabled = false;
  bool _isLoading = false;

  // --- Keys for SharedPreferences ---
  static const String _childLoginVerificationKey = 'child_login_verification';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // --- Getters ---
  bool get childLoginVerification => _childLoginVerification;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;

  // --- Initialize from local storage ---
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _childLoginVerification =
          prefs.getBool(_childLoginVerificationKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;
    } catch (e) {
      print('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Toggle Child Login Verification ---
  Future<void> toggleChildLoginVerification() async {
    _childLoginVerification = !_childLoginVerification;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_childLoginVerificationKey, _childLoginVerification);
    } catch (e) {
      print('Error saving child login verification setting: $e');
    }
  }

  // --- Toggle Notifications ---
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    } catch (e) {
      print('Error saving notifications setting: $e');
    }
  }

  // --- Reset Settings ---
  void reset() {
    _childLoginVerification = true;
    _notificationsEnabled = false;
    notifyListeners();
  }
}
