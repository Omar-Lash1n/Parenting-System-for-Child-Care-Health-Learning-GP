// lib/vaccinations/vaccination_dashboard_page.dart
//
// Vaccination Dashboard — powered by GET /api/Vaccination/file/{childId}.
// Shows vaccination cards grouped by status with filter chips.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/family/models/child_model.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/vaccinations/models/vaccination_file_models.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/vaccinations/vaccination_reminder_page.dart';
import 'package:Ajial/vaccinations/vaccination_reminder_service.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x1ABF092F);
const Color _kGrey = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kGreen = Color(0xFF22C55E);

const String _kFont = 'IBM Plex Sans Arabic';

// ─────────────────────────────────────────────
// Page load state
// ─────────────────────────────────────────────
enum _LoadState { idle, loading, success, error }

// ─────────────────────────────────────────────
// VaccinationDashboardPage
// ─────────────────────────────────────────────
class VaccinationDashboardPage extends StatefulWidget {
  const VaccinationDashboardPage({super.key});

  @override
  State<VaccinationDashboardPage> createState() =>
      _VaccinationDashboardPageState();
}

class _VaccinationDashboardPageState extends State<VaccinationDashboardPage> {
  // ── Route args / active child ────────────────
  String? _childId;
  String _childName = '';
  String? _childPhotoUrl;

  // ── Tab State ─────────────────────────────────
  bool _isBasicTab = true;
  String _selectedFilterLabel = 'الكل';

  // ── Load state ───────────────────────────────
  _LoadState _state = _LoadState.idle;
  String _errorMessage = '';

  // ── API data ─────────────────────────────────
  GetVaccinationFileResponseDto? _data;

  // ── Toggling State ───────────────────────────
  final Set<int> _togglingMilestones = {};

  // Prevents route args from overwriting a manually-selected child
  // on subsequent didChangeDependencies calls (e.g. after provider rebuilds).
  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Read route args only once — never let provider rebuilds overwrite
    // a child the user has manually selected from the switcher.
    if (!_argsLoaded) {
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

    // Always ensure children list is loaded for the dropdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fp = context.read<FamilyProvider>();
      if (fp.status == FamilyStatus.initial) fp.loadChildren();
    });
  }

  // ─────────────────────────────────────────────
  // Load data from API
  // ─────────────────────────────────────────────
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
      // Survey not completed → redirect to welcome
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
          _isBasicTab = true;
          _selectedFilterLabel = 'الكل';
        });
      } catch (e) {
        debugPrint('Parse error: $e');
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

  // ─────────────────────────────────────────────
  // Optimistic Toggle Logic
  // ─────────────────────────────────────────────
  Future<void> _onToggleVaccination(
      VaccinationCardDto item, bool newValue) async {
    if (_togglingMilestones.contains(item.milestoneId)) return;

    setState(() {
      _togglingMilestones.add(item.milestoneId);
      _updateVaccinationInTree(item.milestoneId, newValue);
    });

    final (success, message) = await AuthService().toggleVaccination(
      childId: _childId!,
      milestoneId: item.milestoneId,
      isTaken: newValue,
    );

    if (!mounted) return;

    setState(() {
      _togglingMilestones.remove(item.milestoneId);
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: _kFont)),
          backgroundColor: const Color(0xFF00B050),
        ),
      );
      // Background reload to update filters/chips properly
      _loadDataBackground();
    } else {
      // Rollback
      setState(() {
        _updateVaccinationInTree(item.milestoneId, !newValue);
      });
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: _kFont)),
          backgroundColor: const Color(0xFFFF0B0B),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _updateVaccinationInTree(int milestoneId, bool isTaken) {
    if (_data == null) return;

    List<VaccinationCardDto> updateList(List<VaccinationCardDto> list) {
      return list.map((v) {
        if (v.milestoneId == milestoneId) {
          return v.copyWith(isTaken: isTaken);
        }
        return v;
      }).toList();
    }

    _data = _data!.copyWith(
      mainVaccinations: _data!.mainVaccinations.copyWith(
        vaccinations: updateList(_data!.mainVaccinations.vaccinations),
      ),
      additionalVaccinations: _data!.additionalVaccinations.copyWith(
        vaccinations: updateList(_data!.additionalVaccinations.vaccinations),
      ),
    );
  }

  Future<void> _loadDataBackground() async {
    if (_childId == null) return;
    final (rawData, statusCode, _) =
        await AuthService().getVaccinationFile(_childId!);
    if (!mounted || statusCode != 200 || rawData == null) return;
    try {
      final dto = GetVaccinationFileResponseDto.fromJson(rawData);
      setState(() {
        _data = dto;
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Filtered vaccination list (current tab)
  // ─────────────────────────────────────────────
  List<VaccinationCardDto> get _filteredVaccinations {
    return _isBasicTab
        ? (_data?.mainVaccinations.vaccinations ?? [])
        : (_data?.additionalVaccinations.vaccinations ?? []);
  }

  // ─────────────────────────────────────────────
  // Handle "التطعيمات الاضافية" tab tap
  // ─────────────────────────────────────────────
  void _onAdditionalTabTapped() {
    if (_data == null) return;

    // Server already tells us if the tab is available
    if (!_data!.additionalVaccinations.isAvailable) {
      // This shouldn't be tappable, but guard anyway
      _showUnderAgeDialog();
      return;
    }

    setState(() {
      _isBasicTab = false;
      _selectedFilterLabel = 'الكل';
    });
  }

  void _showUnderAgeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.child_care_rounded,
                    color: Color(0xFFF59E0B), size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'الطفل لم يكمل 4 سنوات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تتوفر التطعيمات الإضافية للأطفال الذين\nأتموا 4 سنوات فأكثر',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  color: _kGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('حسناً',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Child switcher
  // ─────────────────────────────────────────────
  void _showChildSwitcher(List<ChildModel> children) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildSwitcherSheet(
        children: children,
        currentChildId: _childId,
        onChildSelected: (child) {
          setState(() {
            _childId = child.childId;
            _childName = child.fullName;
            _childPhotoUrl = child.photoUrl;
            _isBasicTab = true;
            _selectedFilterLabel = 'الكل';
          });
          _loadData();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool additionalAvailable =
        _data?.additionalVaccinations.isAvailable ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 12),

              // ── Tab toggle (hide additional if not available) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabToggle(additionalAvailable),
              ),
              const SizedBox(height: 12),

              // ── Filter chips ─────────────────────────────
              _buildFilterChips(),
              const SizedBox(height: 16),

              // ── Content ──────────────────────────────────
              Expanded(child: _buildContent()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Image.asset('images/chat info.png', width: 56, height: 56),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFBE8EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2D5DC), width: 1.5),
              ),
              child: Center(
                child: Image.asset('images/left arrow.png',
                    width: 20, height: 20, color: _kPrimary),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Text(
            'تطعيمات $_childName',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),

          // Child selector dropdown
          Consumer<FamilyProvider>(builder: (ctx, fp, _) {
            return GestureDetector(
              onTap:
                  fp.hasChildren ? () => _showChildSwitcher(fp.children) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: ClipOval(
                      child:
                          _childPhotoUrl != null && _childPhotoUrl!.isNotEmpty
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
                  const SizedBox(width: 4),
                  Text(
                    _childName.isNotEmpty ? _childName : 'الطفل',
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Colors.black),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab Toggle
  // ─────────────────────────────────────────────
  Widget _buildTabToggle(bool additionalAvailable) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          // Basic tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isBasicTab = true;
                _selectedFilterLabel = 'الكل';
              }),
              child: _tabItem('التطعيمات الاساسية', _isBasicTab),
            ),
          ),
          // Additional tab
          Expanded(
            child: GestureDetector(
              onTap: additionalAvailable ? _onAdditionalTabTapped : null,
              child: Opacity(
                opacity: additionalAvailable ? 1.0 : 0.45,
                child: _tabItem('التطعيمات الاضافية', !_isBasicTab),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      decoration: BoxDecoration(
        color: active ? _kPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _kGrey,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Filter Chips
  // ─────────────────────────────────────────────
  Widget _buildFilterChips() {
    final m = _data?.mainVaccinations;
    final a = _data?.additionalVaccinations;

    // Counts per filter
    final int c0 = _isBasicTab ? (m?.allCount ?? 0) : (a?.allCount ?? 0);
    final int c1 = _isBasicTab ? (m?.currentCount ?? 0) : 0;
    final int c2 = _isBasicTab ? (m?.missedCount ?? 0) : 0;
    final int c3 =
        _isBasicTab ? (m?.upcomingCount ?? 0) : (a?.upcomingCount ?? 0);
    final int c4 = _isBasicTab ? (m?.doneCount ?? 0) : (a?.doneCount ?? 0);

    final chips = <(String label, int count)>[
      ('الكل', c0),
      if (_isBasicTab) ('الحال', c1),
      if (_isBasicTab) ('الفائت', c2),
      ('القادم', c3),
      ('تم', c4),
    ];

    // Reset label if it's invalid for this tab
    final validLabels = chips.map((c) => c.$1).toList();
    if (!validLabels.contains(_selectedFilterLabel)) {
      _selectedFilterLabel = 'الكل';
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final isSelected = _selectedFilterLabel == chip.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterLabel = chip.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimaryLight : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isSelected ? _kPrimary : _kBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chip.$1,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _kPrimary : _kGrey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${chip.$2}',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _kGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Content area
  // ─────────────────────────────────────────────
  Widget _buildContent() {
    // No child selected yet — prompt the user to use the dropdown.
    if (_childId == null) {
      return Center(
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
            const Text(
              'اختر الطفل من القائمة أعلاه',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط على اسم الطفل في الزاوية اليمنى\nلعرض سجل تطعيماته',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: _kFont, fontSize: 13, color: _kGrey, height: 1.5),
            ),
          ],
        ),
      );
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
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: _kFont, fontSize: 14, color: _kGrey),
                ),
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
        return _buildVaccinationList();
    }
  }

  // ─────────────────────────────────────────────
  // Vaccination list (grouped)
  // ─────────────────────────────────────────────
  Widget _buildVaccinationList() {
    final items = _filteredVaccinations;

    // Group by labelEn
    final current = items.where((v) => v.labelEn == 'Current').toList();
    final missed = items.where((v) => v.labelEn == 'Missed').toList();
    final upcoming = items.where((v) => v.labelEn == 'Upcoming').toList();
    final done = items.where((v) => v.labelEn == 'Done').toList();

    // Build sections depending on active filter
    final sections = <Widget>[];

    void addSection(
        String title, List<VaccinationCardDto> sectionItems, String emptyMsg) {
      sections.add(_SectionHeader(title: title, count: sectionItems.length));
      if (sectionItems.isEmpty) {
        sections.add(_EmptySection(message: emptyMsg));
      } else {
        for (final item in sectionItems) {
          sections.add(_VaccinationCard(
            item: item,
            isToggling: _togglingMilestones.contains(item.milestoneId),
            onToggleChanged: (val) => _onToggleVaccination(item, val),
            childId: _childId!,
            childName: _childName,
          ));
          sections.add(const SizedBox(height: 12));
        }
      }
      sections.add(const SizedBox(height: 16));
    }

    final String activeLabel = _selectedFilterLabel;
    final bool showAll = activeLabel == 'الكل';

    if (_isBasicTab) {
      if (showAll || activeLabel == 'الحال')
        addSection(
            'جرعات حالية', current, 'يبدو انه لا يوجد تطعيم في الوقت الحال');
      if (showAll || activeLabel == 'الفائت')
        addSection('جرعات فائتة', missed,
            'رائع! يبدو انه لا يوجد تطعيم فائت في الوقت الحال');
      if (showAll || activeLabel == 'القادم')
        addSection('جرعات قادمة', upcoming,
            'رائع! يبدو انه تم اتمام جميع التطعيمات  انتم حقاً والدين مميزين');
      if (showAll || activeLabel == 'تم')
        addSection('جرعات تمت', done,
            'رائع! يبدو انه لا يوجد تطعيمات فائتة انتم حقاً والدين مميزين');
    } else {
      // Additional tab chips: الكل, القادم, تم
      if (showAll || activeLabel == 'القادم')
        addSection('جرعات قادمة', upcoming,
            'رائع! تم اتمام جميع التطعيمات الإضافية القادمة');
      if (showAll || activeLabel == 'تم')
        addSection('جرعات تمت', done, 'لا توجد تطعيمات إضافية مكتملة بعد');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: sections,
    );
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty section state
// ─────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              color: _kGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Vaccination Card
// ─────────────────────────────────────────────
class _VaccinationCard extends StatefulWidget {
  final VaccinationCardDto item;
  final ValueChanged<bool> onToggleChanged;
  final bool isToggling;
  final String childId;
  final String childName;

  const _VaccinationCard({
    required this.item,
    required this.onToggleChanged,
    this.isToggling = false,
    required this.childId,
    this.childName = 'طفلك',
  });

  @override
  State<_VaccinationCard> createState() => _VaccinationCardState();
}

class _VaccinationCardState extends State<_VaccinationCard> {
  String? _savedReminderDate; // null means not yet fetched or not set

  @override
  void initState() {
    super.initState();
    _fetchReminderDate();
  }

  Future<void> _fetchReminderDate() async {
    final data = await VaccinationReminderService.getReminderSettings(
        widget.childId, widget.item.milestoneId);
    if (!mounted) return;
    if (data != null && data['appointmentDate'] != null) {
      final parsed = DateTime.tryParse(data['appointmentDate'].toString());
      if (parsed != null) {
        setState(() {
          _savedReminderDate = DateFormat('d MMMM yyyy', 'ar').format(parsed);
        });
        return;
      }
    }
    if (mounted) setState(() => _savedReminderDate = null);
  }

  VaccinationCardDto get item => widget.item;
  bool get _isDone => item.labelEn == 'Done';
  bool get _isMissed => item.labelEn == 'Missed';
  bool get _isCurrent => item.labelEn == 'Current';

  Color get _borderColor {
    if (_isMissed) return const Color(0xFFFF0B0B);
    if (_isDone) return const Color(0xFF00B050);
    if (_isCurrent) return const Color(0xFFFF8A00);
    return _kPrimary;
  }

  Color get _bgColor {
    if (_isMissed) return const Color(0xFFFFF7F7);
    return Colors.white;
  }

  Color get _titleColor {
    if (_isMissed) return const Color(0xFFFF0B0B);
    return Colors.black;
  }

  Color get _badgeBgColor {
    if (_isMissed) return const Color(0xFFFFE5E5);
    if (_isDone) return const Color(0xFFE5F7ED);
    if (_isCurrent) return const Color(0xFFFFF3E0);
    return const Color(0xFFFBE8EC);
  }

  Color get _badgeTextColor {
    if (_isMissed) return const Color(0xFFFF0B0B);
    if (_isDone) return const Color(0xFF00B050);
    if (_isCurrent) return const Color(0xFFFF8A00);
    return _kPrimary;
  }

  String get _actionText {
    if (_isCurrent) return 'تغيير الموعد';
    if (_isMissed) return 'اعادة ضبط';
    return 'وضع تذكير';
  }

  IconData get _actionIcon {
    if (_isMissed) return Icons.sync_rounded;
    return Icons.alarm_rounded;
  }

  DateTime get _appointmentDate =>
      DateTime.tryParse(item.dueDate) ?? DateTime.now();

  Future<void> _openReminderPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VaccinationReminderPage(
          childId: widget.childId,
          milestoneId: item.milestoneId,
          vaccinationTitle: item.nameAr,
          vaccineSubtitle: item.vaccinesAr,
          statusLabel: item.label,
          reminderDate: _appointmentDate,
          appointmentDate: _appointmentDate,
          statusColor: _badgeTextColor,
          statusBackgroundColor: _badgeBgColor,
          accentColor: _borderColor,
          childName: widget.childName,
        ),
      ),
    );
    // Refresh the reminder date shown on the card
    if (mounted) _fetchReminderDate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: _borderColor, width: 6),
          ),
        ),
        padding:
            const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Title and Badge ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nameAr,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.vaccinesAr,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 12,
                          color: _kGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _badgeBgColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: _buildBadgeContent(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Middle Row: Dates ──────────────────────────────
            if (!_isDone) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildInfoItem(
                      'images/syringe.png', 'الموعد', item.dueDateFormatted),
                  const SizedBox(width: 48),
                  _buildInfoItem(Icons.notifications_active_outlined, 'التذكير',
                      _savedReminderDate ?? 'غير محدد'),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
            ],

            // ── Bottom Row: Action, Switch, Help ──────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isDone) ...[
                  // Action Button
                  GestureDetector(
                    onTap: _openReminderPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _borderColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_actionIcon, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(_actionText,
                              style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],

                // "تم؟" Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تم؟',
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 1.1,
                      child: CupertinoSwitch(
                        value: item.isTaken,
                        activeColor: const Color(0xFF00B050),
                        trackColor: const Color(0xFFE2E8F0),
                        onChanged: (item.isDisabled || widget.isToggling)
                            ? null
                            : widget.onToggleChanged,
                      ),
                    ),
                  ],
                ),

                // "ما هذا؟" Help Link
                GestureDetector(
                  onTap: () {}, // TODO: info sheet
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ما هذا؟',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isDone ? Colors.black87 : _borderColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: _isDone ? Colors.black87 : _borderColor,
                          size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeContent() {
    if (_isMissed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('فائت منذ ${item.missedSinceDays ?? 0} يوم',
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _badgeTextColor)),
          const SizedBox(width: 4),
          Icon(Icons.error_outline_rounded, color: _badgeTextColor, size: 14),
        ],
      );
    }
    if (_isDone) {
      return Text(item.completedDateFormatted ?? item.dueDateFormatted,
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _badgeTextColor));
    }
    return Text(item.label,
        style: TextStyle(
            fontFamily: _kFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _badgeTextColor));
  }

  Widget _buildInfoItem(dynamic iconOrImage, String title, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _badgeBgColor,
            shape: BoxShape.circle,
          ),
          child: iconOrImage is String
              ? Center(
                  child: Image.asset(iconOrImage,
                      width: 18, height: 18, color: _badgeTextColor))
              : Icon(iconOrImage as IconData, color: _badgeTextColor, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 11, color: _kGrey)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
          ],
        )
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Child Switcher Sheet
// ─────────────────────────────────────────────
class _ChildSwitcherSheet extends StatefulWidget {
  final List<ChildModel> children;
  final String? currentChildId;
  final ValueChanged<ChildModel> onChildSelected;

  const _ChildSwitcherSheet({
    required this.children,
    required this.currentChildId,
    required this.onChildSelected,
  });

  @override
  State<_ChildSwitcherSheet> createState() => _ChildSwitcherSheetState();
}

class _ChildSwitcherSheetState extends State<_ChildSwitcherSheet> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentChildId;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('اختر الطفل',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                          color: Color(0x1A000000), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Children list
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final child = widget.children[i];
                  final isSelected = _selectedId == child.childId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedId = child.childId),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimaryLight : Colors.white,
                        border: Border.all(
                            color: isSelected ? _kPrimary : _kBorder,
                            width: isSelected ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Radio
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected
                                      ? _kPrimary
                                      : const Color(0xFFCBD5E1),
                                  width: 2),
                              color:
                                  isSelected ? _kPrimary : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.circle,
                                    color: Colors.white, size: 10)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                                color: Color(0xFFF0F0F0),
                                shape: BoxShape.circle),
                            child: ClipOval(
                              child: child.photoUrl != null &&
                                      child.photoUrl!.isNotEmpty
                                  ? Image.network(child.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person_rounded,
                                          size: 24,
                                          color: Color(0xFFBDBDBD)))
                                  : const Icon(Icons.person_rounded,
                                      size: 24, color: Color(0xFFBDBDBD)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name + age
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(child.fullName,
                                    style: const TextStyle(
                                        fontFamily: _kFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 12, color: _kGrey),
                                    const SizedBox(width: 4),
                                    Text(child.ageText,
                                        style: const TextStyle(
                                            fontFamily: _kFont,
                                            fontSize: 12,
                                            color: _kGrey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (child.isActive)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  color: _kGreen, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedId == null
                      ? null
                      : () {
                          final found = widget.children.firstWhere(
                              (c) => c.childId == _selectedId,
                              orElse: () => widget.children.first);
                          Navigator.pop(context);
                          widget.onChildSelected(found);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor: _kPrimary.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text('تأكيد',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
