import 'package:flutter/material.dart';

/// Provider for the Specialist multi-step registration flow.
/// Holds all form data and PageController logic (frontend-only for now).
class SpecialistAuthProvider extends ChangeNotifier {
  // ─── Page Navigation ───────────────────────────────────────
  final PageController pageController = PageController();
  int _currentStep = 0;
  int get currentStep => _currentStep;
  static const int totalSteps = 4; // 4 form steps only (success is a separate screen)

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    pageController.jumpToPage(step);
    notifyListeners();
  }

  // ─── Login Fields ──────────────────────────────────────────
  String loginUsername = '';
  String loginPassword = '';
  bool loginObscure = true;

  void toggleLoginVisibility() {
    loginObscure = !loginObscure;
    notifyListeners();
  }

  // ─── Step 1: Personal Info ─────────────────────────────────
  String fullName = '';
  String username = '';
  String email = '';
  String phone = '';
  String password = '';
  String confirmPassword = '';
  bool passwordObscure = true;
  bool confirmPasswordObscure = true;

  void togglePasswordVisibility() {
    passwordObscure = !passwordObscure;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    confirmPasswordObscure = !confirmPasswordObscure;
    notifyListeners();
  }

  // ─── Step 2: Identity Proof ────────────────────────────────
  String? idFrontImagePath;
  String? idBackImagePath;

  void setIdFrontImage(String path) {
    idFrontImagePath = path;
    notifyListeners();
  }

  void setIdBackImage(String path) {
    idBackImagePath = path;
    notifyListeners();
  }

  // ─── Step 3: Profession License ────────────────────────────
  String? selectedSpecialty;
  String? certificateImagePath;
  String licenseNumber = '';
  String? licenseImagePath;

  final List<String> specialties = [
    'طب أطفال',
    'طب نفسي',
    'تغذية',
    'علاج طبيعي',
    'تخاطب وتواصل',
    'تعديل سلوك',
    'صحة أسرية',
    'طب عام',
  ];

  void setSpecialty(String? val) {
    selectedSpecialty = val;
    notifyListeners();
  }

  void setCertificateImage(String path) {
    certificateImagePath = path;
    notifyListeners();
  }

  void setLicenseImage(String path) {
    licenseImagePath = path;
    notifyListeners();
  }

  // ─── Step 4: Syndicate Proof ───────────────────────────────
  String? syndicateFrontImagePath;
  String? syndicateBackImagePath;
  String? personalPhotoPath;

  void setSyndicateFrontImage(String path) {
    syndicateFrontImagePath = path;
    notifyListeners();
  }

  void setSyndicateBackImage(String path) {
    syndicateBackImagePath = path;
    notifyListeners();
  }

  void setPersonalPhoto(String path) {
    personalPhotoPath = path;
    notifyListeners();
  }

  // ─── Submission ────────────────────────────────────────────
  bool isSubmitting = false;
  bool submissionComplete = false;

  Future<void> submit() async {
    isSubmitting = true;
    notifyListeners();

    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));

    isSubmitting = false;
    submissionComplete = true;
    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────
  void resetAll() {
    _currentStep = 0;
    loginUsername = '';
    loginPassword = '';
    loginObscure = true;
    fullName = '';
    username = '';
    email = '';
    phone = '';
    password = '';
    confirmPassword = '';
    passwordObscure = true;
    confirmPasswordObscure = true;
    idFrontImagePath = null;
    idBackImagePath = null;
    selectedSpecialty = null;
    certificateImagePath = null;
    licenseNumber = '';
    licenseImagePath = null;
    syndicateFrontImagePath = null;
    syndicateBackImagePath = null;
    personalPhotoPath = null;
    isSubmitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
