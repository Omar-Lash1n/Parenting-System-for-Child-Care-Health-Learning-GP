import 'package:flutter/material.dart';

const String _kFont = 'IBM Plex Sans Arabic';

/// Promotional banner for the child-tracking hardware ("قطعة لتتبع الطفل").
///
/// The artwork (boy, copy and red background) is baked into
/// `images/HardwareAd.png`; only the "اطلب الان" call-to-action button is
/// overlaid here so it stays tappable.
class HardwareAdCard extends StatelessWidget {
  final VoidCallback? onOrderTap;

  const HardwareAdCard({super.key, this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 426 / 232,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'images/HardwareAd.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 24,
              bottom: 18,
              child: _OrderButton(onTap: onOrderTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _OrderButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Text(
            'اطلب الان',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBF092F),
            ),
          ),
        ),
      ),
    );
  }
}
