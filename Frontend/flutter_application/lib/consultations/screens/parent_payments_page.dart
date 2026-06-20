import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';

const String _kFont = 'IBM Plex Sans Arabic';
const Color _kPrimary = Color(0xFFBF092F);

class ParentPaymentsPage extends StatefulWidget {
  const ParentPaymentsPage({super.key});

  @override
  State<ParentPaymentsPage> createState() => _ParentPaymentsPageState();
}

class _ParentPaymentsPageState extends State<ParentPaymentsPage> {
  final ParentConsultationService _apiService = ParentConsultationService();
  List<PaymentTransaction> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getPaymentTransactions();
      setState(() {
        _payments = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء تحميل سجل المدفوعات';
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
        final monthName = [
          '',
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ][month];
        return '$day $monthName $year';
      }
    } catch (_) {}
    return dateStr;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF01A449);
      case 'rejected':
        return const Color(0xFFFF0000);
      case 'pending':
        return const Color(0xFFFE8401);
      default:
        return const Color(0xFF8E8E93);
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
                    ? const Center(
                        child: CircularProgressIndicator(color: _kPrimary),
                      )
                    : _error != null
                        ? _buildError()
                        : _payments.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                color: _kPrimary,
                                onRefresh: _loadPayments,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                  itemCount: _payments.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, i) =>
                                      _buildPaymentCard(_payments[i]),
                                ),
                              ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'images/consultations/back_arrow_red.png',
                width: 20,
                height: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'المعاملات المالية',
            style: TextStyle(
              fontFamily: _kFont,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _kFont, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: _loadPayments,
              child: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: _kFont, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مدفوعات بعد',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر هنا سجلات دفعاتك بعد إتمام الحجوزات',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              color: Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentTransaction payment) {
    final statusColor = _statusColor(payment.status);
    final isRejected = payment.status == 'rejected';
    final isApproved = payment.status == 'approved';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Doctor info + Status tag ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Doctor avatar + name (First in RTL = Right)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: const Color(0xFFD9D9D9)),
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.grey, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.doctorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _kFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            payment.serviceTypeAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Status tag (Second in RTL = Left)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.statusAr,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFD9D9D9)),
          const SizedBox(height: 12),

          // ── Row 2: موعد الجلسة ──
          _buildInfoRow(
            label: 'موعد الجلسة',
            value: _formatArabicDate(payment.appointmentDate),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFD9D9D9)),
          ),

          // ── Row 3: قيمة الجلسة ──
          _buildInfoRow(
            label: 'قيمة الجلسة',
            value: '${payment.amount.toStringAsFixed(0)} ج.م',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFD9D9D9)),
          ),

          // ── Row 4: القيمة المدفوعة + method logo ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'القيمة المدفوعة',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              // Amount + method logo
              Row(
                children: [
                  _buildMethodBadge(payment.method, payment.methodAr),
                  const SizedBox(width: 8),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Rejection reason box ──
          if (isRejected) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.05),
                border: Border.all(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'السبب',
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.rejectionReason ??
                        'يبدو أن المبلغ المرسل أقل من المطلوب، يرجى إرسال التكلفة شاملة.',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12,
                      color: Colors.black,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // "إعادة الدفع" button for rejected
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'إعادة الدفع',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],

          // ── Refund info for approved/cancelled ──
          if (isApproved) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFD9D9D9)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المبلغ المسترد بعد خصم 10%',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${(payment.amount * 0.9).toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: _kFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodBadge(String method, String methodAr) {
    final bool isVodafone = method == 'vodafone_cash';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVodafone
            ? const Color(0xFFE60000).withValues(alpha: 0.08)
            : const Color(0xFF6B25AD).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVodafone ? Icons.phone_android : Icons.account_balance_wallet,
            size: 16,
            color: isVodafone
                ? const Color(0xFFE60000)
                : const Color(0xFF6B25AD),
          ),
          const SizedBox(width: 4),
          Text(
            methodAr,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isVodafone
                  ? const Color(0xFFE60000)
                  : const Color(0xFF6B25AD),
            ),
          ),
        ],
      ),
    );
  }
}
