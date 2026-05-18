import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:Ajial/homepage/widgets/section_header.dart';
import 'package:Ajial/lessons/models/lesson_models.dart';

const String _kFont = 'IBM Plex Sans Arabic';
const Color _kPrimary = Color(0xFFBF092F);

class ParentingNutritionSection extends StatelessWidget {
  final List<LessonCardModel> lessons;
  final bool isLoading;

  const ParentingNutritionSection({
    super.key,
    required this.lessons,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: 'تغذية تربوية',
          onShowAllTap: () => Navigator.pushNamed(context, '/lessons'),
        ),
        SizedBox(
          height: 236,
          child: isLoading && lessons.isEmpty
              ? _buildSkeletonList()
              : lessons.isEmpty
                  ? _buildPlaceholderList(context)
                  : _buildLiveList(context),
        ),
      ],
    );
  }

  // ── Shimmer skeleton while loading ─────────────────────────────────────────
  Widget _buildSkeletonList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          width: 327,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Static placeholder cards (no data yet) ─────────────────────────────────
  Widget _buildPlaceholderList(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, _) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/lessons'),
        child: const _PlaceholderCard(),
      ),
    );
  }

  // ── Real live cards ────────────────────────────────────────────────────────
  Widget _buildLiveList(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: lessons.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            '/lesson-detail',
            arguments: lesson.id,
          ),
          child: _LiveLessonCard(lesson: lesson),
        );
      },
    );
  }
}

// ── Live card (real API data) ──────────────────────────────────────────────────

class _LiveLessonCard extends StatelessWidget {
  final LessonCardModel lesson;
  const _LiveLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 327,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0x0DBF092F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lesson.titleAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.categoryNameAr,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      if (lesson.contentPreviewAr.isNotEmpty)
                        Text(
                          lesson.contentPreviewAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0x33BF092F),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: lesson.imageUrl != null && lesson.imageUrl!.isNotEmpty
                      ? Image.network(
                          lesson.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.child_care_rounded,
                            size: 46,
                            color: _kPrimary,
                          ),
                        )
                      : const Icon(
                          Icons.child_care_rounded,
                          size: 46,
                          color: _kPrimary,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFEA400), Color(0xFFFD5E00)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_border_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  lesson.isRead
                      ? 'أجب الأسئلة ${lesson.totalStarsReward}'
                      : 'قراءة الدرس ${lesson.totalStarsReward}',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Static placeholder card (empty state) ─────────────────────────────────────

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 327,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0x0DBF092F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الطفل العصبي',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'نوبات الغضب',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'السيطرة على الانفعالات',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(
                    color: Color(0x33BF092F),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const Icon(
                    Icons.child_care_rounded,
                    size: 54,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFEA400), Color(0xFFFD5E00)],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border_rounded, color: Colors.white, size: 24),
                SizedBox(width: 6),
                Text(
                  'قراءة الدرس 50',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
