// --- lib/providers/child_profile_provider.dart ---
// Child Profile Provider - State Management for Child Profile Screen

import 'package:flutter/material.dart';

/// Model for a single dashboard item on the child profile screen
class DashboardItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isLocked;

  const DashboardItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isLocked = false,
  });
}

class ChildProfileProvider extends ChangeNotifier {
  // --- State ---
  String _childName = 'ابراهيم';
  String _childAge = '25 يوم';
  String? _profileImageUrl;
  double _profileCompletionPercent = 0.25;
  int _completedVaccinations = 2;
  int _totalVaccinations = 8;
  bool _isLoading = false;

  // --- Getters ---
  String get childName => _childName;
  String get childAge => _childAge;
  String? get profileImageUrl => _profileImageUrl;
  double get profileCompletionPercent => _profileCompletionPercent;
  int get completedVaccinations => _completedVaccinations;
  int get totalVaccinations => _totalVaccinations;
  bool get isLoading => _isLoading;

  String get completionPercentText =>
      '${(_profileCompletionPercent * 100).toInt()}%';

  String get vaccinationStatusText =>
      'تم اتمام $_completedVaccinations من $_totalVaccinations تطعيمات أساسية للعام الأول';

  // --- Dashboard Items ---
  List<DashboardItem> get dashboardItems => const [
        DashboardItem(
          title: 'التطعيمات',
          icon: Icons.vaccines,
          iconColor: Color(0xFFBF092F),
          bgColor: Color(0xFFFEF2F2),
        ),
        DashboardItem(
          title: 'بيانات الطفل',
          icon: Icons.child_care,
          iconColor: Color(0xFFFE8401),
          bgColor: Color(0x0DFE8401),
        ),
        DashboardItem(
          title: 'المهام',
          icon: Icons.assignment_outlined,
          iconColor: Color(0xFFFE8401),
          bgColor: Color(0x0DFE8401),
        ),
        DashboardItem(
          title: 'المكافآت',
          icon: Icons.lock_outline,
          iconColor: Color(0xFF000000),
          bgColor: Color(0x0D0EA5E9),
          isLocked: true,
        ),
        DashboardItem(
          title: 'السجل الطبي',
          icon: Icons.medical_services_outlined,
          iconColor: Color(0xFF0EA5E9),
          bgColor: Color(0x0D0EA5E9),
        ),
        DashboardItem(
          title: 'سجل النمو',
          icon: Icons.trending_up,
          iconColor: Color(0xFF01A449),
          bgColor: Color(0x0D01A449),
        ),
      ];

  // --- Methods ---
  void setChildData({
    required String name,
    required String age,
    String? imageUrl,
  }) {
    _childName = name;
    _childAge = age;
    _profileImageUrl = imageUrl;
    notifyListeners();
  }

  void updateCompletion(double percent, int completed, int total) {
    _profileCompletionPercent = percent;
    _completedVaccinations = completed;
    _totalVaccinations = total;
    notifyListeners();
  }
}
