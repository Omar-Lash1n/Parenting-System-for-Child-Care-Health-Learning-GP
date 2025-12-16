// --- lib/providers/child_login_provider.dart ---

import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';

/// Fruit model for child login password selection
class ChildFruit {
  final String id;
  final String code;
  final String name;
  final String imagePath;
  final String audioPath;
  final Color backgroundColor;

  ChildFruit({
    required this.id,
    required this.code,
    required this.name,
    required this.imagePath,
    required this.audioPath,
    required this.backgroundColor,
  });
}

/// ChildLoginProvider - Handles child login screen state and logic
class ChildLoginProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State Variables ---
  List<ChildFruit> _selectedPassword = [];
  bool _isLoading = false;
  bool _isIdError = false;
  bool _isIdCompleted = false;
  bool _showError = false;
  bool _showQuestionMarks = false;
  String _errorMessage = "";
  String _errorAction = "";

  // --- Available Fruits ---
  final List<ChildFruit> availableFruits = [
    ChildFruit(
      id: '1',
      code: 'apple2025',
      name: 'تفاح',
      imagePath: 'images/apple.png',
      audioPath: 'sounds/apple.mp3',
      backgroundColor: const Color(0xFFFFCDD2),
    ),
    ChildFruit(
      id: '2',
      code: 'banana2025',
      name: 'موز',
      imagePath: 'images/banana.png',
      audioPath: 'assets/sounds/banana.mp3',
      backgroundColor: const Color(0xFFFFF9C4),
    ),
    ChildFruit(
      id: '3',
      code: 'orange2025',
      name: 'برتقال',
      imagePath: 'images/orange-juice.png',
      audioPath: 'assets/sounds/orange.mp3',
      backgroundColor: const Color(0xFFFFCC80),
    ),
    ChildFruit(
      id: '4',
      code: 'grape2025',
      name: 'عنب',
      imagePath: 'images/grapes.png',
      audioPath: 'assets/sounds/grape.mp3',
      backgroundColor: const Color(0xFFE1BEE7),
    ),
    ChildFruit(
      id: '5',
      code: 'pear2025',
      name: 'كمثرى',
      imagePath: 'images/pear.png',
      audioPath: 'assets/sounds/pear.mp3',
      backgroundColor: const Color(0xFFC8E6C9),
    ),
    ChildFruit(
      id: '6',
      code: 'strawberry2025',
      name: 'فراولة',
      imagePath: 'images/strawberry.png',
      audioPath: 'assets/sounds/strawberry.mp3',
      backgroundColor: const Color(0xFFEF9A9A),
    ),
    ChildFruit(
      id: '7',
      code: 'watermelon2025',
      name: 'بطيخ',
      imagePath: 'images/watermelon.png',
      audioPath: 'assets/sounds/watermelon.mp3',
      backgroundColor: const Color(0xFFA5D6A7),
    ),
    ChildFruit(
      id: '8',
      code: 'pineapple2025',
      name: 'أناناس',
      imagePath: 'images/pineapple.png',
      audioPath: 'assets/sounds/pineapple.mp3',
      backgroundColor: const Color(0xFFFFF176),
    ),
    ChildFruit(
      id: '9',
      code: 'fig2025',
      name: 'تين',
      imagePath: 'images/fig.png',
      audioPath: 'assets/sounds/fig.mp3',
      backgroundColor: const Color(0xFFD1C4E9),
    ),
    ChildFruit(
      id: '10',
      code: 'lemon2025',
      name: 'ليمون',
      imagePath: 'images/lemon.png',
      audioPath: 'assets/sounds/lemon.mp3',
      backgroundColor: const Color(0xFFFFF59D),
    ),
  ];

  // --- Getters ---
  List<ChildFruit> get selectedPassword => _selectedPassword;
  bool get isLoading => _isLoading;
  bool get isIdError => _isIdError;
  bool get isIdCompleted => _isIdCompleted;
  bool get showError => _showError;
  bool get showQuestionMarks => _showQuestionMarks;
  String get errorMessage => _errorMessage;
  String get errorAction => _errorAction;

  // --- Setters ---
  void setIdCompleted(bool value) {
    if (_isIdCompleted != value) {
      _isIdCompleted = value;
      notifyListeners();
    }
  }

  void setIdError(bool value) {
    if (_isIdError != value) {
      _isIdError = value;
      notifyListeners();
    }
  }

  void clearIdError() {
    if (_isIdError) {
      _isIdError = false;
      notifyListeners();
    }
  }

  // --- Fruit Selection ---
  /// Add fruit to password, returns the fruit if added (for playing audio)
  ChildFruit? addFruit(ChildFruit fruit) {
    if (_selectedPassword.length < 5) {
      _selectedPassword.add(fruit);
      hideToast();
      _showQuestionMarks = false;
      notifyListeners();
      return fruit;
    }
    return null;
  }

  /// Remove fruit at index, clears all after it
  void removeFruitAt(int index) {
    _selectedPassword = _selectedPassword.sublist(0, index);
    hideToast();
    _showQuestionMarks = false;
    notifyListeners();
  }

  void clearPassword() {
    _selectedPassword.clear();
    notifyListeners();
  }

  // --- Toast/Error Management ---
  void showToast(String actionText, String debugMsg) {
    _showError = true;
    _errorAction = actionText;
    _errorMessage = debugMsg;
    notifyListeners();
  }

  void hideToast() {
    if (_showError) {
      _showError = false;
      notifyListeners();
    }
  }

  void setShowQuestionMarks(bool value) {
    _showQuestionMarks = value;
    notifyListeners();
  }

  // --- Validation ---
  /// Returns error type if invalid, null if valid
  /// Error types: 'empty_id', 'short_id', 'empty_fruits', 'incomplete_fruits', null (valid)
  String? validateInputs(String idText) {
    if (idText.isEmpty) {
      _isIdError = true;
      notifyListeners();
      return 'empty_id';
    }

    if (idText.length < 4) {
      _isIdError = true;
      notifyListeners();
      return 'short_id';
    }

    if (_selectedPassword.isEmpty) {
      _showQuestionMarks = true;
      notifyListeners();
      return 'empty_fruits';
    }

    if (_selectedPassword.length < 5) {
      _showQuestionMarks = true;
      notifyListeners();
      return 'incomplete_fruits';
    }

    return null; // Valid
  }

  // --- Login ---
  Future<ChildLoginResult> login({
    required String childId,
  }) async {
    _isLoading = true;
    notifyListeners();

    List<String> fruitCodes = _selectedPassword.map((fruit) => fruit.code).toList();

    final result = await _authService.loginChild(
      childLoginId: childId.trim(),
      fruitPasswordCodes: fruitCodes,
    );

    _isLoading = false;
    notifyListeners();

    return result;
  }

  /// Handle login error (updates UI state)
  void handleLoginError(ChildLoginResult result) {
    _isIdError = true;
    _showQuestionMarks = true;
    showToast("حاول تاني", result.errorMessage ?? "بيانات خاطئة");
  }

  /// Reset all provider state
  void reset() {
    _selectedPassword = [];
    _isLoading = false;
    _isIdError = false;
    _isIdCompleted = false;
    _showError = false;
    _showQuestionMarks = false;
    _errorMessage = "";
    _errorAction = "";
    notifyListeners();
  }
}
