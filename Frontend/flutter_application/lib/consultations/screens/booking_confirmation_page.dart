import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/consultations/screens/payment_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingConfirmationPage extends StatefulWidget {
  final AvailableDoctor doctor;
  final String serviceType;
  final String date;
  final String startTime;
  final String endTime;

  const BookingConfirmationPage({
    super.key,
    required this.doctor,
    required this.serviceType,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  final ParentConsultationService _apiService = ParentConsultationService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _complaintController = TextEditingController();

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _isLoading = true;
  bool _agreeTerms = false;
  bool _shareFile = false;

  // Medical file state
  bool _isFetchingMedicalFile = false;
  String? _medicalFileUrl;
  String? _medicalFileError;

  // Attached lab/radiology image
  XFile? _attachedImage;

  // Arabic day & month names
  static const _arabicDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  static const _arabicMonths = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() { _isLoading = true; });
    try {
      final patients = await _apiService.getPatients();
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ _loadPatients error: $e');
      setState(() { _isLoading = false; });
    }
  }

  String _getFormattedDate() {
    try {
      final parts = widget.date.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final dayName = _arabicDays[dt.weekday % 7];
      return '$dayName - ${dt.day} ${_arabicMonths[dt.month]} ${dt.year}';
    } catch (_) {
      return widget.date;
    }
  }

  String _getSpecLabel() {
    return widget.doctor.specialization.isNotEmpty
        ? widget.doctor.specialization
        : 'استشارة طبية';
  }

  /// جلب الملف الطبي للطفل عند تفعيل مشاركة الملف الطبي
  Future<void> _fetchMedicalFile(String childId) async {
    setState(() {
      _isFetchingMedicalFile = true;
      _medicalFileUrl = null;
      _medicalFileError = null;
    });
    final (success, urlOrError) = await _authService.getMedicalFileUrl(childId);
    if (!mounted) return;
    setState(() {
      _isFetchingMedicalFile = false;
      if (success) {
        _medicalFileUrl = urlOrError;
      } else {
        _medicalFileError = urlOrError;
      }
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(urlOrError, style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// فتح رابط الملف الطبي في المتصفح أو تطبيق خارجي
  Future<void> _openMedicalFile() async {
    if (_medicalFileUrl == null) return;
    final uri = Uri.parse(_medicalFileUrl!);
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
  }

  /// اختيار صورة تحاليل أو أشعة من المعرض
  Future<void> _pickLabImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() { _attachedImage = picked; });
    }
  }

  void _confirmBooking() {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد المريض أولاً', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على شروط الاستخدام', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          doctor: widget.doctor,
          serviceType: widget.serviceType,
          date: widget.date,
          startTime: widget.startTime,
          endTime: widget.endTime,
          patient: _selectedPatient!,
          complaintDescription: _complaintController.text.trim(),
          shareMedicalFile: _shareFile,
        ),
      ),
    );
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
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 8),
                          // Header
                          _buildHeader(),
                          const SizedBox(height: 24),
                          // Booking Summary Card
                          _buildBookingSummaryCard(),
                          const SizedBox(height: 24),
                          // Select Patient
                          _buildSelectPatientSection(),
                          const SizedBox(height: 16),
                          // Complaint Text Area
                          _buildComplaintSection(),
                          const SizedBox(height: 16),
                          // Upload Images
                          _buildUploadImagesSection(),
                          const SizedBox(height: 16),
                          // Upload Medical File — only for children (not isSelf)
                          if (_selectedPatient == null || _selectedPatient!.childId != null)
                            _buildUploadMedicalFileSection(),
                          if (_selectedPatient == null || _selectedPatient!.childId != null)
                            const SizedBox(height: 16),
                          // Terms Checkbox
                          _buildTermsCheckbox(),
                        ],
                      ),
                    ),
                    // Bottom Button
                    Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: _buildConfirmButton(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title
        Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              'تأكيد الحجز',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // Close Button
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
      ],
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(right: BorderSide(color: Color(0xFFBF092F), width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Top row: specialization badge + date/time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Specialization Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF092F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSpecLabel(),
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 14,
                    color: Color(0xFFBF092F),
                  ),
                ),
              ),
              // Date & Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من ${widget.startTime} الى ${widget.endTime}',
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
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFD9D9D9)),
          const SizedBox(height: 16),
          // Doctor Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Doctor Name & Spec
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.doctor.fullName,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'طبيب ${widget.doctor.specialization}',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Doctor Photo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  color: Colors.white,
                ),
                child: widget.doctor.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          widget.doctor.profileImageUrl!,
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

  Widget _buildSelectPatientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'تحديد المريض*',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 99,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: _patients.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final patient = _patients[index];
              final isSelected = _selectedPatient == patient;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedPatient = patient; });
                  // إذا كانت مشاركة الملف الطبي مفعّلة وكان الطفل له childId، اجلب ملفه الطبي
                  if (_shareFile && patient.childId != null) {
                    _fetchMedicalFile(patient.childId!);
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: const Color(0xFFBF092F), width: 2.5)
                            : null,
                      ),
                      child: ClipOval(
                        child: patient.imageUrl != null
                            ? Image.network(
                                patient.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF6E4D0),
                                  child: const Icon(Icons.person, color: Colors.grey, size: 36),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF6E4D0),
                                child: const Icon(Icons.person, color: Colors.grey, size: 36),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 74,
                      child: Text(
                        patient.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? const Color(0xFFBF092F) : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'وصف الشكوى الحالية للمريض (اختياري)',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
          ),
          child: TextField(
            controller: _complaintController,
            maxLines: 5,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'اكتب ملاحظاتك هنا...',
              hintStyle: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'إرفاق صور تحاليل أو أشعة (اختيارى)',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickLabImage,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: _attachedImage != null
                    ? const Color(0xFF01A449)
                    : Colors.black.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    _attachedImage != null
                        ? '✅ ${_attachedImage!.name}'
                        : 'اضغط تحميل الصورة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 13,
                      color: _attachedImage != null
                          ? const Color(0xFF01A449)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadMedicalFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'إرفاق الملف الطبي للطفل (اختيارى)',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              // Checkbox and Label (Right side)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'مشاركة الملف الطبي',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final newValue = !_shareFile;
                          setState(() {
                            _shareFile = newValue;
                            if (!newValue) {
                              _medicalFileUrl = null;
                              _medicalFileError = null;
                            }
                          });
                          if (newValue && _selectedPatient?.childId != null) {
                            _fetchMedicalFile(_selectedPatient!.childId!);
                          } else if (newValue && _selectedPatient == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'يرجى اختيار الطفل أولاً حتى يمكن مشاركة ملفه الطبي',
                                  style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            setState(() { _shareFile = false; });
                          }
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _shareFile ? const Color(0xFFBF092F) : const Color(0xFFD9D9D9),
                              width: 1.5,
                            ),
                            color: _shareFile ? const Color(0xFFBF092F) : Colors.white,
                          ),
                          child: _shareFile
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Button (Left side)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: _shareFile && _medicalFileUrl != null ? _openMedicalFile : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _shareFile ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: _shareFile && _medicalFileUrl != null
                            ? const Color(0xFF01A449)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    child: _isFetchingMedicalFile
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBF092F)),
                          )
                        : Text(
                            'فتح الملف الطبي',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans Arabic',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: _shareFile && _medicalFileUrl != null
                                  ? const Color(0xFF01A449)
                                  : Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_medicalFileError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _medicalFileError!,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12,
                color: Colors.red,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        if (_medicalFileUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '✅ تم جلب الملف الطبي — اضغط "تحميل ملف طبي" لفتحه',
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12,
                color: Color(0xFF01A449),
              ),
              textAlign: TextAlign.right,
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: const Text(
            'أوافق على شروط الاستخدام، سياسة الإلغاء (خصم 10%)، وأقر بعلمي بأن التطبيق حلقة وصل تقنية والمسؤولية الطبية تقع بالكامل على الطبيب المعالج.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 12,
              height: 1.5,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() { _agreeTerms = !_agreeTerms; }),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreeTerms ? const Color(0xFFBF092F) : const Color(0xFFD9D9D9),
                width: 1.5,
              ),
              color: _agreeTerms ? const Color(0xFFBF092F) : Colors.white,
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _confirmBooking,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFBF092F),
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: const Text(
          'تأكيد الحجز',
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
}
