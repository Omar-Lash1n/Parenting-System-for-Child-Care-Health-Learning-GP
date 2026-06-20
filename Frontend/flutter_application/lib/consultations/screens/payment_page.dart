import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/my_bookings_page.dart';

class PaymentPage extends StatefulWidget {
  final AvailableDoctor doctor;
  final String serviceType;
  final String date;
  final String startTime;
  final String endTime;
  final Patient patient;
  final String? complaintDescription;
  final bool shareMedicalFile;

  const PaymentPage({
    super.key,
    required this.doctor,
    required this.serviceType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.patient,
    this.complaintDescription,
    required this.shareMedicalFile,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final ParentConsultationService _apiService = ParentConsultationService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  PaymentMethods? _paymentMethods;
  String _selectedMethod = 'vodafone'; // 'vodafone' or 'instapay'
  XFile? _receiptImage;

  double get _price => widget.serviceType == 'remote'
      ? (widget.doctor.remoteSessionPrice ?? 0)
      : (widget.doctor.clinicExaminationPrice ?? 0);

  String get _sessionTypeLabel => widget.serviceType == 'remote' ? 'اون لاين' : 'عيادة';

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _apiService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل طرق الدفع';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickReceiptImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _receiptImage = picked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'))),
      );
    }
  }

  Future<void> _confirmBooking() async {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إرفاق صورة الإيصال', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final bookingId = await _apiService.createBooking(
        specialistId: widget.doctor.id,
        serviceType: widget.serviceType,
        childId: widget.patient.isSelf ? null : widget.patient.childId,
        slotDate: widget.date,
        startTime: widget.startTime,
        complaintDescription: widget.complaintDescription,
        shareMedicalFile: widget.shareMedicalFile,
      );

      int methodVal = _selectedMethod == 'vodafone' ? 1 : 2;
      await _apiService.submitBookingPayment(
        bookingId: bookingId,
        method: methodVal,
        receiptFile: _receiptImage!,
      );

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/check.png',
                    width: 65,
                    height: 65,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تم الحجز بنجاح',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'جاري مراجعة الإيصال وتأكيد الحجز، يمكنك متابعة حالة الحجز من قائمة الحجوزات.',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 259,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBF092F),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;
      // Navigate to MyBookingsPage, removing all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyBookingsPage()),
        (route) => route.isFirst,
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحجز: $e', style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() { _isSubmitting = false; });
    }
  }

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
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'IBM Plex Sans Arabic')))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildPriceSummary(),
                          const SizedBox(height: 24),
                          _buildPaymentMethodsSection(),
                          const SizedBox(height: 24),
                          _buildUploadReceiptSection(),
                          const SizedBox(height: 24),
                          _buildWarningsSection(),
                          const SizedBox(height: 32),
                          _buildConfirmButton(),
                          const SizedBox(height: 12),
                          _buildBackButton(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.black, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'حجز جلسة $_sessionTypeLabel',
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قيمة الجلسة $_sessionTypeLabel',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                '$_priceج.م',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFD9D9D9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المبلغ المطلوب',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                '$_priceج.م',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'يرجى ارسال المبلغ ($_priceج.م) على المحفظة المناسبة لك',
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (_paymentMethods?.vodafoneCashNumber != null)
          _buildMethodTile(
            value: 'vodafone',
            number: _paymentMethods!.vodafoneCashNumber!,
            imagePath: 'images/vodafonelogo.png',
          ),
        const SizedBox(height: 16),
        if (_paymentMethods?.instaPayNumber != null)
          _buildMethodTile(
            value: 'instapay',
            number: _paymentMethods!.instaPayNumber!,
            imagePath: 'images/instapaylogo.png',
          ),
      ],
    );
  }

  Widget _buildMethodTile({required String value, required String number, required String imagePath}) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() { _selectedMethod = value; }),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            // Radio Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBF092F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Number
            Text(
              number,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // Logo
            Image.asset(
              imagePath,
              height: 26,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'إرفاق صورة فاتورة التحويل',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _receiptImage == null ? _pickReceiptImage : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      _receiptImage != null ? 'تم تحميل الصورة' : 'اضغط تحميل الصورة',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        color: _receiptImage != null ? const Color(0xFF01A449) : Colors.black.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (_receiptImage != null) ...[
                // Edit Button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: _pickReceiptImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBF092F),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'تعديل',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Open Button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              FutureBuilder(
                                future: _receiptImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(snapshot.data!),
                                    );
                                  }
                                  return const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(color: Color(0xFFBF092F)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'فتح',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Upload Button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: _pickReceiptImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'تحميل صورة',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFBF092F).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFFBF092F).withValues(alpha: 0.25), style: BorderStyle.solid), // Dashed normally but solid is fine for now
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'إرشادات هامة قبل بدء الحجز',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildWarningItem('مراجعة الإيصال تستغرق من 5 إلى 15 دقيقة فقط.'),
          const SizedBox(height: 12),
          _buildWarningItem('في حال إلغاء الحجز، حقك محفوظ وسيتم إعادة المبلغ لمحفظتك بخصم 10%.'),
          const SizedBox(height: 12),
          _buildWarningItem('لا يمكن الغاء الحجز قبل موعد الجلسة ب نصف ساعة ولا يتم استرداد قيمة الحجز.'),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user_outlined, color: Color(0xFFBF092F), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _confirmBooking,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFBF092F),
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: _isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                'تأكيد الحجز وإرسال الإيصال',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: const Text(
          'السابق',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
