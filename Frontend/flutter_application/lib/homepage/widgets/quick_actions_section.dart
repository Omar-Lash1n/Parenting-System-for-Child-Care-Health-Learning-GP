import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'اضف مهمة',
        icon: Icons.event_note_outlined,
        iconColor: const Color(0xFF01A449),
        backgroundColor: const Color(0x0D01A449),
        onTap: () => Navigator.pushNamed(context, '/tasks-welcome'),
      ),
      _QuickActionData(
        label: 'استشارات طبية',
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: const Color(0xFF0EA5E9),
        backgroundColor: const Color(0x0D0EA5E9),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('قريبًا')),
        ),
      ),
      _QuickActionData(
        label: 'مراكز تطعيم',
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFFFE8401),
        backgroundColor: const Color(0x0DFE8401),
        onTap: () => Navigator.pushNamed(context, '/health-unit-search'),
      ),
      _QuickActionData(
        label: 'التطعيمات',
        icon: Icons.vaccines_outlined,
        iconColor: _kPrimary,
        backgroundColor: const Color(0x0DBF092F),
        onTap: () => Navigator.pushNamed(context, '/kids-vaccination-home'),
      ),
    ];

    return SizedBox(
      height: 116,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => _QuickActionCard(data: actions[index]),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 106,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });
}
