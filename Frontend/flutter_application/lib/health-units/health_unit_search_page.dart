import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/health_unit_provider.dart';
import 'package:Ajial/health-units/health_unit_results_sheet.dart';
import 'package:Ajial/health-units/health_unit_dialogs.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kMaroon = Color(0xFF7F0A1E);
const String _kFont = 'IBM Plex Sans Arabic';

// Default center of Egypt
const LatLng _kEgyptCenter = LatLng(26.8, 30.8);
const double _kDefaultZoom = 6.0;
const double _kLocationZoom = 13.0;

class HealthUnitSearchPage extends StatefulWidget {
  const HealthUnitSearchPage({super.key});

  @override
  State<HealthUnitSearchPage> createState() => _HealthUnitSearchPageState();
}

class _HealthUnitSearchPageState extends State<HealthUnitSearchPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _showResults = false;
  bool _initialDialogShown = false;

  // Filter chip data
  static const List<Map<String, String?>> _filterChips = [
    {'label': 'الكل', 'type': null},
    {'label': 'مستشفى', 'type': 'Hospital'},
    {'label': 'وحدة صحية', 'type': 'HealthUnit'},
    {'label': 'مفتوح', 'type': null},
    {'label': 'قريب', 'type': null},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialDialog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _showInitialDialog() async {
    if (_initialDialogShown) return;
    _initialDialogShown = true;

    final provider = context.read<HealthUnitProvider>();
    if (!provider.showSearchHintDialog) return;

    final goToSearch = await showSearchHintDialog(context);
    provider.dismissSearchHint();
    if (goToSearch && mounted) {
      _searchFocusNode.requestFocus();
    }
  }

  Future<void> _handleLocationRequest() async {
    final provider = context.read<HealthUnitProvider>();

    // Show location hint dialog if not dismissed
    if (provider.showLocationHintDialog) {
      final proceed = await showLocationHintDialog(context);
      provider.dismissLocationHint();
      if (!proceed || !mounted) return;
    }

    // Show custom permission dialog
    final granted = await showLocationPermissionDialog(context);
    if (!granted || !mounted) return;

    // Request system location permission & get position
    await _requestLocationAndSearch();
  }

  Future<void> _requestLocationAndSearch() async {
    final provider = context.read<HealthUnitProvider>();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى تفعيل خدمة الموقع',
              style: TextStyle(fontFamily: _kFont),
            ),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من الإعدادات',
              style: TextStyle(fontFamily: _kFont),
            ),
          ),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    provider.updateUserLocation(position.latitude, position.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        _kLocationZoom,
      ),
    );

    setState(() {
      _showResults = true;
    });
  }

  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;
    final provider = context.read<HealthUnitProvider>();
    provider.searchHealthUnits(keyword: keyword.trim());
    _searchFocusNode.unfocus();
    setState(() {
      _showResults = true;
    });
  }

  void _onFilterTap(String label) {
    final provider = context.read<HealthUnitProvider>();

    if (label == 'قريب') {
      if (provider.locationPermissionGranted &&
          provider.userLatitude != null &&
          provider.userLongitude != null) {
        provider.setFilter(label);
        setState(() => _showResults = true);
      } else {
        _handleLocationRequest();
      }
      return;
    }

    provider.setFilter(label);
    setState(() => _showResults = true);
  }

  Set<Marker> _buildMarkers(HealthUnitProvider provider) {
    return provider.healthUnits.map((unit) {
      final lat = (unit['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (unit['longitude'] as num?)?.toDouble() ?? 0;
      final id = unit['id']?.toString() ?? '';
      final nameAr = unit['nameAr'] ?? '';

      return Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: nameAr),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          provider.selectUnit(unit);
          setState(() => _showResults = true);
          _sheetController.animateTo(
            0.35,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthUnitProvider>(
      builder: (context, provider, _) {
        final initialPosition = provider.userLatitude != null
            ? LatLng(provider.userLatitude!, provider.userLongitude!)
            : _kEgyptCenter;
        final initialZoom =
            provider.userLatitude != null ? _kLocationZoom : _kDefaultZoom;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Stack(
              children: [
                // Layer 1: Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: initialZoom,
                  ),
                  markers: _buildMarkers(provider),
                  myLocationEnabled: provider.locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Layer 2: Search bar + filter chips
                SafeArea(
                  child: Column(
                    children: [
                      _buildSearchBar(provider),
                      const SizedBox(height: 8),
                      _buildFilterChips(provider),
                    ],
                  ),
                ),

                // Layer 3: Location FAB
                Positioned(
                  bottom: _showResults ? 60 : 80,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: 'location_fab',
                    backgroundColor: _kPrimary,
                    onPressed: () {
                      if (provider.locationPermissionGranted &&
                          provider.userLatitude != null) {
                        _searchController.clear();
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(provider.userLatitude!,
                                provider.userLongitude!),
                            _kLocationZoom,
                          ),
                        );
                        provider.updateUserLocation(
                          provider.userLatitude!,
                          provider.userLongitude!,
                        );
                        setState(() => _showResults = true);
                      } else {
                        _searchController.clear();
                        _handleLocationRequest();
                      }
                    },
                    child:
                        const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),

                // Layer 4: Bottom status bar
                if (provider.isLoading || provider.hasError)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomStatusBar(provider),
                  ),

                // Layer 5: Results bottom sheet
                if (_showResults && !provider.isLoading)
                  HealthUnitResultsSheet(
                    controller: _sheetController,
                    units: provider.healthUnits,
                    title: provider.searchKeyword.isNotEmpty
                        ? provider.searchKeyword
                        : 'الاقرب الى',
                    searchKeyword: provider.searchKeyword,
                    onClose: () => setState(() => _showResults = false),
                    onSearchAgain: () {
                      provider.clearSearch();
                      _searchController.clear();
                      setState(() => _showResults = false);
                      _searchFocusNode.requestFocus();
                    },
                    onShowNearest: () {
                      if (provider.locationPermissionGranted &&
                          provider.userLatitude != null) {
                        provider.searchHealthUnits(
                          latitude: provider.userLatitude,
                          longitude: provider.userLongitude,
                        );
                      } else {
                        _handleLocationRequest();
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(HealthUnitProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mic icon (placeholder)
          IconButton(
            icon: const Icon(Icons.mic, color: Color(0xFF6B7280)),
            onPressed: () {},
          ),

          // Search text field
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: 'ابحث باسم المركز او الحي او المدينة...',
                hintStyle: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: _onSearch,
            ),
          ),

          // Search icon
          IconButton(
            icon: const Icon(Icons.search, color: _kPrimary),
            onPressed: () => _onSearch(_searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(HealthUnitProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _filterChips[index];
          final label = chip['label']!;
          final isSelected = provider.activeFilter == label;

          return GestureDetector(
            onTap: () => _onFilterTap(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _kPrimary : const Color(0xFFD1D5DB),
                ),
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomStatusBar(HealthUnitProvider provider) {
    if (provider.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _kMaroon,
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'جاري تحميل اقرب الاماكن...',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showResults = true),
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _kPrimary,
        child: Row(
          children: [
            const Icon(Icons.close, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'عذراً لم نتمكن من ألان الوصول',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                provider.searchHealthUnits();
              },
              child: const Text(
                'اعد المحاولة',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
