import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_booking_details_page.dart';

enum SlotStatus { completed, unbooked, booked }

class BookingSlot {
  final String timeText;
  final SlotStatus status;
  final DateTime startTime;
  final bool hasSymptomsData;

  BookingSlot({
    required this.timeText,
    required this.status,
    required this.startTime,
    required this.hasSymptomsData,
  });
}

class SpecialistTelemedicineBookingsPage extends StatefulWidget {
  const SpecialistTelemedicineBookingsPage({super.key});

  @override
  State<SpecialistTelemedicineBookingsPage> createState() =>
      _SpecialistTelemedicineBookingsPageState();
}

class _SpecialistTelemedicineBookingsPageState
    extends State<SpecialistTelemedicineBookingsPage> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;
  final int _initialDayIndex = 50000;
  final double _itemWidth = 73.0; // 65 width + 8 margin

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _scrollController = ScrollController(
      initialScrollOffset: (_initialDayIndex * _itemWidth) - 150,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      setState(() {
        _selectedDate = picked;
      });
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      final pickedUtc = DateTime.utc(picked.year, picked.month, picked.day);
      final diff = pickedUtc.difference(today).inDays;
      final targetIndex = _initialDayIndex + diff;

      if (_scrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
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

  List<BookingSlot> _getMockSlotsForDate(DateTime date) {
    final now = DateTime.now();
    // Only return mock data for today to demonstrate the UI
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return [
        BookingSlot(
          timeText: 'من 7 م الى 7:45 م',
          status: SlotStatus.completed,
          startTime: DateTime(date.year, date.month, date.day, 19, 0),
          hasSymptomsData: false,
        ),
        BookingSlot(
          timeText: 'من 8 م الى 8:45 م',
          status: SlotStatus.booked, // Changed to booked to test the empty state
          startTime: DateTime(date.year, date.month, date.day, 20, 0),
          hasSymptomsData: false,
        ),
        BookingSlot(
          timeText: 'موعد الآن',
          status: SlotStatus.booked,
          // Set slightly in the past so the timer is 0 and shows 'Start Session Now'
          startTime: now.subtract(const Duration(minutes: 5)),
          hasSymptomsData: true,
        ),
        BookingSlot(
          timeText: 'من 9 م الى 9:45 م',
          status: SlotStatus.booked,
          // Set to 9 PM today so the timer is dynamic and counts down
          startTime: DateTime(date.year, date.month, date.day, 21, 0),
          hasSymptomsData: true,
        ),
      ];
    }
    return [];
  }

  Widget _buildStatusWidget(BuildContext context, BookingSlot slot) {
    switch (slot.status) {
      case SlotStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF5),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Text(
            'جلسة مكتملة',
            style: TextStyle(
              fontFamily: specialistFont,
              color: specialistGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case SlotStatus.unbooked:
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
      case SlotStatus.booked:
        return InkWell(
          onTap: () {
            final dateText = '${_getArabicDayName(_selectedDate.weekday)} - ${_selectedDate.day} ${_getArabicMonthName(_selectedDate.month)} ${_selectedDate.year}';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SpecialistTelemedicineBookingDetailsPage(
                  dateText: dateText,
                  timeText: slot.timeText,
                  sessionStartTime: slot.startTime,
                  hasSymptomsData: slot.hasSymptomsData,
                  isAlreadyCompleted: slot.status == SlotStatus.completed,
                ),
              ),
            );
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
  }

  @override
  Widget build(BuildContext context) {
    final slots = _getMockSlotsForDate(_selectedDate);

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

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                        
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
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
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
              Expanded(
                child: slots.isEmpty
                    ? Center(
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
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        itemCount: slots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  slot.timeText,
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
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
