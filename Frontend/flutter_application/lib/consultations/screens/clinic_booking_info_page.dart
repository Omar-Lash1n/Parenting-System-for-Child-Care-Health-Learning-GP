import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/doctor_booking_page.dart';

class ClinicBookingInfoPage extends StatefulWidget {
  final AvailableDoctor doctor;

  const ClinicBookingInfoPage({super.key, required this.doctor});

  @override
  State<ClinicBookingInfoPage> createState() => _ClinicBookingInfoPageState();
}

class _ClinicBookingInfoPageState extends State<ClinicBookingInfoPage> {
  final ParentConsultationService _apiService = ParentConsultationService();

  BookingInfo? _bookingInfo;
  bool _isLoading = true;
  String? _error;

  // Tab: 'clinic' | 'remote'
  String _activeTab = 'clinic';

  @override
  void initState() {
    super.initState();
    _loadBookingInfo();
  }

  Future<void> _loadBookingInfo() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final info = await _apiService.getBookingInfo(widget.doctor.id);
      setState(() {
        _bookingInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء تحميل بيانات العيادة';
        _isLoading = false;
      });
    }
  }

  ClinicInfo? get _clinic => _bookingInfo?.clinic;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildServiceToggle(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFBF092F)))
                        : _error != null
                            ? _buildError()
                            : _buildBody(),
                  ),
                ],
              ),
              // Bottom button
              Positioned(
                bottom: 24,
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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Doctor info (right)
          Row(
            children: [
              // Doctor avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF6E4D0),
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
                ),
                clipBehavior: Clip.hardEdge,
                child: widget.doctor.profileImageUrl != null
                    ? Image.network(
                        widget.doctor.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.grey, size: 24),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // verified badge
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(left: 4),
                        child: const Icon(Icons.verified, color: Color(0xFF0EA5E9), size: 16),
                      ),
                      Text(
                        widget.doctor.fullName,
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.doctor.specialization,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Back button (left)
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

  // ── Service toggle ─────────────────────────────────────────────────────────

  Widget _buildServiceToggle() {
    final hasRemote = widget.doctor.hasRemote && (_bookingInfo?.remote?.isAvailable ?? false);
    final hasClinic = widget.doctor.hasClinic && (_bookingInfo?.clinic?.isAvailable ?? true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            // داخل العيادة (right tab)
            Expanded(
              child: GestureDetector(
                onTap: hasClinic
                    ? () {
                        setState(() { _activeTab = 'clinic'; });
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _activeTab == 'clinic'
                        ? const Color(0xFFBF092F)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'داخل العيادة',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: _activeTab == 'clinic'
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            // جلسة اون لاين (left tab)
            Expanded(
              child: GestureDetector(
                onTap: hasRemote
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorBookingPage(
                              doctor: widget.doctor,
                              initialServiceType: 'remote',
                            ),
                          ),
                        );
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _activeTab == 'remote'
                        ? const Color(0xFFBF092F)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'جلسة اون لاين',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: hasRemote
                          ? (_activeTab == 'remote'
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.5))
                          : Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          _buildClinicAddressCard(),
          const SizedBox(height: 16),
          _buildWorkingHoursCard(),
          const SizedBox(height: 16),
          _buildPriceCard(),
          const SizedBox(height: 16),
          _buildBookingInfoCard(),
        ],
      ),
    );
  }

  Widget _buildClinicAddressCard() {
    final address = _clinic?.fullAddress;
    return _buildInfoCard(
      title: 'عنوان العيادة',
      child: Text(
        (address != null && address.isNotEmpty) ? address : 'لم يتم تحديد العنوان',
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildWorkingHoursCard() {
    final hours = _clinic?.workingHoursFormatted ?? 'غير متاح';
    return _buildInfoCard(
      title: 'مواعيد عمل العيادة',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          hours,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    final price = _clinic?.examinationPrice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            price != null ? '${price.toInt()}ج.م' : 'غير محدد',
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const Text(
            'قيمة الكشف داخل العيادة',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return _buildInfoCard(
      title: 'معلومات الكشف',
      child: const Text(
        'احجز الآن و سيتم التواصل مع حضراتكم لتاكيد الحجز',
        style: TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  /// Generic card with title + divider + content
  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFD9D9D9), height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic', color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookingInfo,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBF092F)),
            child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Bottom button ──────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    final price = _clinic?.examinationPrice ?? widget.doctor.clinicExaminationPrice;
    final label = price != null
        ? 'حجز اقرب موعد ${price.toInt()}ج.م'
        : 'حجز اقرب موعد';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorBookingPage(
              doctor: widget.doctor,
              initialServiceType: 'clinic',
            ),
          ),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFBF092F),
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
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
