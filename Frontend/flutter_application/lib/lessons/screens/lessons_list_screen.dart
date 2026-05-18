import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/lessons/models/lesson_models.dart';
import 'package:Ajial/lessons/providers/lesson_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class LessonsListScreen extends StatefulWidget {
  const LessonsListScreen({super.key});

  @override
  State<LessonsListScreen> createState() => _LessonsListScreenState();
}

class _LessonsListScreenState extends State<LessonsListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<LessonProvider>();
      if (provider.categoriesStatus == LessonsStatus.initial) {
        provider.loadCategories();
      }
      provider.loadLessons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<LessonProvider>().loadLessons(
            categoryId: _selectedCategoryId,
            search: value.isEmpty ? null : value,
          );
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    context.read<LessonProvider>().loadLessons(
          categoryId: categoryId,
          search: _searchController.text.isEmpty
              ? null
              : _searchController.text,
        );
  }

  void _openLesson(String lessonId) {
    final provider = context.read<LessonProvider>();
    Navigator.pushNamed(context, '/lesson-detail', arguments: lessonId)
        .then((_) {
      if (!mounted) return;
      provider.loadLessons(
        categoryId: _selectedCategoryId,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Consumer<LessonProvider>(
                builder: (_, provider, __) => _buildCategoryChips(provider),
              ),
              Expanded(
                child: Consumer<LessonProvider>(
                  builder: (_, provider, __) => _buildBody(provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Title on the RIGHT (first child in RTL row)
          const Expanded(
            child: Text(
              'تغذية تربوية',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Back arrow on the LEFT (last child in RTL row)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن سلوك، عنوانٍ تربوية',
          hintStyle: const TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            color: Color(0xFF9E9E9E),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9E9E9E),
          ),
          suffixIcon: const Icon(
            Icons.mic_rounded,
            color: Color(0xFF9E9E9E),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _kPrimary),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(LessonProvider provider) {
    if (provider.categoriesStatus == LessonsStatus.loading &&
        provider.categories.isEmpty) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kPrimary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'الكل',
            isSelected: _selectedCategoryId == null,
            onTap: () => _selectCategory(null),
          ),
          ...provider.categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                label: cat.nameAr,
                isSelected: _selectedCategoryId == cat.id,
                onTap: () => _selectCategory(cat.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LessonProvider provider) {
    if (provider.lessonsStatus == LessonsStatus.loading ||
        provider.lessonsStatus == LessonsStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimary),
      );
    }

    if (provider.lessonsStatus == LessonsStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Color(0xFFD0D0D0),
              ),
              const SizedBox(height: 16),
              Text(
                provider.lessonsError ?? 'تعذر تحميل الدروس',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.loadLessons(
                  categoryId: _selectedCategoryId,
                  search: _searchController.text.isEmpty
                      ? null
                      : _searchController.text,
                ),
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: _kFont,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.lessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Color(0xFFD0D0D0),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'يبدو أنه لا تتوفر نتائج بحث للكلمة\n"${_searchController.text}"'
                    : 'لا يوجد دروس متاحة حالياً',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => provider.loadLessons(
        categoryId: _selectedCategoryId,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: provider.lessons.length,
        itemBuilder: (context, index) {
          final lesson = provider.lessons[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LessonCard(
              lesson: lesson,
              onTap: () => _openLesson(lesson.id),
            ),
          );
        },
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kPrimary : const Color(0xFFD9D9D9),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ── Lesson card ───────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final LessonCardModel lesson;
  final VoidCallback onTap;

  const _LessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lesson.titleAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.categoryNameAr,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  if (lesson.contentPreviewAr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lesson.contentPreviewAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12,
                        color: Colors.black45,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildActionButton(),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _buildImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 88,
      height: 88,
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
                size: 44,
                color: _kPrimary,
              ),
            )
          : const Icon(
              Icons.child_care_rounded,
              size: 44,
              color: _kPrimary,
            ),
    );
  }

  Widget _buildActionButton() {
    if (lesson.isQuizCompleted) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x1201A449),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFF01A449)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF01A449),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'مكتمل · ${lesson.starsEarned} نجمة',
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 12,
                color: Color(0xFF01A449),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 36,
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
          const Icon(Icons.star_border_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            lesson.isRead
                ? 'أجب الأسئلة ${lesson.totalStarsReward}'
                : 'قراءة الدرس ${lesson.totalStarsReward}',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
