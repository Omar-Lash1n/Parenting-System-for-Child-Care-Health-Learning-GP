import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Ajial/lessons/models/lesson_models.dart';
import 'package:Ajial/lessons/providers/lesson_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  String? _lessonId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _lessonId = args;
      final provider = context.read<LessonProvider>();
      provider.resetDetail();
      // Fire detail load + mark-read in parallel — mark-read is idempotent
      // Capture provider before the async gap to avoid context-across-async warnings.
      Future.wait([
        provider.loadLessonDetail(_lessonId!),
        provider.markLessonRead(_lessonId!),
      ]);
    }
  }

  void _startQuiz(BuildContext context, LessonDetailModel lesson) {
    // Capture providers BEFORE the async gap
    final lessonProv = context.read<LessonProvider>();
    final profileProv = context.read<ParentProfileProvider>();
    Navigator.pushNamed(
      context,
      '/lesson-quiz',
      arguments: {
        'lessonId': lesson.id,
        'lessonTitle': lesson.titleAr,
      },
    ).then((_) {
      if (!mounted) return;
      // Reload detail so isQuizCompleted reflects new state
      if (_lessonId != null) {
        lessonProv.loadLessonDetail(_lessonId!);
      }
      // Refresh stars balance
      profileProv.fetchProfile();
    });
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<LessonProvider>(
            builder: (context, provider, _) => _buildContent(context, provider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LessonProvider provider) {
    // Show loading header while loading detail
    if (provider.lessonDetailStatus == LessonsStatus.loading ||
        provider.lessonDetailStatus == LessonsStatus.initial) {
      return Column(
        children: [
          _buildHeader(context),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: _kPrimary),
            ),
          ),
        ],
      );
    }

    if (provider.lessonDetailStatus == LessonsStatus.error) {
      return Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: Color(0xFFD0D0D0),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.lessonDetailError ?? 'تعذر تحميل الدرس',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        if (_lessonId != null) {
                          provider.loadLessonDetail(_lessonId!);
                        }
                      },
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
            ),
          ),
        ],
      );
    }

    final lesson = provider.currentLesson!;
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLessonHeroCard(lesson),
                const SizedBox(height: 16),
                _buildContentCard(lesson),
                if (lesson.videoUrl != null &&
                    lesson.videoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildVideoCard(lesson.videoUrl!, lesson.imageUrl),
                ],
                const SizedBox(height: 80), // space for button
              ],
            ),
          ),
        ),
        if (!lesson.isQuizCompleted)
          _buildQuizButton(context, provider, lesson),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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

  Widget _buildLessonHeroCard(LessonDetailModel lesson) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DBF092F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.titleAr,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.categoryNameAr,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                if (lesson.isQuizCompleted) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF01A449),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'مكتمل',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 12,
                          color: Color(0xFF01A449),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 90,
            height: 90,
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
    );
  }

  Widget _buildContentCard(LessonDetailModel lesson) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Text(
        lesson.contentAr,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 14,
          color: Colors.black87,
          height: 1.9,
        ),
      ),
    );
  }

  Widget _buildVideoCard(String videoUrl, String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: () => _openVideo(videoUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0x1ABF092F),
            border: Border.all(color: const Color(0x33BF092F)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Thumbnail image or fallback ──
              if (hasImage)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0x1ABF092F),
                  ),
                )
              else
                Container(color: const Color(0x1ABF092F)),

              // ── Dark scrim overlay ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),

              // ── Centered play button ──
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              // ── Label at bottom-right ──
              const Positioned(
                bottom: 12,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'مشاهدة الفيديو',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizButton(
    BuildContext context,
    LessonProvider provider,
    LessonDetailModel lesson,
  ) {
    final quizReady = provider.markReadStatus == LessonsStatus.loaded &&
        provider.quizQuestions.isNotEmpty;
    final isLoading = provider.markReadStatus == LessonsStatus.loading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: InkWell(
        onTap: quizReady ? () => _startQuiz(context, lesson) : null,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: quizReady
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFEA400), Color(0xFFFD5E00)],
                  )
                : null,
            color: quizReady ? null : const Color(0xFFE0E0E0),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_border_rounded,
                        color: quizReady ? Colors.white : Colors.black38,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'أجب الاسئلة واحصل على ${lesson.totalStarsReward} نجمة',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: quizReady ? Colors.white : Colors.black38,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
