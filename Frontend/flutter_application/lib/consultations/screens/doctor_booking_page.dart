import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/booking_confirmation_page.dart';

class DoctorBookingPage extends StatefulWidget {
  final AvailableDoctor doctor;
  final String initialServiceType; // 'remote' or 'clinic'

  const DoctorBookingPage({
    super.key,
    required this.doctor,
    this.initialServiceType = 'remote',
  });

  @override
  State<DoctorBookingPage> createState() => _DoctorBookingPageState();
}

class _DoctorBookingPageState extends State<DoctorBookingPage> {
  final ParentConsultationService _apiService = ParentConsultationService();

  String _serviceType = 'remote';
  BookingInfo? _bookingInfo;
  DaySlotsResponse? _slotsResponse;
  bool _isLoading = true;
  bool _isSlotsLoading = false;
  String? _errorMessage;
  String? _error;

  DateTime _selectedDate = DateTime.now();
  List<DateTime> _weekDays = [];

  // Arabic day names
  static const _arabicDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  static const _arabicMonths = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialServiceType;
    _generateWeekDays();
    _loadBookingData();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    // Generate 7 days starting from today
    _weekDays = List.generate(7, (i) => now.add(Duration(days: i)));
    // Select today by default
    _selectedDate = now;
  }

  Future<void> _loadBookingData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final info = await _apiService.getBookingInfo(widget.doctor.id);
      setState(() {
        _bookingInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      print('⚠️ _loadBookingData fallback (booking-info not available): $e');
      // Still show the page using doctor data we already have
      setState(() {
        _bookingInfo = null;
        _isLoading = false;
      });
    }
    // Always try to fetch slots regardless of booking-info success
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() { _isSlotsLoading = true; });
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      print('🗓️ Fetching slots for doctor=${widget.doctor.id}, type=$_serviceType, date=$dateStr');
      final slots = await _apiService.getSlots(widget.doctor.id, _serviceType, dateStr);
      print('✅ Got ${slots.slots.length} slots, isAvailable=${slots.isAvailable}');
      if (mounted) {
        setState(() {
          _slotsResponse = slots;
          _isSlotsLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ _fetchSlots error: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _slotsResponse = null;
          _isSlotsLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToConfirmation(String date, String startTime, String endTime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
          doctor: widget.doctor,
          serviceType: _serviceType,
          date: date,
          startTime: startTime,
          endTime: endTime,
        ),
      ),
    );
  }

  Future<void> _bookNearestSlot() async {
    try {
      final nearest = await _apiService.getNearestSlot(widget.doctor.id, _serviceType);
      if (nearest != null && nearest.found && mounted) {
        _navigateToConfirmation(
          nearest.date,
          nearest.startTime ?? '',
          nearest.endTime ?? '',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لا توجد مواعيد متاحة حالياً',
              style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
            ),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getArabicDayName(DateTime date) => _arabicDays[date.weekday % 7];

  String _getFormattedDate() {
    final day = _getArabicDayName(_selectedDate);
    return '$day ${_selectedDate.day} ${_arabicMonths[_selectedDate.month]} ${_selectedDate.year}';
  }

  String _getMonthYear() {
    return '${_arabicMonths[_selectedDate.month]} ${_selectedDate.year}';
  }

  double? get _currentPrice {
    if (_serviceType == 'remote') {
      return _bookingInfo?.remote?.sessionPrice ?? widget.doctor.remoteSessionPrice;
    } else {
      return _bookingInfo?.clinic?.examinationPrice ?? widget.doctor.clinicExaminationPrice;
    }
  }

  int? get _sessionDuration => _bookingInfo?.remote?.sessionDurationMinutes;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFBF092F)))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic', color: Colors.red)))
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: Column(
                            children: [
                              // Doctor Header
                              _buildDoctorHeader(),
                              const SizedBox(height: 12),
                              // Service Type Toggle
                              _buildServiceToggle(),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    // Date Picker
                                    _buildDatePicker(),
                                    const SizedBox(height: 16),
                                    // Slots Card
                                    _buildSlotsCard(),
                                    const SizedBox(height: 16),
                                    // Session Info Card
                                    _buildSessionInfoCard(),
                                    const SizedBox(height: 16),
                                    // Consultation Details Card
                                    _buildConsultationDetailsCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Button
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: _buildBottomButton(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFBF092F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Color(0xFFBF092F), size: 18),
            ),
          ),
          const Spacer(),
          // Doctor Name & Specialization
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Color(0xFF0EA5E9), size: 18),
                  const SizedBox(width: 2),
                  Text(
                    widget.doctor.fullName,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'طبيب ${widget.doctor.specialization}',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
            ],
          ),
          const SizedBox(width: 11),
          // Doctor Photo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF6E4D0),
              border: Border.all(color: const Color(0xFFD9D9D9), width: 0.4),
            ),
            child: widget.doctor.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.doctor.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceToggle() {
    final bool remoteAvailable = _bookingInfo?.remote?.isAvailable ?? widget.doctor.hasRemote;
    final bool clinicAvailable = _bookingInfo?.clinic?.isAvailable ?? widget.doctor.hasClinic;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Menu icon
          Opacity(
            opacity: 0.5,
            child: Transform.rotate(
              angle: 1.5708, // 90 degrees
              child: const Icon(Icons.menu, size: 24, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          // Toggle Container
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.black.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  // Clinic Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: clinicAvailable ? () {
                        setState(() { _serviceType = 'clinic'; });
                        _fetchSlots();
                      } : null,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _serviceType == 'clinic' ? const Color(0xFFBF092F) : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'داخل العيادة',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans Arabic',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: _serviceType == 'clinic'
                                ? Colors.white
                                : clinicAvailable
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Remote Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: remoteAvailable ? () {
                        setState(() { _serviceType = 'remote'; });
                        _fetchSlots();
                      } : null,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _serviceType == 'remote' ? const Color(0xFFBF092F) : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'جلسة اون لاين',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans Arabic',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: _serviceType == 'remote'
                                ? Colors.white
                                : remoteAvailable
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      children: [
        // Month header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Calendar view button
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  locale: const Locale('ar'),
                );
                if (picked != null) {
                  setState(() { _selectedDate = picked; });
                  _generateWeekDays();
                  _fetchSlots();
                }
              },
              child: const Text(
                'عرض التقويم',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Color(0xFFBF092F),
                ),
              ),
            ),
            // Month Year + Arrow
            Row(
              children: [
                const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black),
                const SizedBox(width: 4),
                Text(
                  _getMonthYear(),
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Week days horizontal scroll
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL
            itemCount: _weekDays.length,
            itemBuilder: (context, index) {
              final date = _weekDays[index];
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month;

              return GestureDetector(
                onTap: () {
                  setState(() { _selectedDate = date; });
                  _fetchSlots();
                },
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFBF092F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? null : Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFBF092F).withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: isSelected ? 15 : 3,
                        offset: isSelected ? const Offset(0, 10) : const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getArabicDayName(date),
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header: Date + Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPrice != null)
                Text(
                  '${_currentPrice!.toInt()}ج.م',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              Text(
                _getFormattedDate(),
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFD9D9D9)),
          const SizedBox(height: 16),
          // Slots List
          if (_isSlotsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFBF092F)),
              ),
            )
          else if (_slotsResponse != null && _slotsResponse!.slots.isNotEmpty)
            ..._slotsResponse!.slots.map((slot) => _buildSlotRow(slot))
          else if (_serviceType == 'clinic' && _slotsResponse?.isAvailable == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'العيادة متاحة في هذا اليوم',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  if (_slotsResponse?.workingHoursText != null)
                    Text(
                      _slotsResponse!.workingHoursText!,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  _errorMessage ?? 'لا توجد مواعيد متاحة في هذا اليوم',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotRow(TimeSlot slot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: slot.isBooked
            ? null
            : () {
                final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                _navigateToConfirmation(dateStr, slot.startTime, slot.endTime);
              },
        child: Opacity(
          opacity: slot.isBooked ? 0.5 : 1.0,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.black.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Book Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBF092F),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    slot.isBooked ? 'محجوز' : 'حجز الان',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Time Range
                Text(
                  'من ${slot.startTime} الى ${slot.endTime}',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          // Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentPrice != null ? '${_currentPrice!.toInt()}ج.م' : '--',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                _serviceType == 'remote' ? 'قيمة الجلسة اون لاين' : 'قيمة الكشف',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFD9D9D9)),
          const SizedBox(height: 16),
          // Duration Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _sessionDuration != null ? '$_sessionDuration دقيقة' : '--',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const Text(
                'مدة الجلسة',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'معلومات الكشف',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: const Color(0xFFD9D9D9)),
          const SizedBox(height: 12),
          Text(
            _serviceType == 'remote'
                ? '"استشارة طبية مرئية عن بعد شاملة تمكنك من التواصل المباشر مع الطبيب من داخل منزلك للحفاظ على سلامة طفلك وتوفير وقتك. الخدمة مثالية للمتابعات الدورية، مراجعة نتائج التحاليل والأشعة، الاستشارات العاجلة في حالات الطفح الجلدي، نزلات البرد، أو لطلب نصائح التغذية والنمو. بعد انتهاء الجلسة، ستحصل على روشتة إلكترونية معتمدة تحتوي على التشخيص وخطة العلاج كاملة."'
                : '"كشف طبي مباشر داخل العيادة يتيح لك التواصل المباشر مع الطبيب لفحص طفلك. يشمل الفحص السريري الكامل والتشخيص وخطة العلاج."',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 12,
              height: 1.5,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final priceText = _currentPrice != null ? ' ${_currentPrice!.toInt()}ج.م' : '';
    return GestureDetector(
      onTap: _bookNearestSlot,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFBF092F),
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: Text(
          'حجز اقرب موعد$priceText',
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
