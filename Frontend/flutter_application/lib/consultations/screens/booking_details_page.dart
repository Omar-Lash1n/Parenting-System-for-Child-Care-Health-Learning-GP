import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';

class BookingDetailPage extends StatefulWidget {
  final Booking booking;
  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final ParentConsultationService _apiService = ParentConsultationService();
  Booking? _bookingDetail;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  Booking get _booking => _bookingDetail ?? widget.booking;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _apiService.getBookingDetail(widget.booking.bookingId);
      setState(() {
        _bookingDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to load booking details: $e');
      setState(() {
        _error = 'حدث خطأ أثناء تحميل تفاصيل الحجز: $e';
        _isLoading = false;
      });
    }
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

  Future<void> _handleCancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إلغاء الحجز', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic', color: Color(0xFFBF092F))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _isCancelling = true; });

    try {
      final currentBooking = _booking;
      if (currentBooking.attachments.isNotEmpty) {
        // We have attachments, delete them (specifically the first/receipt attachment)
        final attachmentId = currentBooking.attachments.first.id;
        await _apiService.deleteBookingAttachment(currentBooking.bookingId, attachmentId);
      } else {
        // Fallback to normal cancel booking if no attachment exists
        await _apiService.cancelBooking(currentBooking.bookingId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الحجز بنجاح', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Pop back to list and trigger reload
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إلغاء الحجز: $e', style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() { _isCancelling = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _booking.status == 'pending_payment' || _booking.status == 'pending_review'
        ? const Color(0xFFFE8401)
        : _booking.status == 'confirmed'
            ? const Color(0xFF28A745)
            : const Color(0xFF8E8E93);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFBF092F)))
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'IBM Plex Sans Arabic'), textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadBookingDetails,
                                    child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _buildBookingCard(statusColor),
                                      const SizedBox(height: 24),
                                      _buildInstructionsCard(),
                                      const SizedBox(height: 140), // Spacing for bottom buttons
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 24,
                                  left: 0,
                                  right: 0,
                                  child: _buildBottomButtons(),
                                ),
                              ],
                            ),
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
            'تفاصيل الحجز',
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

  Widget _buildBookingCard(Color statusColor) {
    return Container(
      width: double.infinity,
      height: 155.5,
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
              // Tag
              Container(
                width: 120,
                height: 41,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _booking.statusAr,
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
                    _formatArabicDate(_booking.appointmentDate),
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من ${_booking.startTime} الى ${_booking.endTime} . ${_booking.durationMinutes} دقيقة',
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
                    _booking.doctorName,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _booking.specialization,
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
                child: _booking.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _booking.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFBF092F).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFFBF092F).withValues(alpha: 0.25), style: BorderStyle.solid), // dashed in wireframe
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إرشادات هامة قبل بدء المكالمة',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFFBF092F), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'يرجى التواجد داخل هذه الصفحة قبل الموعد بـ 5د.',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFFBF092F), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'تأكد من جودة الإنترنت وإضاءة الغرفة حول المريض',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Disabled Primary Button (دخول الجلسة)
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: const Text(
            'دخول الجلسة',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Color(0x80000000), // opacity: 0.5
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Active Cancel Button (إلغاء الحجز)
        if (_booking.canCancel)
          GestureDetector(
            onTap: _isCancelling ? null : _handleCancelBooking,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
              child: _isCancelling
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text(
                      'إلغاء الحجز',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
