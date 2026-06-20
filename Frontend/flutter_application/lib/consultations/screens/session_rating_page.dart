import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';

// ── Theme constants ───────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kStar = Color(0xFFF6A609);
const Color _kBorder = Color(0xFFE2E2E2);
const String _kFont = 'IBM Plex Sans Arabic';

/// شاشة تقييم الجلسة (استبيان من 3 خطوات) — يظهر بعد اكتمال الجلسة.
/// يعيد `true` عبر Navigator.pop عند نجاح التقييم كي تُحدّث صفحة التفاصيل حالة الزر.
class SessionRatingPage extends StatefulWidget {
  final String bookingId;
  final String doctorName;

  const SessionRatingPage({
    super.key,
    required this.bookingId,
    required this.doctorName,
  });

  @override
  State<SessionRatingPage> createState() => _SessionRatingPageState();
}

class _SessionRatingPageState extends State<SessionRatingPage> {
  final ParentConsultationService _api = ParentConsultationService();

  int _step = 0; // 0 = النجوم، 1 = السؤال الأول، 2 = السؤال الثاني

  int? _rating; // 1..5
  bool? _wouldBookAgain;
  bool? _hadIssue;
  final TextEditingController _issueController = TextEditingController();

  bool _submitting = false;
  bool _showCelebration = false;

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: _kFont)),
        backgroundColor: _kPrimary,
      ),
    );
  }

  void _next() {
    if (_step == 0) {
      if (_rating == null) {
        _toast('يرجى اختيار تقييم الجلسة');
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_wouldBookAgain == null) {
        _toast('يرجى اختيار إجابة');
        return;
      }
      setState(() => _step = 2);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  Future<void> _submit() async {
    if (_hadIssue == null) {
      _toast('يرجى تحديد ما إذا واجهت مشكلة');
      return;
    }
    if (_hadIssue == true && _issueController.text.trim().isEmpty) {
      _toast('يرجى كتابة وصف المشكلة التي واجهتها');
      return;
    }

    setState(() => _submitting = true);
    try {
      final status = await _api.submitSessionRating(
        bookingId: widget.bookingId,
        rating: _rating!,
        wouldBookAgain: _wouldBookAgain!,
        hadIssue: _hadIssue!,
        issueDescription: _hadIssue == true ? _issueController.text.trim() : null,
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _showCelebration = true;
      });

      final stars = status.starsAwarded > 0 ? status.starsAwarded : 250;
      await _showRewardOverlay(stars);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Celebration + reward popup (صورة 12) ──────────────────────────────────────

  Future<void> _showRewardOverlay(int stars) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'reward',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => _RewardOverlay(stars: stars),
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildQuestionCard(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStepBody(),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
              if (_showCelebration)
                const Positioned.fill(child: IgnorePointer(child: _CelebrationLayer())),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F1F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black87, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'تقييم الجلسة',
            style: TextStyle(
              fontFamily: _kFont,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Question prompt card (light pink box) ─────────────────────────────────────

  String get _questionText {
    switch (_step) {
      case 0:
        return 'ما تقييمك للجلسة مع الطبيب ${widget.doctorName}؟';
      case 1:
        return 'هل ستعاود طلب الجلسة مرة اخرى؟';
      default:
        return 'هل واجهت اى مشكلة اثناء الجلسة او الحجز؟';
    }
  }

  Widget _buildQuestionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFBEDEF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.12)),
        ),
        child: Text(
          _questionText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _kFont,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Step bodies ───────────────────────────────────────────────────────────────

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _buildStarsStep();
      case 1:
        return _buildBookAgainStep();
      default:
        return _buildIssueStep();
    }
  }

  // Step 0 — تقييم النجوم (5 → 1)
  Widget _buildStarsStep() {
    return Column(
      children: [
        for (int value = 5; value >= 1; value--) ...[
          _buildStarRow(value),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStarRow(int value) {
    final bool selected = _rating == value;
    return GestureDetector(
      onTap: () => setState(() => _rating = value),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? _kPrimary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            value,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.star_rounded, color: _kStar, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  // Step 1 — هل ستعاود طلب الجلسة؟
  Widget _buildBookAgainStep() {
    return Column(
      children: [
        _buildChoiceTile(
          label: 'نعم, عند الحاجة',
          selected: _wouldBookAgain == true,
          onTap: () => setState(() => _wouldBookAgain = true),
        ),
        const SizedBox(height: 12),
        _buildChoiceTile(
          label: 'لا, جلسة ضعيفة ولم نستفد منها',
          selected: _wouldBookAgain == false,
          onTap: () => setState(() => _wouldBookAgain = false),
        ),
      ],
    );
  }

  // Step 2 — هل واجهت مشكلة؟
  Widget _buildIssueStep() {
    return Column(
      children: [
        _buildChoiceTile(
          label: 'نعم, واجهت مشكلة',
          selected: _hadIssue == true,
          onTap: () => setState(() => _hadIssue = true),
        ),
        if (_hadIssue == true) ...[
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'وصف المشكلة الحالية',
              style: TextStyle(
                fontFamily: _kFont,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _issueController,
              maxLines: 4,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: _kFont, fontSize: 14, color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'اكتب الشكوى هنا...',
                hintStyle: TextStyle(fontFamily: _kFont, fontSize: 14, color: Color(0xFFBDBDBD)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildChoiceTile(
          label: 'لا يوجد مشكلة',
          selected: _hadIssue == false,
          onTap: () => setState(() => _hadIssue = false),
        ),
      ],
    );
  }

  Widget _buildChoiceTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? _kPrimary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _kFont,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // ── Bottom bar (التالي / تأكيد + السابق) ──────────────────────────────────────

  Widget _buildBottomBar() {
    final bool isLast = _step == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _primaryButton(
            label: isLast ? 'تأكيد التقييم' : 'التالي',
            loading: _submitting,
            onTap: _submitting ? null : (isLast ? _submit : _next),
          ),
          if (_step > 0) ...[
            const SizedBox(height: 12),
            _outlinedButton(
              label: 'السابق',
              onTap: _submitting ? null : _back,
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onTap, bool loading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: onTap == null ? _kPrimary.withValues(alpha: 0.6) : _kPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _outlinedButton({required String label, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFCFCF)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: _kFont,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ── Reward overlay (auto-dismiss card + confetti) — صورة 12 ─────────────────────

class _RewardOverlay extends StatefulWidget {
  final int stars;
  const _RewardOverlay({required this.stars});

  @override
  State<_RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<_RewardOverlay> {
  @override
  void initState() {
    super.initState();
    // إغلاق تلقائي بعد عرض الاحتفال
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _CelebrationLayer())),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(
                          value: 0.85,
                          minHeight: 12,
                          backgroundColor: Color(0xFFFFDCB4),
                          valueColor: AlwaysStoppedAnimation<Color>(_kOrange),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Icon(Icons.star_border_rounded, color: _kOrange, size: 56),
                      const SizedBox(height: 14),
                      Text(
                        'تم اضافة ${widget.stars} نجمة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تم اضافة عدد النقاط الى محفظة نقاطك تجدها في الملف الشخصي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 13,
                          color: Color(0xFF6B6B6B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti celebration (نفس تأثير المطر في باقي التطبيق) ──────────────────────

class _CelebrationLayer extends StatefulWidget {
  const _CelebrationLayer();

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(progress: _ctrl.value),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  const _ConfettiPainter({required this.progress});

  static const _colors = [
    Color(0xFF54C7C9),
    Color(0xFFF45D5D),
    Color(0xFF53A8F1),
    Color(0xFFF2B94B),
    Color(0xFF61BE93),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 40; i++) {
      paint.color = _colors[i % _colors.length].withValues(alpha: 0.95);
      final leftSide = i.isEven;
      final baseX = leftSide
          ? 12.0 + (i % 6) * 22
          : size.width - 110 + (i % 6) * 20;
      final baseY = 40.0 + (i % 9) * 34;
      final fall = (progress * (140 + (i % 5) * 40)) % (size.height + 120);
      final drift = math.sin(progress * math.pi * 2 + i) * 24;
      final center = Offset(baseX + drift, baseY + fall);
      final path = Path()
        ..moveTo(center.dx, center.dy - 12)
        ..lineTo(center.dx + 13, center.dy + 12)
        ..lineTo(center.dx - 13, center.dy + 12)
        ..close();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((progress * 2.2 + i) * 0.7);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
