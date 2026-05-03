import 'package:flutter/material.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onShowAllTap;
  final String showAllText;

  const SectionHeader({
    super.key,
    required this.title,
    this.onShowAllTap,
    this.showAllText = 'عرض الكل',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 47,
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onShowAllTap,
            borderRadius: BorderRadius.circular(20),
            child: Opacity(
              opacity: onShowAllTap == null ? 0.35 : 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        showAllText,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
