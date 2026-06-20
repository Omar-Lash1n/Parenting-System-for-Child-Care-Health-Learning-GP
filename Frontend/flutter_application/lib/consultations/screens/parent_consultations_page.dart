import 'package:flutter/material.dart';
import 'package:Ajial/consultations/widgets/consultation_onboarding_dialog.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/screens/doctor_booking_page.dart';
import 'package:Ajial/consultations/screens/clinic_booking_info_page.dart';
import 'package:Ajial/consultations/screens/my_bookings_page.dart';
import 'package:Ajial/consultations/screens/parent_payments_page.dart';

class ParentConsultationsPage extends StatefulWidget {
  const ParentConsultationsPage({super.key});

  @override
  State<ParentConsultationsPage> createState() =>
      _ParentConsultationsPageState();
}

class _ParentConsultationsPageState extends State<ParentConsultationsPage> {
  final ParentConsultationService _apiService = ParentConsultationService();

  List<AvailableDoctor> _doctors = [];
  List<String> _categories = ['الكل'];

  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      setState(() {});
    });

    // Listen to text changes for live search
    _searchController.addListener(() {
      setState(() {}); // update clear/mic icon
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConsultationOnboardingDialog(context);
    });

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch specialties first
      final specialties = await _apiService.getSpecialties();

      // Build categories list, avoiding duplicate "الكل"
      final specNames = specialties
          .map((s) => s.name)
          .where((name) => name.isNotEmpty && name != 'الكل')
          .toList();

      // Now fetch doctors
      final doctorList = await _apiService.getDoctors(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          specialty: _selectedCategory == 'الكل' ? null : _selectedCategory);

      setState(() {
        _categories = ['الكل', ...specNames];
        _doctors = doctorList;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ _loadData error: $e');
      setState(() {
        _error = 'حدث خطأ أثناء تحميل البيانات\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctorList = await _apiService.getDoctors(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          specialty: _selectedCategory == 'الكل' ? null : _selectedCategory);

      setState(() {
        _doctors = doctorList;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ _fetchDoctors error: $e');
      setState(() {
        _error = 'حدث خطأ أثناء تحميل الأطباء\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _searchHistory.remove(query.trim());
        _searchHistory.insert(0, query.trim());
        _searchQuery = query.trim();
      });
    } else {
      setState(() {
        _searchQuery = '';
      });
    }
    _searchFocusNode.unfocus();
    _fetchDoctors();
  }

  void _selectHistoryItem(String item) {
    _searchController.text = item;
    _submitSearch(item);
  }

  Map<String, Color> _getSpecializationColors(String spec) {
    switch (spec) {
      case 'اسنان':
        return {'bg': const Color(0xFFE0F2FE), 'text': const Color(0xFF0284C7)};
      case 'باطنه':
        return {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF166534)};
      case 'تغذية':
        return {'bg': const Color(0xFFFFEDD5), 'text': const Color(0xFFC2410C)};
      case 'تربية و سلوك':
        return {'bg': const Color(0xFFF3E8FF), 'text': const Color(0xFF7E22CE)};
      default:
        return {'bg': const Color(0xFFF1F5F9), 'text': const Color(0xFF475569)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
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
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'استشارات طبية',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'bookings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyBookingsPage(),
                    ),
                  );
                } else if (value == 'finance') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentPaymentsPage(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'bookings',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حجوزاتي',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 16,
                        ),
                      ),
                      Image.asset(
                        'images/consultations/syringe.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'finance',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المعاملات المالية',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 16,
                        ),
                      ),
                      Image.asset(
                        'images/consultations/business.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 64),
                // Tab Bar
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                                _searchFocusNode.unfocus();
                              });
                              _fetchDoctors();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFEE2E2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  color: isSelected
                                      ? const Color(0xFFBF092F)
                                      : const Color(0xFF64748B),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Doctor Cards List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFBF092F)))
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : _doctors.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'images/consultations/search.png',
                                        width: 80,
                                        height: 80,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'يبدو انه لا يتوفر نتائج بحث',
                                        style: TextStyle(
                                          fontFamily: 'IBM Plex Sans Arabic',
                                          color: Color(0xFF64748B),
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty)
                                        Text(
                                          '"$_searchQuery"',
                                          style: const TextStyle(
                                            fontFamily: 'IBM Plex Sans Arabic',
                                            color: Color(0xFF64748B),
                                            fontSize: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: _doctors.length,
                                  itemBuilder: (context, index) {
                                    return _buildDoctorCard(_doctors[index]);
                                  },
                                ),
                ),
              ],
            ),

            // Search Bar
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          _searchFocusNode.hasFocus && _searchHistory.isNotEmpty
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(24))
                              : BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: _searchFocusNode.hasFocus
                          ? [
                              const BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onSubmitted: _submitSearch,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans Arabic',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'ابحث عن عيادة, تخصص, طبيب',
                              hintStyle: TextStyle(
                                fontFamily: 'IBM Plex Sans Arabic',
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF94A3B8), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _submitSearch('');
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.mic_none,
                                color: Color(0xFF94A3B8)),
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ),
                  // Search History Dropdown
                  if (_searchFocusNode.hasFocus && _searchHistory.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _searchHistory.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1, 
                          color: Colors.black.withValues(alpha: 0.05),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = _searchHistory[index];
                          return InkWell(
                            onTap: () => _selectHistoryItem(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: 'IBM Plex Sans Arabic',
                                        color: Colors.black,
                                        fontSize: 14,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Opacity(
                                    opacity: 0.5,
                                    child: Icon(
                                      Icons.backup_outlined,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(AvailableDoctor doctor) {
    final specColors = _getSpecializationColors(doctor.specialization);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  color: Colors.grey[200],
                ),
                child: doctor.profileImageUrl != null &&
                        doctor.profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          doctor.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      doctor.fullName,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'طبيب ${doctor.specialization}',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: specColors['bg'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  doctor.specialization,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    color: specColors['text'],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              if (doctor.hasRemote)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorBookingPage(
                            doctor: doctor,
                            initialServiceType: 'remote',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF092F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      doctor.remoteSessionPrice != null
                          ? 'حجز جلسة اون لاين ${doctor.remoteSessionPrice!.toInt()}ج.م'
                          : 'حجز جلسة اون لاين',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (doctor.hasRemote && doctor.hasClinic)
                const SizedBox(height: 8),
              if (doctor.hasClinic)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClinicBookingInfoPage(
                            doctor: doctor,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      doctor.clinicExaminationPrice != null
                          ? 'حجز كشف داخل العيادة ${doctor.clinicExaminationPrice!.toInt()}ج.م'
                          : 'حجز كشف داخل العيادة',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
