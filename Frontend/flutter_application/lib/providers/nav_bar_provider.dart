import 'package:flutter/material.dart';

const Color _kNavPrimaryColor = Color(0xFFBF092F);
const String _kNavFontFamily = 'IBM Plex Sans Arabic';

class NavBarProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  static const _navItems = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'الرئيسية',
      route: '/home',
    ),
    _NavItemData(
      icon: Icons.sentiment_satisfied_alt_outlined,
      activeIcon: Icons.sentiment_satisfied_alt,
      label: 'عائلتي',
      route: '/family',
    ),
    _NavItemData(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'المهام',
      route: '/tasks-welcome',
    ),
    _NavItemData(
      icon: Icons.workspace_premium_outlined,
      activeIcon: Icons.workspace_premium,
      label: 'التكريم',
      route: '/ranking',
    ),
    _NavItemData(
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'الملف الشخصى',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = index == currentIndex;
            return _buildNavItem(
              context: context,
              item: item,
              isActive: isActive,
              index: index,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required _NavItemData item,
    required bool isActive,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (index == currentIndex) return;
        Navigator.pushReplacementNamed(context, item.route);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              width: isActive ? 50 : 0,
              decoration: BoxDecoration(
                color: isActive ? _kNavPrimaryColor : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: isActive ? 1.0 : 0.5,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 24,
                color: isActive ? _kNavPrimaryColor : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: isActive ? 1.0 : 0.5,
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kNavFontFamily,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? _kNavPrimaryColor : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
