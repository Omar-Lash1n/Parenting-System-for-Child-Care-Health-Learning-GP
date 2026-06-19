import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/booking_details_page.dart';
import 'package:Ajial/consultations/screens/clinical_record_page.dart';
import 'package:Ajial/consultations/widgets/clinical_record_paper.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final ParentConsultationService _apiService = ParentConsultationService();
  bool _isLoading = true;
  List<Booking> _bookings = [];
  String? _error;

  /// هل يوجد روشتة لكل حجز مكتمل: null = قيد التحميل، true/false = النتيجة.
  final Map<String, bool?> _hasPrescription = {};

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await _apiService.getBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
      _loadPrescriptionFlags();
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء تحميل الحجوزات\n$e';
        _isLoading = false;
      });
    }
  }

  /// يجلب حالة وجود روشتة لكل حجز مكتمل (لإظهار "عرض الروشتة" أو "لا توجد روشتة").
  Future<void> _loadPrescriptionFlags() async {
    final completed = _bookings.where((b) => b.status == 'completed').toList();
    for (final b in completed) {
      if (_hasPrescription.containsKey(b.bookingId)) continue;
      _hasPrescription[b.bookingId] = null; // قيد التحميل
      try {
        final res = await _apiService.getPrescription(b.bookingId);
        if (!mounted) return;
        setState(() => _hasPrescription[b.bookingId] = res.hasPrescription);
      } catch (_) {
        if (!mounted) return;
        setState(() => _hasPrescription[b.bookingId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFBF092F)))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'IBM Plex Sans Arabic')))
                        : _bookings.isEmpty
                            ? const Center(
                                child: Text('لا توجد حجوزات حتى الآن',
                                    style: TextStyle(fontFamily: 'IBM Plex Sans Arabic', fontSize: 16)))
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _bookings.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _buildBookingCard(_bookings[index]);
                                },
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'الحجوزات',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFBF092F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Color(0xFFBF092F), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _formatArabicDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final dayName = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'][date.weekday - 1];
        final monthName = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'][month];
        return '$dayName - $day $monthName $year';
      }
    } catch (_) {}
    return dateStr;
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = booking.status == 'pending_payment' || booking.status == 'pending_review'
        ? const Color(0xFFFE8401)
        : booking.status == 'confirmed'
            ? const Color(0xFF008CFF)
            : booking.status == 'rejected'
                ? const Color(0xFFD32F2F)
                : const Color(0xFF8E8E93);

    final isCompleted = booking.status == 'completed';

    return Container(
      width: 343,
      height: isCompleted ? 255 : 211.5,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(right: BorderSide(color: Color(0xFFBF092F), width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Status tag + Date details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag (statusAr)
              Container(
                width: 120,
                height: 41,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  booking.statusAr,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Date info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatArabicDate(booking.appointmentDate),
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من ${booking.startTime} الى ${booking.endTime} . ${booking.durationMinutes} دقيقة',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Divider(height: 1, color: const Color(0xFFD9D9D9)),
          const Spacer(),
          // Row 2: Doctor info
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking.doctorName,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    booking.specialization,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  color: Colors.white,
                ),
                child: booking.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          booking.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 28),
              ),
            ],
          ),
          const Spacer(),
          // Row 3: Action Button
          GestureDetector(
            onTap: () async {
              final refresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailPage(booking: booking),
                ),
              );
              if (refresh == true) {
                _loadBookings();
              }
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                booking.status == 'rejected' ? 'عرض سبب الرفض' : 'عرض تفاصيل الجلسة',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Row 4: عرض الروشتة الطبية (للجلسات المكتملة فقط)
          if (isCompleted) ...[
            const SizedBox(height: 10),
            _buildPrescriptionLink(booking),
          ],
        ],
      ),
    );
  }

  /// زر "عرض الروشتة الطبية" أسفل بطاقة الجلسة المكتملة.
  /// مُفعّل عند وجود روشتة، ويظهر "لا توجد روشتة للجلسة" (مُعطّل) إذا لم يُضِف الطبيب روشتة.
  Widget _buildPrescriptionLink(Booking booking) {
    final hasPrescription = _hasPrescription[booking.bookingId];

    // قيد التحميل
    if (hasPrescription == null) {
      return const Center(
        child: Text(
          'عرض الروشتة الطبية',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0x55000000),
          ),
        ),
      );
    }

    // لا توجد روشتة — مُعطّل
    if (!hasPrescription) {
      return const Center(
        child: Text(
          'لا توجد روشتة للجلسة',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0x80000000),
          ),
        ),
      );
    }

    // توجد روشتة — مُفعّل
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClinicalRecordPage(
            bookingId: booking.bookingId,
            type: ClinicalRecordType.prescription,
          ),
        ),
      ),
      child: const Center(
        child: Text(
          'عرض الروشتة الطبية',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
