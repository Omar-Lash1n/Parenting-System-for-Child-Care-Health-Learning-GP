// --- lib/widgets/skeleton_loading.dart ---
// Reusable skeleton loading widgets for consistent loading states

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const Color kPrimaryColor = Color(0xFFBF092F);

/// Base shimmer widget with customizable colors
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// Skeleton container - a rounded rectangle placeholder
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton circle - for avatars and profile pictures
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton for parent profile page loading state
class ParentProfileSkeleton extends StatelessWidget {
  const ParentProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile header section
            Row(
              children: [
                const SkeletonCircle(size: 80),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 150, height: 20, borderRadius: 10),
                      const SizedBox(height: 8),
                      SkeletonBox(width: 100, height: 14, borderRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stats cards
            Row(
              children: [
                Expanded(
                    child: SkeletonBox(
                        width: double.infinity, height: 80, borderRadius: 16)),
                const SizedBox(width: 12),
                Expanded(
                    child: SkeletonBox(
                        width: double.infinity, height: 80, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),

            // Section title
            Align(
              alignment: Alignment.centerRight,
              child: SkeletonBox(width: 100, height: 18, borderRadius: 8),
            ),
            const SizedBox(height: 16),

            // Children list
            ...List.generate(
                2,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonBox(
                          width: double.infinity, height: 80, borderRadius: 16),
                    )),

            const SizedBox(height: 24),

            // Menu items
            ...List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonBox(
                          width: double.infinity, height: 56, borderRadius: 12),
                    )),
          ],
        ),
      ),
    );
  }
}

/// Generic list skeleton - for any list loading state
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final double borderRadius;
  final EdgeInsets padding;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 70,
    this.spacing = 12,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding:
                  EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
              child: SkeletonBox(
                width: double.infinity,
                height: itemHeight,
                borderRadius: borderRadius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card skeleton with avatar - for child cards, user cards, etc.
class CardWithAvatarSkeleton extends StatelessWidget {
  final double avatarSize;
  final double height;

  const CardWithAvatarSkeleton({
    super.key,
    this.avatarSize = 50,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SkeletonCircle(size: avatarSize),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 16, borderRadius: 8),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 12, borderRadius: 6),
                ],
              ),
            ),
            SkeletonBox(width: 30, height: 30, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

/// Button skeleton - for loading buttons
class ButtonSkeleton extends StatelessWidget {
  final double? width;
  final double height;

  const ButtonSkeleton({
    super.key,
    this.width,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SkeletonBox(
        width: width ?? double.infinity,
        height: height,
        borderRadius: 50,
      ),
    );
  }
}

/// Homepage skeleton for initial app loading
class HomepageSkeleton extends StatelessWidget {
  const HomepageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with avatar
            Row(
              children: [
                const SkeletonCircle(size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 100, height: 14, borderRadius: 8),
                      const SizedBox(height: 6),
                      SkeletonBox(width: 150, height: 18, borderRadius: 10),
                    ],
                  ),
                ),
                SkeletonBox(width: 40, height: 40, borderRadius: 20),
              ],
            ),
            const SizedBox(height: 24),

            // Main card
            SkeletonBox(width: double.infinity, height: 180, borderRadius: 20),
            const SizedBox(height: 24),

            // Section title
            Align(
              alignment: Alignment.centerRight,
              child: SkeletonBox(width: 120, height: 18, borderRadius: 8),
            ),
            const SizedBox(height: 16),

            // Grid items
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: List.generate(
                  4,
                  (index) => SkeletonBox(
                      width: double.infinity, height: 100, borderRadius: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form skeleton for forms loading
class FormSkeleton extends StatelessWidget {
  final int fieldCount;

  const FormSkeleton({
    super.key,
    this.fieldCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
                child: SkeletonBox(width: 200, height: 28, borderRadius: 12)),
            const SizedBox(height: 8),
            Center(child: SkeletonBox(width: 250, height: 16, borderRadius: 8)),
            const SizedBox(height: 32),

            // Form fields
            ...List.generate(
                fieldCount,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 80, height: 14, borderRadius: 6),
                          const SizedBox(height: 8),
                          SkeletonBox(
                              width: double.infinity,
                              height: 55,
                              borderRadius: 30),
                        ],
                      ),
                    )),

            const SizedBox(height: 16),

            // Button
            SkeletonBox(width: double.infinity, height: 55, borderRadius: 50),
          ],
        ),
      ),
    );
  }
}
