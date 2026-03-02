// --- lib/providers/add_child_flow_provider.dart ---

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/api/auth_service.dart';

/// FruitItem model for fruit password selection
class FruitItem {
  final String imagePath;
  final String code;
  FruitItem(this.imagePath, this.code);
}

/// AddChildFlowProvider - Handles multi-step add child flow state
/// This provider is SHARED across all PageView steps to persist data
class AddChildFlowProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- Step/Flow State ---
  int _currentStep = 0;
  int _totalSteps = 4;

  // --- Child Data ---
  String? _selectedGender;
  File? _childImage;
  String? _selectedMonth;

  // --- Account Data (for older children) ---
  List<String> _selectedFruitCodes = [];
  List<String> _selectedFruitImages = [];

  // --- Validation Errors ---
  String? _nameError;
  String? _dateError;
  String? _genderError;
  String? _idError;

  // --- Age Check ---
  bool _isOlderChild = false;
  bool _isLoading = false;

  // --- Fruit Data ---
  final List<FruitItem> fruitsList = [
    FruitItem('images/lemon.png', 'lemon2025'),
    FruitItem('images/grapes.png', 'grape2025'),
    FruitItem('images/orange-juice.png', 'orange2025'),
    FruitItem('images/banana.png', 'banana2025'),
    FruitItem('images/pear.png', 'pear2025'),
    FruitItem('images/apple.png', 'apple2025'),
    FruitItem('images/fig.png', 'fig2025'),
    FruitItem('images/strawberry.png', 'strawberry2025'),
    FruitItem('images/pineapple.png', 'pineapple2025'),
    FruitItem('images/watermelon.png', 'watermelon2025'),
  ];

  // --- Months List ---
  final List<Map<String, String>> monthsList = [
    {'val': '1', 'label': 'يناير (01)'},
    {'val': '2', 'label': 'فبراير (02)'},
    {'val': '3', 'label': 'مارس (03)'},
    {'val': '4', 'label': 'أبريل (04)'},
    {'val': '5', 'label': 'مايو (05)'},
    {'val': '6', 'label': 'يونيو (06)'},
    {'val': '7', 'label': 'يوليو (07)'},
    {'val': '8', 'label': 'أغسطس (08)'},
    {'val': '9', 'label': 'سبتمبر (09)'},
    {'val': '10', 'label': 'أكتوبر (10)'},
    {'val': '11', 'label': 'نوفمبر (11)'},
    {'val': '12', 'label': 'ديسمبر (12)'},
  ];

  // --- Getters ---
  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  String? get selectedGender => _selectedGender;
  File? get childImage => _childImage;
  String? get selectedMonth => _selectedMonth;
  List<String> get selectedFruitCodes => _selectedFruitCodes;
  List<String> get selectedFruitImages => _selectedFruitImages;
  String? get nameError => _nameError;
  String? get dateError => _dateError;
  String? get genderError => _genderError;
  String? get idError => _idError;
  bool get isOlderChild => _isOlderChild;
  bool get isLoading => _isLoading;

  // --- Setters ---
  void setCurrentStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setSelectedMonth(String? month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setChildImage(File? image) {
    _childImage = image;
    notifyListeners();
  }

  void clearChildImage() {
    _childImage = null;
    notifyListeners();
  }

  // --- Fruit Selection ---
  void addFruit(int index) {
    if (_selectedFruitImages.length < 5) {
      _selectedFruitImages.add(fruitsList[index].imagePath);
      _selectedFruitCodes.add(fruitsList[index].code);
      notifyListeners();
    }
  }

  void clearFruits() {
    _selectedFruitImages.clear();
    _selectedFruitCodes.clear();
    notifyListeners();
  }

  // --- Error Clearing ---
  void clearErrors() {
    _nameError = null;
    _dateError = null;
    _genderError = null;
    _idError = null;
    notifyListeners();
  }

  // --- Image Picker ---
  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _childImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- Validation and Navigation ---
  /// Validates current step and returns true if valid
  bool validateStep({
    required int stepIndex,
    required String name,
    required String day,
    required String month,
    required String year,
    required String childId,
    required BuildContext context,
  }) {
    clearErrors();

    switch (stepIndex) {
      case 0: // Name
        if (name.trim().isEmpty) {
          _nameError = "اسم الطفل كامل مطلوب - يرجى إدخال اسم الطفل للمتابعة";
          notifyListeners();
          return false;
        }
        // Validate name contains only letters and spaces
        final nameRegex = RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$');
        if (!nameRegex.hasMatch(name.trim())) {
          _nameError = "يرجى إدخال اسم صحيح يحتوي على حروف فقط";
          notifyListeners();
          return false;
        }
        // Validate full name has at least two words (first and last name)
        final nameParts = name.trim().split(RegExp(r'\s+'));
        if (nameParts.length < 2) {
          _nameError = "يرجى إدخال الاسم كاملاً (الاسم الأول واسم العائلة)";
          notifyListeners();
          return false;
        }
        // Validate each name part has at least 2 characters
        for (var part in nameParts) {
          if (part.length < 2) {
            _nameError = "كل جزء من الاسم يجب أن يكون حرفين على الأقل";
            notifyListeners();
            return false;
          }
        }
        return true;

      case 1: // Birth Date
        if (day.isEmpty || month.isEmpty || year.isEmpty) {
          _dateError = "يرجى إدخال تاريخ الميلاد كاملاً";
          notifyListeners();
          return false;
        }

        int? d = int.tryParse(day);
        int? m = int.tryParse(month);
        int? y = int.tryParse(year);

        if (d == null ||
            d < 1 ||
            d > 31 ||
            m == null ||
            m < 1 ||
            m > 12 ||
            y == null ||
            y > DateTime.now().year ||
            y < 1900) {
          _dateError = "تاريخ غير صحيح";
          notifyListeners();
          return false;
        }

        // Calculate age and determine if older child
        final dob = DateTime(y, m, d);
        final now = DateTime.now();

        // Check if birth date is in the future
        if (dob.isAfter(now)) {
          _dateError = "تاريخ الميلاد لا يمكن أن يكون في المستقبل";
          notifyListeners();
          return false;
        }

        int age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }

        // Validate age range (0-18 years)
        if (age < 0) {
          _dateError = "تاريخ الميلاد غير صحيح";
          notifyListeners();
          return false;
        }

        if (age >= 18) {
          _dateError = "عمر الطفل يجب أن يكون أقل من 18 سنة";
          notifyListeners();
          return false;
        }

        _isOlderChild = age >= 4;
        _totalSteps = _isOlderChild ? 5 : 4;
        notifyListeners();
        return true;

      case 2: // Gender
        if (_selectedGender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "يرجى اختيار نوع الطفل",
                style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
              ),
            ),
          );
          return false;
        }
        return true;

      case 3: // Picture (optional)
        return true;

      case 4: // Account (for older children)
        if (childId.length != 4) {
          _idError = "يجب أن يتكون الرقم من 4 أرقام";
          notifyListeners();
          return false;
        }
        if (_selectedFruitCodes.length != 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "يرجى اختيار 5 فواكه لكلمة السر",
                style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
              ),
            ),
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  // --- Submit to Backend ---
  Future<bool> submitDataToBackend({
    required String name,
    required String day,
    required String month,
    required String year,
    required String childId,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Prepare data
      final String fullName = name.trim();
      final int d = int.parse(day);
      final int m = int.parse(month);
      final int y = int.parse(year);
      final DateTime birthDate = DateTime(y, m, d);
      final String gender = (_selectedGender == 'male') ? 'Male' : 'Female';

      // Call API
      final result = await _authService.addChild(
        fullName: fullName,
        birthDate: birthDate,
        gender: gender,
        profileImage: _childImage,
        childLoginId: _isOlderChild ? childId.trim() : null,
        fruitPasswordCodes: _isOlderChild ? _selectedFruitCodes : null,
      );

      _isLoading = false;
      notifyListeners();

      if (!context.mounted) return false;

      if (result.$1) {
        // Success
        return true;
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.$2,
              style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
            style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// Reset all provider state (call when flow is complete or cancelled)
  void reset() {
    _currentStep = 0;
    _totalSteps = 4;
    _selectedGender = null;
    _childImage = null;
    _selectedMonth = null;
    _selectedFruitCodes = [];
    _selectedFruitImages = [];
    _nameError = null;
    _dateError = null;
    _genderError = null;
    _idError = null;
    _isOlderChild = false;
    _isLoading = false;
    notifyListeners();
  }
}
