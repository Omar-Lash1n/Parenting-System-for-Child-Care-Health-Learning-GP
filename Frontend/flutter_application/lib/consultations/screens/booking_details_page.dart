import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/cancel_booking_page.dart';
import 'package:Ajial/consultations/screens/clinical_record_page.dart';
import 'package:Ajial/consultations/screens/parent_telemedicine_chat_page.dart';
import 'package:Ajial/consultations/screens/session_rating_page.dart';
import 'package:Ajial/consultations/widgets/clinical_record_paper.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isJoiningSession = false;

  Timer? _chatTimer;
  Duration _chatTimeLeft = Duration.zero;

  Booking get _booking => _bookingDetail ?? widget.booking;

  @override
  void initState() {
    super.initState();
    _initChatTimerIfNeeded();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    super.dispose();
  }

  void _initChatTimerIfNeeded() {
    if (_chatTimer != null || _booking.status != 'completed') return;

    try {
      final dateParts = _booking.appointmentDate.split('-');
      final endParts = _booking.endTime.split(':');
      if (dateParts.length == 3 && endParts.length >= 2) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);
        
        final sessionEnd = DateTime(year, month, day, endHour, endMinute);
        final chatDeadline = sessionEnd.add(const Duration(days: 3));
        
        _updateChatTimer(chatDeadline);
        _chatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateChatTimer(chatDeadline);
        });
      }
    } catch (_) {}
  }

  void _updateChatTimer(DateTime deadline) {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.isBefore(deadline)) {
      setState(() {
        _chatTimeLeft = deadline.difference(now);
      });
    } else {
      _chatTimer?.cancel();
      setState(() {
        _chatTimeLeft = Duration.zero;
      });
    }
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
      _initChatTimerIfNeeded();
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
    // الحجز المدفوع (المؤكد): شاشة تفصيل المبلغ المسترد مع خصم 10% (صورة 6).
    if (_booking.status == 'confirmed') {
      final cancelled = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => CancelBookingPage(booking: _booking)),
      );
      if (cancelled == true && mounted) {
        Navigator.pop(context, true); // العودة لقائمة الحجوزات مع إعادة التحميل
      }
      return;
    }

    // الحجز غير المدفوع (انتظار الدفع / المراجعة): لا رسوم ولا مبلغ مسترد — حوار تأكيد مبسّط.
    final confirmed = await showCancelConfirmDialog(context, withFee: false);
    if (confirmed != true || !mounted) return;

    setState(() { _isCancelling = true; });
    try {
      await _apiService.cancelBooking(_booking.bookingId);
      if (!mounted) return;
      await showCancelSuccessDialog(context, withRefund: false);
      if (!mounted) return;
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

  /// استدعاء API الجلسة ثم فتح رابط Google Meet لو canJoin = true
  Future<void> _handleJoinSession() async {
    setState(() { _isJoiningSession = true; });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await _apiService.getSessionStatus(_booking.bookingId);
      if (!mounted) return;
      if (session.canJoin && session.joinUrl != null) {
        final uri = Uri.parse(session.joinUrl!);
        final launched = await canLaunchUrl(uri);
        if (launched) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح رابط الجلسة', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // الطبيب لم يبدأ الجلسة بعد
        messenger.showSnackBar(
          const SnackBar(
            content: Text('الطبيب لم يبدأ الجلسة بعد، يرجى الانتظار قليلاً ثم المحاولة مجدداً', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _isJoiningSession = false; });
    }
  }


  bool _isSessionNow() {
    if (_booking.status != 'confirmed') return false;
    try {
      final dateParts = _booking.appointmentDate.split('-');
      final startParts = _booking.startTime.split(':');
      final endParts = _booking.endTime.split(':');
      if (dateParts.length == 3 && startParts.length >= 2 && endParts.length >= 2) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);
        
        final now = DateTime.now();
        final sessionStart = DateTime(year, month, day, startHour, startMinute);
        final sessionEnd = DateTime(year, month, day, endHour, endMinute);
        
        // Show button only during the exact session window (no early buffer)
        return !now.isBefore(sessionStart) && now.isBefore(sessionEnd);
      }
    } catch (_) {}
    return false;
  }

  String _getTimeLeftForSession() {
    try {
      final dateParts = _booking.appointmentDate.split('-');
      final timeParts = _booking.startTime.split(':');
      if (dateParts.length == 3 && timeParts.length >= 2) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final sessionTime = DateTime(year, month, day, hour, minute);
        final now = DateTime.now();
        
        final difference = sessionTime.difference(now);
        if (difference.isNegative) {
          return 'بدأت الجلسة بالفعل';
        }
        
        final days = difference.inDays;
        final hours = difference.inHours % 24;
        final minutes = difference.inMinutes % 60;
        
        List<String> parts = [];
        if (days > 0) {
          parts.add('$days يوم');
        }
        if (hours > 0) {
          parts.add('$hours ساعة');
        }
        if (minutes > 0) {
          parts.add('$minutes دقيقة');
        }
        
        if (parts.isEmpty) {
          return 'أقل من دقيقة على الجلسة';
        }
        
        return 'فاضل ${parts.join(' و ')} على الجلسة';
      }
    } catch (_) {}
    return 'فاضل وقت على الجلسة';
  }

  String _getActionButtonText() {
    if (_booking.status == 'pending_review') {
      return 'في انتظار تأكيد طلب الحجز';
    } else if (_booking.status == 'pending_payment') {
      return 'في انتظار إتمام الدفع';
    } else if (_booking.status == 'confirmed') {
      return _getTimeLeftForSession();
    } else if (_booking.status == 'rejected') {
      return 'تم رفض هذا الحجز';
    }
    return 'دخول الجلسة';
  }

  @override
  Widget build(BuildContext context) {
    // الجلسة المكتملة لها شاشة خاصة (الروشتة + التشخيص + التقييم).
    if (_booking.status == 'completed') {
      return _buildCompletedScaffold();
    }

    // الحجز الملغي له شاشة خاصة (صورة 10).
    if (_booking.status == 'cancelled') {
      return _buildCancelledScaffold();
    }

    final isSessionNow = _isSessionNow();
    final statusColor = isSessionNow
        ? const Color(0xFF28A745)
        : _booking.status == 'pending_payment' || _booking.status == 'pending_review'
            ? const Color(0xFFFE8401)
            : _booking.status == 'confirmed'
                ? const Color(0xFF008CFF)
                : _booking.status == 'rejected'
                    ? const Color(0xFFD32F2F)
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
                                      _buildRejectionCard(),
                                      _buildMedicalFileCard(),
                                      if (_booking.status != 'rejected') _buildInstructionsCard(),
                                      const SizedBox(height: 140),
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

  // ============================================================
  // شاشة الجلسة المكتملة (الروشتة الطبية + التشخيص + التقييم) — صورة 7
  // ============================================================

  Widget _buildCompletedScaffold() {
    const green = Color(0xFF28A745);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeader(title: 'جلسة ${_formatArabicDate(_booking.appointmentDate)}'),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildBookingCard(green),
                      const SizedBox(height: 20),
                      _buildClinicalGrid(),
                      const SizedBox(height: 20),
                      _buildChatCard(),
                      const SizedBox(height: 24),
                      _buildCompletedBottomButtons(),
                      const SizedBox(height: 16),
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

  // ============================================================
  // شاشة الحجز الملغي (صورة 10)
  // ============================================================

  Widget _buildCancelledScaffold() {
    const red = Color(0xFFBF092F);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeader(title: 'جلسة ${_formatArabicDate(_booking.appointmentDate)}'),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildBookingCard(red),
                          const SizedBox(height: 24),
                          _buildInstructionsCard(),
                          const SizedBox(height: 160),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: _buildCancelledBottomButtons(),
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

  Widget _buildCancelledBottomButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showComingSoon('طلب الجلسة من جديد'),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFBF092F),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: const Text(
              'طلب الجلسة من جديد',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showComingSoon('المساعدة في اتمام عملية الحجز'),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: const Text(
              'اريد المساعدة في اتمام عملية الحجز',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalGrid() {
    return Row(
      children: [
        // التشخيص الطبي (يمين في RTL)
        Expanded(
          child: _buildGridTile(
            label: 'التشخيص الطبي',
            icon: Icons.description_outlined,
            color: const Color(0xFFBF092F),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClinicalRecordPage(
                  bookingId: _booking.bookingId,
                  type: ClinicalRecordType.diagnosis,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // الروشتة الطبية (يسار في RTL)
        Expanded(
          child: _buildGridTile(
            label: 'الروشتة الطبية',
            icon: Icons.assignment_outlined,
            color: const Color(0xFF01A449),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClinicalRecordPage(
                  bookingId: _booking.bookingId,
                  type: ClinicalRecordType.prescription,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard() {
    final bool isTimeout = _chatTimeLeft.inSeconds <= 0;
    
    String timerText = 'انتهت فترة التحدث إلى الطبيب';
    if (!isTimeout) {
      String days = _chatTimeLeft.inDays.toString().padLeft(2, '0');
      String hours = (_chatTimeLeft.inHours % 24).toString().padLeft(2, '0');
      String minutes = (_chatTimeLeft.inMinutes % 60).toString().padLeft(2, '0');
      timerText = 'متبقي $days يوم : $hours س : $minutes ق';
    }

    return GestureDetector(
      onTap: isTimeout ? null : () {
        // Calculate the exact deadline again to pass to the chat page
        final dateParts = _booking.appointmentDate.split('-');
        final endParts = _booking.endTime.split(':');
        DateTime deadline = DateTime.now().add(const Duration(days: 3)); // Fallback
        if (dateParts.length == 3 && endParts.length >= 2) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final endHour = int.parse(endParts[0]);
          final endMinute = int.parse(endParts[1]);
          final sessionEnd = DateTime(year, month, day, endHour, endMinute);
          deadline = sessionEnd.add(const Duration(days: 3));
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentTelemedicineChatPage(
              bookingId: _booking.bookingId,
              doctorId: _booking.specialistId,
              doctorName: _booking.doctorName,
              doctorImage: _booking.photoUrl.isNotEmpty ? _booking.photoUrl : 'https://via.placeholder.com/150',
              doctorSpecialization: _booking.specialization,
              chatDeadline: deadline,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isTimeout 
                    ? Colors.grey.withValues(alpha: 0.1) 
                    : const Color(0xFF008CFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded, 
                color: isTimeout ? Colors.grey : const Color(0xFF008CFF), 
                size: 30
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'تحدث مع الطبيب',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isTimeout ? Colors.grey : Colors.black,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isTimeout 
                    ? Colors.grey.withValues(alpha: 0.08) 
                    : const Color(0xFFBF092F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timerText,
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: isTimeout ? Colors.grey.shade700 : const Color(0xFFBF092F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBottomButtons() {
    final bool rated = _booking.hasRated;
    return Column(
      children: [
        // قيم الجلسة واحصل على 250 — يظهر مرة واحدة (يصبح مُعطّلاً بعد التقييم)
        GestureDetector(
          onTap: rated ? null : _openRatingPage,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: rated
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFE8401), Color(0xFFFFA53D)],
                    ),
              color: rated ? const Color(0xFFE9E9E9) : null,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rated ? 'تم تقييم الجلسة' : 'قيم الجلسة واحصل على 250',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: rated ? Colors.black54 : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  rated ? Icons.check_circle_outline_rounded : Icons.star_border_rounded,
                  color: rated ? Colors.black54 : Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // طلب الجلسة مرة اخرى (placeholder)
        GestureDetector(
          onTap: () => _showComingSoon('طلب الجلسة مرة اخرى'),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'طلب الجلسة مرة اخرى',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openRatingPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionRatingPage(
          bookingId: _booking.bookingId,
          doctorName: _booking.doctorName,
        ),
      ),
    );
    if (result == true) {
      // أُرسل التقييم بنجاح — أعد تحميل التفاصيل كي يتحدث زر التقييم الى "تم تقييم الجلسة"
      await _loadBookingDetails();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — قريباً', style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
        backgroundColor: const Color(0xFFBF092F),
      ),
    );
  }

  Widget _buildHeader({String title = 'تفاصيل الحجز'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              'images/back_arrow_red.png',
              width: 38,
              height: 38,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
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
              // Date info (يمين في RTL)
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
              // Tag (يسار في RTL)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 41,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _isSessionNow()
                      ? 'الطبيب متاح الآن للبدء'
                      : _booking.status == 'cancelled'
                          ? 'تم الغاء الحجز'
                          : _booking.statusAr,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Spacer(),
          Divider(height: 1, color: const Color(0xFFD9D9D9)),
          const Spacer(),
          // Row 2: Doctor info (الصورة يمين + الاسم يسارها)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    if (_booking.status != 'rejected') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 24),
              const SizedBox(width: 8),
              Text(
                'سبب الرفض',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _booking.rejectionReason ?? 'لم يتم تحديد سبب للرفض',
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// بطاقة الملف الطبي — تظهر فقط لو كان هناك ملف طبي URL
  Widget _buildMedicalFileCard() {
    final url = _booking.medicalFileUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF01A449).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFF01A449).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Open file button
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا يمكن فتح الملف', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF01A449),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'فتح الملف',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الملف الطبي للطفل',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'اضغط لفتح الملف الطبي وتحميله',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.medical_services_outlined, color: Color(0xFF01A449), size: 28),
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
    final sessionNow = _isSessionNow();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sessionNow)
          GestureDetector(
            onTap: _isJoiningSession ? null : _handleJoinSession,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFBF092F),
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
              child: _isJoiningSession
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'دخول الجلسة',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Text(
              _getActionButtonText(),
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0x80000000), // opacity: 0.5
              ),
            ),
          ),
        if (_booking.canCancel && !sessionNow) ...[
          const SizedBox(height: 12),
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
      ],
    );
  }
}
