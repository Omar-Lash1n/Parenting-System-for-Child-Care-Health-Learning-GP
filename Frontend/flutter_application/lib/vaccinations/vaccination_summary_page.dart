// lib/vaccinations/vaccination_summary_page.dart
//
// Vaccination Summary (ملخص التطعيمات) — a per-child overview powered by
// GET /api/Vaccination/file/{childId}.
//
// Shows:
//  • Progress overview (completion ring + done/missed/upcoming counts)
//  • Next vaccine highlight (most urgent: missed → current → nearest upcoming)
//  • Missed / upcoming list (what needs attention)
//  • Done vaccines list (history)
//
// Receives route args: { childId, childName, childProfileImageUrl }.
// A child switcher in the header lets the user change child.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/vaccinations/models/vaccination_file_models.dart';
import 'package:Ajial/vaccinations/widgets/select_child_bottom_sheet.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x1ABF092F);
const Color _kGrey = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kGreen = Color(0xFF00B050);
const Color _kOrange = Color(0xFFFF8A00);
const Color _kRed = Color(0xFFFF0B0B);
const String _kFont = 'IBM Plex Sans Arabic';

enum _LoadState { idle, loading, success, error }

// ─────────────────────────────────────────────
// VaccinationSummaryPage
// ─────────────────────────────────────────────
class VaccinationSummaryPage extends StatefulWidget {
  const VaccinationSummaryPage({super.key});

  @override
  State<VaccinationSummaryPage> createState() => _VaccinationSummaryPageState();
}

class _VaccinationSummaryPageState extends State<VaccinationSummaryPage> {
  String? _childId;
  String _childName = '';
  String? _childPhotoUrl;

  _LoadState _state = _LoadState.idle;
  String _errorMessage = '';
  GetVaccinationFileResponseDto? _data;

  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _childId = args['childId'] as String?;
      _childName = (args['childName'] as String?) ?? '';
      _childPhotoUrl = args['childProfileImageUrl'] as String?;
      if (_childId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
      }
    }
  }

  // ── Load data ───────────────────────────────
  Future<void> _loadData() async {
    if (_childId == null || !mounted) return;
    setState(() {
      _state = _LoadState.loading;
      _errorMessage = '';
      _data = null;
    });

    final (rawData, statusCode, errorMsg) =
        await AuthService().getVaccinationFile(_childId!);

    if (!mounted) return;

    if (statusCode == 400) {
      // Survey not completed → redirect to welcome flow
      Navigator.pushReplacementNamed(
        context,
        '/vaccination-welcome',
        arguments: {
          'childId': _childId,
          'childName': _childName,
          'childProfileImageUrl': _childPhotoUrl,
        },
      );
      return;
    }

    if (rawData != null) {
      try {
        final dto = GetVaccinationFileResponseDto.fromJson(rawData);
        setState(() {
          _data = dto;
          _childName = dto.childName;
          _childPhotoUrl = dto.childImageUrl ?? _childPhotoUrl;
          _state = _LoadState.success;
        });
      } catch (e) {
        debugPrint('Summary parse error: $e');
        setState(() {
          _state = _LoadState.error;
          _errorMessage = 'حدث خطأ في معالجة البيانات';
        });
      }
    } else {
      setState(() {
        _state = _LoadState.error;
        _errorMessage = errorMsg ?? 'حدث خطأ في تحميل البيانات';
      });
    }
  }

  Future<void> _pickChild() async {
    final selected = await showSelectChildSheet(context);
    if (selected == null || !mounted) return;
    setState(() {
      _childId = selected.childId;
      _childName = selected.fullName;
      _childPhotoUrl = selected.photoUrl;
    });
    _loadData();
  }

  // ─────────────────────────────────────────────
  // Aggregated metrics (main + additional when available)
  // ─────────────────────────────────────────────
  bool get _includeAdditional =>
      _data?.additionalVaccinations.isAvailable ?? false;

  List<VaccinationCardDto> get _allVaccines {
    if (_data == null) return const [];
    return [
      ..._data!.mainVaccinations.vaccinations,
      if (_includeAdditional) ..._data!.additionalVaccinations.vaccinations,
    ];
  }

  int get _totalAll {
    if (_data == null) return 0;
    return _data!.mainVaccinations.allCount +
        (_includeAdditional ? _data!.additionalVaccinations.allCount : 0);
  }

  int get _doneCount {
    if (_data == null) return 0;
    return _data!.mainVaccinations.doneCount +
        (_includeAdditional ? _data!.additionalVaccinations.doneCount : 0);
  }

  int get _missedCount => _data?.mainVaccinations.missedCount ?? 0;

  int get _currentCount => _data?.mainVaccinations.currentCount ?? 0;

  int get _upcomingCount {
    if (_data == null) return 0;
    return _data!.mainVaccinations.upcomingCount +
        (_includeAdditional ? _data!.additionalVaccinations.upcomingCount : 0);
  }

  double get _progress {
    final total = _totalAll;
    if (total == 0) return 0;
    return (_doneCount / total).clamp(0.0, 1.0);
  }

  /// The single most urgent vaccine to highlight.
  VaccinationCardDto? get _nextVaccine {
    final all = _allVaccines;
    if (all.isEmpty) return null;

    final missed = all.where((v) => v.labelEn == 'Missed').toList()
      ..sort((a, b) =>
          (b.missedSinceDays ?? 0).compareTo(a.missedSinceDays ?? 0));
    if (missed.isNotEmpty) return missed.first;

    final current = all.where((v) => v.labelEn == 'Current').toList();
    if (current.isNotEmpty) return current.first;

    final upcoming = all.where((v) => v.labelEn == 'Upcoming').toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (upcoming.isNotEmpty) return upcoming.first;

    return null; // everything done
  }

  /// Vaccines needing attention: missed → current → upcoming (excluding the
  /// highlighted next vaccine to avoid duplication).
  List<VaccinationCardDto> get _attentionList {
    final next = _nextVaccine;
    final missed = _allVaccines.where((v) => v.labelEn == 'Missed').toList()
      ..sort((a, b) =>
          (b.missedSinceDays ?? 0).compareTo(a.missedSinceDays ?? 0));
    final current = _allVaccines.where((v) => v.labelEn == 'Current').toList();
    final upcoming = _allVaccines.where((v) => v.labelEn == 'Upcoming').toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final combined = [...missed, ...current, ...upcoming];
    if (next != null) {
      combined.removeWhere((v) => v.milestoneId == next.milestoneId);
    }
    return combined;
  }

  List<VaccinationCardDto> get _doneList {
    final done = _allVaccines.where((v) => v.labelEn == 'Done').toList()
      ..sort((a, b) =>
          (b.completedDate ?? '').compareTo(a.completedDate ?? ''));
    return done;
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  color: _kPrimaryLight, shape: BoxShape.circle),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(Icons.arrow_forward_rounded,
                    color: _kPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ملخص التطعيمات',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          // Child selector
          if (_childId != null)
            GestureDetector(
              onTap: _pickChild,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: ClipOval(
                      child: _childPhotoUrl != null &&
                              _childPhotoUrl!.isNotEmpty
                          ? Image.network(_childPhotoUrl!,
                              fit: BoxFit.cover,
                              width: 32,
                              height: 32,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: Color(0xFFBDBDBD)))
                          : const Icon(Icons.person_rounded,
                              size: 18, color: Color(0xFFBDBDBD)),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Colors.black),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Body (state machine) ────────────────────
  Widget _buildBody() {
    if (_childId == null) {
      return _NoChildPrompt(onPick: _pickChild);
    }

    switch (_state) {
      case _LoadState.idle:
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator(color: _kPrimary));

      case _LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 56, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: _kFont, fontSize: 14, color: _kGrey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('إعادة المحاولة',
                      style: TextStyle(
                          fontFamily: _kFont, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ],
            ),
          ),
        );

      case _LoadState.success:
        return _buildSummary();
    }
  }

  // ── Summary content ─────────────────────────
  Widget _buildSummary() {
    final next = _nextVaccine;
    final attention = _attentionList;
    final done = _doneList;

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ProgressOverviewCard(
            childName: _childName,
            ageFormatted: _data?.ageFormatted ?? '',
            progress: _progress,
            doneCount: _doneCount,
            missedCount: _missedCount,
            upcomingCount: _upcomingCount + _currentCount,
            totalCount: _totalAll,
          ),
          const SizedBox(height: 20),

          // Next vaccine highlight
          if (next != null) ...[
            const _SectionTitle('التطعيم القادم'),
            const SizedBox(height: 12),
            _NextVaccineCard(item: next),
            const SizedBox(height: 20),
          ] else ...[
            const _AllDoneBanner(),
            const SizedBox(height: 20),
          ],

          // Attention list (missed / current / upcoming)
          if (attention.isNotEmpty) ...[
            const _SectionTitle('يحتاج إلى انتباه'),
            const SizedBox(height: 12),
            ...attention.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MiniVaccineTile(item: v),
                )),
            const SizedBox(height: 20),
          ],

          // Done list
          const _SectionTitle('تطعيمات تمت'),
          const SizedBox(height: 12),
          if (done.isEmpty)
            const _EmptyHint('لم يتم تسجيل أى تطعيم مكتمل بعد')
          else
            ...done.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MiniVaccineTile(item: v),
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _NoChildPrompt
// ─────────────────────────────────────────────
class _NoChildPrompt extends StatelessWidget {
  final VoidCallback onPick;
  const _NoChildPrompt({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: _kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.child_care_rounded,
                  size: 32, color: _kPrimary),
            ),
            const SizedBox(height: 14),
            const Text('اختر الطفل لعرض ملخص تطعيماته',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('اختيار طفل',
                  style: TextStyle(
                      fontFamily: _kFont, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ProgressOverviewCard
// ─────────────────────────────────────────────
class _ProgressOverviewCard extends StatelessWidget {
  final String childName;
  final String ageFormatted;
  final double progress;
  final int doneCount;
  final int missedCount;
  final int upcomingCount;
  final int totalCount;

  const _ProgressOverviewCard({
    required this.childName,
    required this.ageFormatted,
    required this.progress,
    required this.doneCount,
    required this.missedCount,
    required this.upcomingCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, Color(0xFF8E0623)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33BF092F), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Progress ring
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _RingPainter(progress: progress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$pct%',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const Text('اكتمال',
                            style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 10,
                                color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تطعيمات $childName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    if (ageFormatted.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(ageFormatted,
                          style: const TextStyle(
                              fontFamily: _kFont,
                              fontSize: 12,
                              color: Colors.white70)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'أكمل $doneCount من $totalCount تطعيم',
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.18)),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                  label: 'مكتملة',
                  value: doneCount,
                  color: const Color(0xFF6EE7A8)),
              _StatDivider(),
              _StatPill(
                  label: 'فائتة',
                  value: missedCount,
                  color: const Color(0xFFFFC4C4)),
              _StatDivider(),
              _StatPill(
                  label: 'قادمة',
                  value: upcomingCount,
                  color: const Color(0xFFFFD79A)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontFamily: _kFont, fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.18),
    );
  }
}

// ─────────────────────────────────────────────
// _RingPainter — circular progress ring
// ─────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 5;
    const stroke = 7.0;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// _SectionTitle
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Status colour helpers
// ─────────────────────────────────────────────
Color _statusColor(String labelEn) {
  switch (labelEn) {
    case 'Missed':
      return _kRed;
    case 'Done':
      return _kGreen;
    case 'Current':
      return _kOrange;
    default:
      return _kPrimary; // Upcoming
  }
}

Color _statusBg(String labelEn) {
  switch (labelEn) {
    case 'Missed':
      return const Color(0xFFFFE5E5);
    case 'Done':
      return const Color(0xFFE5F7ED);
    case 'Current':
      return const Color(0xFFFFF3E0);
    default:
      return _kPrimaryLight;
  }
}

// ─────────────────────────────────────────────
// _NextVaccineCard — prominent highlight
// ─────────────────────────────────────────────
class _NextVaccineCard extends StatelessWidget {
  final VaccinationCardDto item;
  const _NextVaccineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.labelEn);
    final bg = _statusBg(item.labelEn);

    String subtitle;
    if (item.labelEn == 'Missed') {
      subtitle = 'فائت منذ ${item.missedSinceDays ?? 0} يوم — يُفضّل تداركه';
    } else if (item.labelEn == 'Current') {
      subtitle = 'حان موعده الآن';
    } else {
      subtitle = 'الموعد: ${item.dueDateFormatted}';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: color, width: 6)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(Icons.vaccines_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nameAr,
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(item.vaccinesAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _kFont, fontSize: 12, color: _kGrey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(subtitle,
                            style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _MiniVaccineTile — compact list row
// ─────────────────────────────────────────────
class _MiniVaccineTile extends StatelessWidget {
  final VaccinationCardDto item;
  const _MiniVaccineTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.labelEn);
    final bg = _statusBg(item.labelEn);

    String trailing;
    if (item.labelEn == 'Done') {
      trailing = item.completedDateFormatted ?? item.dueDateFormatted;
    } else if (item.labelEn == 'Missed') {
      trailing = 'فائت';
    } else if (item.labelEn == 'Current') {
      trailing = 'الآن';
    } else {
      trailing = item.dueDateFormatted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(
              item.labelEn == 'Done'
                  ? Icons.check_rounded
                  : Icons.vaccines_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                const SizedBox(height: 2),
                Text(item.vaccinesAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontFamily: _kFont, fontSize: 11.5, color: _kGrey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(50)),
            child: Text(trailing,
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _AllDoneBanner — shown when nothing is pending
// ─────────────────────────────────────────────
class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB6E7C9)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: Color(0xFFCDEFDB), shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded,
                color: _kGreen, size: 30),
          ),
          const SizedBox(height: 10),
          const Text('رائع! لا توجد تطعيمات معلّقة',
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B7A45))),
          const SizedBox(height: 4),
          const Text('تم إكمال جميع التطعيمات المستحقة لطفلك حتى الآن',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12.5,
                  color: Color(0xFF2E7D52),
                  height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _EmptyHint
// ─────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: _kFont, fontSize: 13, color: _kGrey)),
        ],
      ),
    );
  }
}
