// --- lib/child-app/home/child_home_provider.dart ---

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Ajial/child-app/tasks/child_home_task_repository.dart';

/// ChildHomeProvider - Handles child home screen state and gamification logic
class ChildHomeProvider extends ChangeNotifier {
  // --- Audio Players ---
  final AudioPlayer _mainPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // --- State Variables ---
  String _childName = '';
  int _currentStars = 0;
  bool _isFirstLogin = false;
  bool _showCollectStarsDialog = false;
  bool _showNewHeroDialog = false;
  bool _isUILocked = false;
  int _pendingStars = 25;
  bool _isAnimatingStars = false;
  bool _microphoneStarsCollected = false; // Track if "يتكلم" box stars collected this session
  bool _pendingNavigateToRecordings = false; // Flag to navigate after collecting stars

  // --- Getters ---
  String get childName => _childName;
  int get currentStars => _currentStars;
  bool get isFirstLogin => _isFirstLogin;
  bool get showCollectStarsDialog => _showCollectStarsDialog;
  bool get showNewHeroDialog => _showNewHeroDialog;
  bool get isUILocked => _isUILocked;
  int get pendingStars => _pendingStars;
  bool get isAnimatingStars => _isAnimatingStars;
  bool get microphoneStarsCollected => _microphoneStarsCollected;
  bool get pendingNavigateToRecordings => _pendingNavigateToRecordings;

  /// Initialize provider with child data from login
  void initializeWithData({
    required String name,
    int stars = 0,
    bool isFirstLogin = true,
  }) {
    _childName = name;
    _currentStars = stars;
    _isFirstLogin = isFirstLogin;

    if (_isFirstLogin) {
      // Lock UI and show first popup after a short delay
      _isUILocked = true;
      _pendingStars = 25;
      notifyListeners();

      // Trigger first popup (will be called from UI after build)
    }

    notifyListeners();
  }

  /// Start the first-time experience popup sequence (Hero badge first)
  void startFirstTimeExperience() {
    if (_isFirstLogin && !_showCollectStarsDialog && !_showNewHeroDialog) {
      // Show hero badge popup FIRST
      _showNewHeroDialog = true;
      notifyListeners();

      // Play celebratory sound for hero badge
      playSound('assets/sounds/hero_badge.mp3'); // TODO: Replace with actual audio path
    }
  }

  /// Collect stars from dialog - animate and update counter
  Future<void> collectStars() async {
    _isAnimatingStars = true;
    _showCollectStarsDialog = false;
    notifyListeners();

    // Play success sound
    playSound('assets/sounds/collect_stars.mp3'); // TODO: Replace with actual audio path

    // Simulate star animation duration
    await Future.delayed(const Duration(milliseconds: 1500));

    // Update star counter
    _currentStars += _pendingStars;
    _pendingStars = 0;
    _isAnimatingStars = false;
    
    // Unlock UI after collecting stars (end of first-time experience)
    _isUILocked = false;
    _isFirstLogin = false;
    notifyListeners();
  }

  /// Claim hero badge and show stars popup next
  void claimHeroBadge() {
    _showNewHeroDialog = false;
    notifyListeners();

    // Show stars popup after a brief pause
    Future.delayed(const Duration(milliseconds: 500), () {
      _showCollectStarsDialog = true;
      notifyListeners();
      playSound('assets/sounds/hero_badge.mp3'); // TODO: Replace with actual audio path
    });
  }

  /// Close collect stars dialog without collecting (if needed)
  void closeCollectStarsDialog() {
    _showCollectStarsDialog = false;
    notifyListeners();
  }

  /// Show popup for "يتكلم" box stars (10 stars) then navigate
  void showMicrophoneStarsPopup() {
    if (_microphoneStarsCollected) {
      // Already collected, just set flag for navigation
      _pendingNavigateToRecordings = true;
      notifyListeners();
      return;
    }
    
    // Set pending stars for microphone activity
    _pendingStars = 10;
    _showCollectStarsDialog = true;
    _pendingNavigateToRecordings = true;
    
    // Play sound when popup appears
    playSound('assets/sounds/hero_badge.mp3');
    
    notifyListeners();
  }

  /// Called after collecting microphone stars - mark as collected
  void markMicrophoneStarsCollected() {
    _microphoneStarsCollected = true;
    _pendingNavigateToRecordings = false;
    notifyListeners();
  }

  /// Clear navigation flag after navigating
  void clearNavigationFlag() {
    _pendingNavigateToRecordings = false;
    notifyListeners();
  }

  // --- Audio Helper ---
  String _normalizeAssetPath(String path) {
    String p = path.trim();
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    while (p.startsWith('assets/')) {
      p = p.substring('assets/'.length);
    }
    return p;
  }

  /// Play a sound from assets
  Future<void> playSound(String rawPath) async {
    try {
      final path = _normalizeAssetPath(rawPath);
      await _mainPlayer.stop();
      await _mainPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Audio Error (playSound) for '$rawPath' -> $e");
    }
  }

  /// Play click sound effect
  Future<void> playClick() async {
    try {
      final path = _normalizeAssetPath('assets/sounds/click.mp3');
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("SFX Error (playClick) -> $e");
    }
  }

  /// Add stars (for future use - completing activities)
  void addStars(int amount) {
    _currentStars += amount;
    notifyListeners();
  }

  /// Refresh stars count from the API (GET /api/ChildHome/tasks)
  /// Call this whenever you need the latest totalStars from the server.
  Future<void> refreshStarsFromApi() async {
    try {
      final repo = ChildHomeTaskRepository();
      final response = await repo.fetchTasks();
      _currentStars = response.totalStars;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh stars from API: $e');
    }
  }

  /// Set stars directly (used when loading from API)
  void setStars(int stars) {
    _currentStars = stars;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _childName = '';
    _currentStars = 0;
    _isFirstLogin = false;
    _showCollectStarsDialog = false;
    _showNewHeroDialog = false;
    _isUILocked = false;
    _pendingStars = 25;
    _isAnimatingStars = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _mainPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
