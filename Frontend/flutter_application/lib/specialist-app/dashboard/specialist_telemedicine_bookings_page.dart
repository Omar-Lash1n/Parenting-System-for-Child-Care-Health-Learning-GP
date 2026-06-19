import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/models/doctor_consultation_models.dart';
import 'package:Ajial/specialist-app/dashboard/services/doctor_consultation_api_service.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_booking_details_page.dart';

class SpecialistTelemedicineBookingsPage extends StatefulWidget {
  const SpecialistTelemedicineBookingsPage({super.key});

  @override
  State<SpecialistTelemedicineBookingsPage> createState() =>
      _SpecialistTelemedicineBookingsPageState();
}

class _SpecialistTelemedicineBookingsPageState
    extends State<SpecialistTelemedicineBookingsPage> {
  final DoctorConsultationApiService _api = DoctorConsultationApiService();

  late DateTime _selectedDate;
  late ScrollController _scrollController;
  final int _initialDayIndex = 50000;
  final double _itemWidth = 73.0; // 65 width + 8 margin

  // --- Slots state for the selected day ---
  List<DoctorSlot> _slots = [];
  bool _loadingSlots = false;
  String? _slotsError;

  // --- Calendar (booked-day dots) state for the visible month ---
  final Set<String> _bookedDates = <String>{};
  String? _loadedCalendarMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _scrollController = ScrollController(
      initialScrollOffset: (_initialDayIndex * _itemWidth) - 150,
    );
    _loadSlots();
    _loadCalendar();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // ==================== Data loading ==========================
  // ============================================================

  String _formatDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatMonthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  Future<void> _loadSlots() async {
    final requestedDate = _selectedDate;
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
    });
    try {
      final result = await _api.getSlots(_formatDateKey(requestedDate));
      // Ignore stale responses if the user moved to another day meanwhile.
      if (!mounted || requestedDate != _selectedDate) return;
      setState(() {
        _slots = result.isAvailable ? result.slots : <DoctorSlot>[];
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted || requestedDate != _selectedDate) return;
      setState(() {
        _slots = [];
        _slotsError = _cleanError(e);
        _loadingSlots = false;
      });
    }
  }

  Future<void> _loadCalendar() async {
    final month = _formatMonthKey(_selectedDate);
    if (month == _loadedCalendarMonth) return;
    try {
      final result = await _api.getCalendar(month);
      if (!mounted) return;
      setState(() {
        _loadedCalendarMonth = month;
        _bookedDates
          ..removeWhere((d) => d.startsWith('$month-'))
          ..addAll(result.bookedDates);
      });
    } catch (_) {
      // Calendar dots are a non-critical enhancement; ignore failures.
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _loadSlots();
    _loadCalendar();
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('SocketException') ||
        text.contains('connection') ||
        text.contains('Connection') ||
        text.contains('DioException')) {
      return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
    }
    return text.isEmpty ? 'تعذر الاتصال بالخادم، حاول مرة أخرى' : text;
  }

  // ============================================================
  // ==================== Date helpers ==========================
  // ============================================================

  String _getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  String _getArabicDayName(int weekday) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الاحد'
    ];
    return days[weekday - 1];
  }

  Future<void> _selectDate(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: specialistGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      _onDateSelected(picked);
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      final pickedUtc = DateTime.utc(picked.year, picked.month, picked.day);
      final diff = pickedUtc.difference(today).inDays;
      final targetIndex = _initialDayIndex + diff;

      if (_scrollController.hasClients) {
        final targetOffset =
            (targetIndex * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2) + 16;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // ============================================================
  // ==================== Slot row widget =======================
  // ============================================================

  Widget _buildStatusWidget(BuildContext context, DoctorSlot slot) {
    if (!slot.isBooked || slot.bookingId == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          'لم يتم حجز الموعد',
          style: TextStyle(
            fontFamily: specialistFont,
            color: Colors.black.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        final dateText =
            '${_getArabicDayName(_selectedDate.weekday)} - ${_selectedDate.day} ${_getArabicMonthName(_selectedDate.month)} ${_selectedDate.year}';
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpecialistTelemedicineBookingDetailsPage(
              bookingId: slot.bookingId!,
              dateText: dateText,
            ),
          ),
        );
        // The session may have ended/completed while in the details page.
        _loadSlots();
        _loadedCalendarMonth = null;
        _loadCalendar();
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: specialistGreen,
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Text(
          'عرض تفاصيل الحجز',
          style: TextStyle(
            fontFamily: specialistFont,
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ==================== Build =================================
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FAF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: specialistGreen,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'حجوزات الكشف عن بعد',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Calendar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_getArabicMonthName(_selectedDate.month)} ${_selectedDate.year}',
                            style: const TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.black, size: 24),
                        ],
                      ),
                      const Text(
                        'عرض التقويم',
                        style: TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: specialistGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Calendar Picker
              SizedBox(
                height: 90,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 100000,
                  itemExtent: _itemWidth,
                  itemBuilder: (context, index) {
                    final now = DateTime.now();
                    final date = DateTime(
                        now.year, now.month, now.day + (index - _initialDayIndex));

                    final isSelected = date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                    final hasBooking = _bookedDates.contains(_formatDateKey(date));

                    return GestureDetector(
                      onTap: () {
                        _onDateSelected(date);

                        if (_scrollController.hasClients) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final targetOffset = (index * _itemWidth) -
                              (screenWidth / 2) +
                              (_itemWidth / 2) +
                              16;
                          _scrollController.animateTo(
                            targetOffset,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 65,
                        margin: const EdgeInsets.only(left: 8, bottom: 12, top: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? specialistGreen : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade600.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getArabicDayName(date.weekday),
                              style: TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isSelected || hasBooking)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : specialistGreen,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Body
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingSlots) {
      return const Center(
        child: CircularProgressIndicator(color: specialistGreen),
      );
    }

    if (_slotsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Colors.black.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                _slotsError!,
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadSlots,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    color: specialistGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/Box.png',
              width: 100,
              height: 100,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'يبدو انه لا يتوفر كشوفات يوم ${_getArabicDayName(_selectedDate.weekday)} ${_selectedDate.day} ${_getArabicMonthName(_selectedDate.month)}\n, جرب التنقل بين الايام',
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 16,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: _slots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final slot = _slots[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slot.rangeText,
                style: const TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              _buildStatusWidget(context, slot),
            ],
          ),
        );
      },
    );
  }
}
