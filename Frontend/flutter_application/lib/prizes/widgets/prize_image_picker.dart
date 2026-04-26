// lib/prizes/widgets/prize_image_picker.dart
//
// Circular prize image picker (130x130) with camera badge.
// Shows: picked file > existing URL > default gift icon.

import 'dart:typed_data';

import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class PrizeImagePicker extends StatelessWidget {
  final Uint8List? pickedBytes;
  final String? existingImageUrl;
  final String? prizeName;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const PrizeImagePicker({
    super.key,
    required this.pickedBytes,
    required this.existingImageUrl,
    required this.onPick,
    this.onRemove,
    this.prizeName,
  });

  bool get _hasImage =>
      pickedBytes != null ||
      (existingImageUrl != null && existingImageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Image circle
              GestureDetector(
                onTap: onPick,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F5F5),
                    image: _hasImage ? _decoration() : null,
                  ),
                  alignment: Alignment.center,
                  child: _hasImage
                      ? null
                      : Image.asset(
                          'images/gift.png',
                          width: 56,
                          height: 56,
                          color: _kPrimary,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.card_giftcard,
                              size: 56,
                              color: _kPrimary),
                        ),
                ),
              ),
              // Camera badge
              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: onPick,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
              // Remove badge (only when image exists and onRemove provided)
              if (_hasImage && onRemove != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (prizeName != null && prizeName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            prizeName!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'عنوان المكافأة',
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999)),
          ),
        ],
      ],
    );
  }

  DecorationImage _decoration() {
    if (pickedBytes != null) {
      return DecorationImage(
        image: MemoryImage(pickedBytes!),
        fit: BoxFit.cover,
      );
    }
    return DecorationImage(
      image: NetworkImage(existingImageUrl!),
      fit: BoxFit.cover,
    );
  }
}
