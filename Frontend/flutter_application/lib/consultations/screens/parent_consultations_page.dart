import 'package:flutter/material.dart';
import 'package:Ajial/consultations/widgets/consultation_onboarding_dialog.dart';

// --- Mock Data Models ---
class DoctorMock {
  final String id;
  final String name;
  final String specialization;
  final String imageUrl;
  final String description;
  final double? onlinePrice;
  final double? clinicPrice;

  DoctorMock({
    required this.id,
    required this.name,
    required this.specialization,
    required this.imageUrl,
    required this.description,
    this.onlinePrice,
    this.clinicPrice,
  });
}

class ParentConsultationsPage extends StatefulWidget {
  const ParentConsultationsPage({super.key});

  @override
  State<ParentConsultationsPage> createState() =>
      _ParentConsultationsPageState();
}

class _ParentConsultationsPageState extends State<ParentConsultationsPage> {
  // Mock Data
  final List<DoctorMock> _allDoctors = [
    DoctorMock(
      id: '1',
      name: 'د. محمد ابراهيم',
      specialization: 'اسنان',
      imageUrl: 'https://i.pravatar.cc/150?img=11',
      description:
          'طبيب أسنان الأطفال، نؤمن بأن وقاية أسنان طفلك تبدأ من الصغر. متخصصة في علاج عصب الأسنان اللبنية، تركيبات الأسنان الوقائية للأطفال، وتعديل ....',
      onlinePrice: 220,
      clinicPrice: 250,
    ),
    DoctorMock(
      id: '2',
      name: 'د. احمد سمير',
      specialization: 'اسنان',
      imageUrl: 'https://i.pravatar.cc/150?img=12',
      description:
          'طبيب أسنان الأطفال، نؤمن بأن وقاية أسنان طفلك تبدأ من الصغر. متخصصة في علاج عصب الأسنان اللبنية، تركيبات الأسنان الوقائية للأطفال، وتعديل ....',
      onlinePrice: 220,
      clinicPrice: null,
    ),
    DoctorMock(
      id: '3',
      name: 'د. سارة محمود',
      specialization: 'باطنه',
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      description:
          'طبيب باطنة أطفال، خبرة في تشخيص وعلاج أمراض الجهاز الهضمي والتنفسي والمناعة لدى الأطفال منذ الولادة وحتى المراهقة.',
      onlinePrice: null,
      clinicPrice: 250,
    ),
    DoctorMock(
      id: '4',
      name: 'د. نورهان علي',
      specialization: 'تغذية',
      imageUrl: 'https://i.pravatar.cc/150?img=9',
      description:
          'أخصائية تغذية علاجية للأطفال، متابعة حالات السمنة والنحافة ونقص النمو وتصميم أنظمة غذائية صحية متوازنة.',
      onlinePrice: 150,
      clinicPrice: 200,
    ),
    DoctorMock(
      id: '5',
      name: 'د. مصطفى كمال',
      specialization: 'تربية و سلوك',
      imageUrl: 'https://i.pravatar.cc/150?img=14',
      description:
          'أخصائي تعديل سلوك وتربية خاصة، مساعدة الأطفال على التخلص من العادات السلبية وتعزيز المهارات الاجتماعية والتواصل.',
      onlinePrice: 300,
      clinicPrice: 350,
    ),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Mock search history
  List<String> _searchHistory = [
    'عيادات تربوية',
    'عيادات تربوية', // Added duplicate to match screenshot visual if needed, though usually history is distinct
    'عيادات تربوية',
    'عيادات سلوكية',
    'عيادات سلوكية',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure distinct history
    _searchHistory = _searchHistory.toSet().toList();

    _searchFocusNode.addListener(() {
      setState(() {}); // Rebuild to show/hide history dropdown
    });

    // Show the onboarding dialog right after the page is built for the first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConsultationOnboardingDialog(context);
    });
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
        // Add to history if not exists, bring to top if exists
        _searchHistory.remove(query.trim());
        _searchHistory.insert(0, query.trim());
        _searchQuery = query.trim();
      });
    }
    _searchFocusNode.unfocus();
  }

  void _selectHistoryItem(String item) {
    _searchController.text = item;
    _submitSearch(item);
  }

  List<String> get _categories {
    final Set<String> specs = _allDoctors.map((d) => d.specialization).toSet();
    return ['الكل', ...specs];
  }

  List<DoctorMock> get _filteredDoctors {
    return _allDoctors.where((doctor) {
      final matchesSearch = doctor.name.contains(_searchQuery) ||
          doctor.specialization.contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'الكل' ||
          doctor.specialization == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
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
                color: Color(0xFFFEE2E2), // Light red background circle
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
                // TODO: Handle menu selection
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
            // Main Content (Filters and Cards)
            Column(
              children: [
                const SizedBox(height: 64), // Space for search bar to overlay
                // Tab Bar (Filters)
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
                                _searchFocusNode.unfocus(); // Unfocus search when selecting category
                              });
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

                // Doctor Cards List or Empty State
                Expanded(
                  child: _filteredDoctors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'images/consultations/search.png',
                                width: 80,
                                height: 80,
                                // color: const Color(0xFF94A3B8), // Apply gray tint if needed, removing to match original image colors
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'يبدو انه لا يتوفر نتائج بحث للكلمة',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  color: Color(0xFF64748B),
                                  fontSize: 16,
                                ),
                              ),
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
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (context, index) {
                            return _buildDoctorCard(_filteredDoctors[index]);
                          },
                        ),
                ),
              ],
            ),

            // Search Bar and History Overlay
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: _searchFocusNode.hasFocus && _searchHistory.isNotEmpty
                          ? const BorderRadius.vertical(top: Radius.circular(24))
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
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            onSubmitted: _submitSearch,
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
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.mic_none, color: Color(0xFF94A3B8)),
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ),
                  // History Dropdown Overlay
                  if (_searchFocusNode.hasFocus && _searchHistory.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _searchHistory.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = _searchHistory[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.history, color: Color(0xFF94A3B8), size: 20),
                            title: Text(
                              item,
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Sans Arabic',
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => _selectHistoryItem(item),
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

  Widget _buildDoctorCard(DoctorMock doctor) {
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
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  image: DecorationImage(
                    image: NetworkImage(doctor.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      doctor.name,
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
              // Specialization Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          // Description
          Text(
            doctor.description,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 12,
              color: Color(0xFF64748B), // Gray color
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Buttons
          Column(
            children: [
              if (doctor.onlinePrice != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF092F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'حجز جلسة اون لاين ${doctor.onlinePrice!.toInt()}ج.م',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (doctor.onlinePrice != null && doctor.clinicPrice != null)
                const SizedBox(height: 8),
              if (doctor.clinicPrice != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      'حجز كشف داخل العيادة ${doctor.clinicPrice!.toInt()}ج.م',
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
