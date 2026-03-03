// --- lib/vaccinations/widgets/child_profile_frame.dart ---

import 'package:flutter/material.dart';

/// ChildProfileFrame
///
/// A reusable widget that displays a child's profile photo inside a
/// circular decorative frame (the candy/toys ring from the Figma design).
///
/// Layers (bottom → top):
///   1. Outer decorative ring  — `images/vaccination_frame.png`
///   2. Inner white filler circle
///   3. Child's photo clipped to a circle
///
/// Usage:
/// ```dart
/// ChildProfileFrame(
///   imageUrl: 'https://example.com/child.jpg',
///   size: 220,
/// )
/// ```
class ChildProfileFrame extends StatelessWidget {
  /// The remote URL or local asset path for the child's profile photo.
  /// If null, [placeholderAsset] is used instead.
  final String? imageUrl;

  /// Outer diameter of the entire frame widget. Defaults to 280.
  final double size;

  /// The fraction of [size] used for the child photo diameter.
  /// Tune this value until the photo sits perfectly inside the ring's
  /// center hole. Increase to show more of the photo; decrease if the
  /// photo edges still overflow the ring.
  final double photoRatio;

  /// Fallback asset shown when [imageUrl] is null or fails to load.
  final String placeholderAsset;

  const ChildProfileFrame({
    super.key,
    this.imageUrl,
    this.size = 280,
    this.photoRatio = 0.44,
    this.placeholderAsset = 'images/child-sample.png',
  });

  @override
  Widget build(BuildContext context) {
    // Inner photo diameter = size × photoRatio.
    // The 3D candy ring has a thicker band than the Figma flat illustration;
    // 0.44 keeps the photo safely inside the ring's center hole.
    // Adjust photoRatio in the constructor call if needed.
    final double innerSize = size * photoRatio;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Layer 1 (bottom): White backing circle ───────────────────────
          // Ensures a clean white surface behind the child photo.
          Container(
            width: innerSize,
            height: innerSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),

          // ── Layer 2 (middle): Child's profile photo ──────────────────────
          // Clipped to a circle; sits inside the frame's hollow center.
          ClipOval(
            child: SizedBox(
              width: innerSize,
              height: innerSize,
              child: _buildChildImage(),
            ),
          ),

          // ── Layer 3 (top): Decorative ring ───────────────────────────────
          // Placed LAST so it renders on top of the photo. The ring's white
          // center is opaque and acts as the border / matting around the photo.
          // BoxFit.fill makes it cover exactly the SizedBox square so the
          // outer ring aligns with the widget boundary.
          _DecorativeRing(size: size),
        ],
      ),
    );
  }

  /// Builds the appropriate image widget based on whether [imageUrl] is set.
  Widget _buildChildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFBF092F),
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  /// Fallback image when no URL is available or an error occurs.
  Widget _buildPlaceholder() {
    return Image.asset(
      placeholderAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.child_care,
        size: 60,
        color: Color(0xFFBF092F),
      ),
    );
  }
}

// ─────────────────────────── Private sub-widget ─────────────────────────────

/// The decorative candy/toys circular ring image that forms the outer border.
class _DecorativeRing extends StatelessWidget {
  final double size;

  const _DecorativeRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'images/vaccination_frame.png',
        // BoxFit.fill stretches the square PNG to fill the SizedBox
        // edge-to-edge, so the ring's center hole aligns precisely with
        // the child photo beneath it.
        fit: BoxFit.fill,
        // Graceful fallback: a simple colored circle border if asset is absent.
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFBF092F),
              width: 6,
            ),
          ),
        ),
      ),
    );
  }
}
