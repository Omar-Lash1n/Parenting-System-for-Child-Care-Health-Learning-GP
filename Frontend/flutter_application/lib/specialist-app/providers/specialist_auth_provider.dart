import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/specialist-services.dart';

/// Provider for the Specialist multi-step registration flow.
/// Holds form data, validation, and API integration.
class SpecialistAuthProvider extends ChangeNotifier {
  final SpecialistService _service = SpecialistService();
  final ImagePicker _picker = ImagePicker();

  // ─── Page Navigation ───────────────────────────────────────
  final PageController pageController = PageController();
  int _currentStep = 0;
  int get currentStep => _currentStep;
  static const int totalSteps = 3;

  // ─── Error / Status ────────────────────────────────────────
  String? errorMessage;
  bool isSubmitting = false;
  bool isLoggingIn = false;
  bool submissionComplete = false;

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // ─── Step Navigation with Validation ───────────────────────
  bool nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return false;
    }
    errorMessage = null;
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
    return true;
  }

  void previousStep() {
    errorMessage = null;
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

  // ─── Step 0: Personal Info ─────────────────────────────────
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

  // ─── Step 1: Identity Proof (XFile-based — works on web + mobile) ───
  XFile? idFrontImageFile;
  XFile? idBackImageFile;
  XFile? personalPhotoFile;

  String? get idFrontImageName => idFrontImageFile?.name;
  String? get idBackImageName => idBackImageFile?.name;
  String? get personalPhotoName => personalPhotoFile?.name;

  Future<void> pickIdFrontImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      idFrontImageFile = picked;
      notifyListeners();
    }
  }

  Future<void> pickIdBackImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      idBackImageFile = picked;
      notifyListeners();
    }
  }

  Future<void> pickPersonalPhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      personalPhotoFile = picked;
      notifyListeners();
    }
  }

  // ─── Step 2: License + Syndicate (XFile-based) ─────────────
  String? selectedSpecialty;
  XFile? certificateImageFile;
  String licenseNumber = '';
  XFile? licenseImageFile;
  XFile? syndicateCardFile;

  String? get certificateImageName => certificateImageFile?.name;
  String? get licenseImageName => licenseImageFile?.name;
  String? get syndicateCardName => syndicateCardFile?.name;

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

  Future<void> pickCertificateImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      certificateImageFile = picked;
      notifyListeners();
    }
  }

  Future<void> pickLicenseImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      licenseImageFile = picked;
      notifyListeners();
    }
  }

  Future<void> pickSyndicateCard() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      syndicateCardFile = picked;
      notifyListeners();
    }
  }

  // ─── Validation ────────────────────────────────────────────

  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStep0();
      case 1:
        return _validateStep1();
      case 2:
        return _validateStep2();
      default:
        return null;
    }
  }

  String? _validateStep0() {
    if (fullName.trim().isEmpty) return 'الاسم الرباعي مطلوب';
    if (fullName.trim().length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    if (fullName.trim().length > 100) return 'الاسم يجب ألا يتجاوز 100 حرف';

    if (username.trim().isEmpty) return 'اسم المستخدم مطلوب';
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!usernameRegex.hasMatch(username.trim())) {
      return 'اسم المستخدم يجب أن يحتوي على حروف وأرقام فقط (بدون مسافات أو رموز)';
    }

    if (email.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }

    if (phone.trim().isEmpty) return 'رقم الهاتف مطلوب';
    final phoneRegex = RegExp(r'^(01[0125])[0-9]{8}$');
    final phoneClean = phone.trim().replaceAll(RegExp(r'^\+?20|^0020'), '');
    if (!phoneRegex.hasMatch(phoneClean) && !RegExp(r'^(01[0125])[0-9]{8}$').hasMatch(phone.trim())) {
      return 'رقم الهاتف غير صالح. استخدم تنسيق مصري (مثل: 01012345678)';
    }

    if (password.isEmpty) return 'كلمة المرور مطلوبة';
    if (password.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل';
    }

    return null;
  }

  String? _validateStep1() {
    if (idFrontImageFile == null) return 'صورة البطاقة (الوجه الأمامي) مطلوبة';
    if (idBackImageFile == null) return 'صورة البطاقة (الوجه الخلفي) مطلوبة';
    if (personalPhotoFile == null) return 'الصورة الشخصية مطلوبة';
    return null;
  }

  String? _validateStep2() {
    if (selectedSpecialty == null || selectedSpecialty!.isEmpty) {
      return 'التخصص مطلوب';
    }
    if (certificateImageFile == null) return 'صورة شهادة التخصص مطلوبة';
    if (licenseNumber.trim().isEmpty) return 'رقم الترخيص المهني مطلوب';
    if (licenseImageFile == null) return 'صورة الترخيص المهني مطلوبة';
    if (syndicateCardFile == null) return 'صورة كارنيه النقابة مطلوبة';
    return null;
  }

  // ─── Submit Registration ───────────────────────────────────

  Future<void> submit() async {
    final error = _validateStep2();
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    final (success, message) = await _service.registerSpecialist(
      fullName: fullName.trim(),
      username: username.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
      specialization: selectedSpecialty!,
      practiceLicenseNumber: licenseNumber.trim(),
      idFrontImage: idFrontImageFile!,
      idBackImage: idBackImageFile!,
      specializationCertificateImage: certificateImageFile!,
      practiceLicenseImage: licenseImageFile!,
      unionCardImage: syndicateCardFile!,
      personalPhoto: personalPhotoFile!,
    );

    isSubmitting = false;

    if (success) {
      submissionComplete = true;
    } else {
      errorMessage = message;
    }
    notifyListeners();
  }

  // ─── Login ─────────────────────────────────────────────────

  Future<SpecialistLoginResult?> login() async {
    if (loginUsername.trim().isEmpty) {
      errorMessage = 'اسم المستخدم مطلوب';
      notifyListeners();
      return null;
    }
    if (loginPassword.isEmpty) {
      errorMessage = 'كلمة المرور مطلوبة';
      notifyListeners();
      return null;
    }

    isLoggingIn = true;
    errorMessage = null;
    notifyListeners();

    final result = await _service.loginSpecialist(
      username: loginUsername.trim(),
      password: loginPassword,
    );

    isLoggingIn = false;

    if (!result.success) {
      errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result;
  }
  // ─── Clear login state (for non-approved users) ─────────
  void clearLoginState() {
    isLoggingIn = false;
    // Remove any stored tokens since user isn't approved
    _service.logoutSpecialist();
    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────
  void resetAll() {
    _currentStep = 0;
    errorMessage = null;
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
    idFrontImageFile = null;
    idBackImageFile = null;
    personalPhotoFile = null;
    selectedSpecialty = null;
    certificateImageFile = null;
    licenseNumber = '';
    licenseImageFile = null;
    syndicateCardFile = null;
    isSubmitting = false;
    submissionComplete = false;
    isLoggingIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
