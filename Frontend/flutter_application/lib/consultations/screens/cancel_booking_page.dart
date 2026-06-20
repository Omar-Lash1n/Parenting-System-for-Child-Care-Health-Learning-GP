import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';

const Color _kRed = Color(0xFFBF092F);

/// شاشة تأكيد إلغاء الحجز مع تفصيل المبلغ المسترد (صورة 6).
/// تُعرَض فقط للحجوزات المدفوعة (المؤكدة) حيث تُخصم رسوم 10% ويُسترَد 90%.
class CancelBookingPage extends StatefulWidget {
  final Booking booking;
  const CancelBookingPage({super.key, required this.booking});

  @override
  State<CancelBookingPage> createState() => _CancelBookingPageState();
}

class _CancelBookingPageState extends State<CancelBookingPage> {
  final ParentConsultationService _apiService = ParentConsultationService();
  bool _isCancelling = false;

  Booking get _booking => widget.booking;

  double get _basePrice => _booking.price;
  int get _feePercent => _booking.cancellationFeePercent;
  double get _feeAmount => _basePrice * _feePercent / 100;
  double get _refundAmount => _basePrice - _feeAmount;

  String _formatMoney(double value) {
    final isWhole = value == value.roundToDouble();
    final text = isWhole ? value.toInt().toString() : value.toStringAsFixed(2);
    return '${text}ج.م';
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

  Future<void> _confirmCancel() async {
    final confirmed = await showCancelConfirmDialog(context, withFee: true);
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await _apiService.cancelBooking(_booking.bookingId);
      if (!mounted) return;
      await showCancelSuccessDialog(context, withRefund: true);
      if (!mounted) return;
      Navigator.pop(context, true); // يعود لقائمة الحجوزات مع إعادة التحميل
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إلغاء الحجز: $e', style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
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
              const SizedBox(height: 24),
              _buildHeader('جلسة ${_formatArabicDate(_booking.appointmentDate)}'),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildBookingCard(),
                          const SizedBox(height: 20),
                          _buildBreakdownCard(),
                          const SizedBox(height: 16),
                          _buildRefundMethodCard(),
                          const SizedBox(height: 160),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildBottomButtons(),
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

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: _kRed, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    // الحجز هنا مؤكَّد دائماً (مدفوع)
    const statusColor = Color(0xFF008CFF);
    return Container(
      width: double.infinity,
      height: 155.5,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(right: BorderSide(color: _kRed, width: 4)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // التاريخ (يمين في RTL)
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
              // شارة الحالة (يسار في RTL)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 41,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _booking.statusAr,
                  style: const TextStyle(
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
          const Divider(height: 1, color: Color(0xFFD9D9D9)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // صورة الطبيب (يمين في RTL)
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
              // اسم الطبيب والتخصص (يسار الصورة) — محاذاة لليمين تحت الاسم
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

  Widget _buildBreakdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBreakdownRow('قيمة الجلسة الاساسي', _formatMoney(_basePrice), Colors.black),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          _buildBreakdownRow('رسوم الإلغاء ($_feePercent%)', '-${_formatMoney(_feeAmount)}', _kRed),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          _buildBreakdownRow('المبلغ المسترد اليكم', _formatMoney(_refundAmount), Colors.black),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.05),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'طريقة الاسترجاع',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined, color: _kRed, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سيتم إعادة المبلغ إلى محفظتك التى تم ارسال قيمة الجلسة منها خلال 5 أيام عمل',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.6,
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
        GestureDetector(
          onTap: _isCancelling ? null : _confirmCancel,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _kRed,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: _isCancelling
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'تأكيد الإلغاء وتخصم الـ $_feePercent%',
                    style: const TextStyle(
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
          onTap: _isCancelling ? null : () => Navigator.pop(context, false),
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
              'ابقاء الجلسة',
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
}

// ============================================================
// حوارات مشتركة لإلغاء الحجز (صورة 7 + صورة 8)
// ============================================================

/// حوار التأكيد قبل الإلغاء (صورة 7). يُعيد true لو أكّد الإلغاء.
/// [withFee] = true للحجوزات المدفوعة (تذكر خصم 10%).
Future<bool?> showCancelConfirmDialog(BuildContext context, {required bool withFee}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر الإغلاق (أعلى اليسار)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Color(0xFFEDEDED), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.black54, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.08), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.warning_amber_rounded, color: _kRed, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'الغاء حجز الجلسة؟',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                withFee
                    ? 'سوف يتم الغاء حجز الجلسة وخصم 10% من مبلغ حجز الجلسة'
                    : 'سوف يتم الغاء حجز الجلسة',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // الغاء الحجز (يمين في RTL — أحمر)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: const Color(0xFFFF1A1A), borderRadius: BorderRadius.circular(50)),
                        alignment: Alignment.center,
                        child: const Text(
                          'الغاء الحجز',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans Arabic',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ابقاء الحجز (يسار في RTL — أبيض)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'ابقاء الحجز',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans Arabic',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// حوار النجاح بعد الإلغاء (صورة 8).
Future<void> showCancelSuccessDialog(BuildContext context, {required bool withRefund}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.08), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_rounded, color: _kRed, size: 46),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم الغاء الحجز بنجاح',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                withRefund
                    ? 'سيتم استرجاع المبلغ خلال 5 ايام عمل وان كان هناك تاخر عن ذلك يرجى التواصل معنا'
                    : 'تم الغاء حجز الجلسة بنجاح',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(50)),
                  alignment: Alignment.center,
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
