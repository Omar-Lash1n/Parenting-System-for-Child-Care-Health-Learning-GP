import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/tracking_provider.dart';

const Color _kRed = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

const _kRadiusOptions = [100.0, 250.0, 500.0, 1000.0, 2000.0, 5000.0];

String _radiusLabel(double m) {
  if (m >= 1000) return '${(m / 1000).toStringAsFixed(0)}كم';
  return '${m.toInt()}م';
}

double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final phi1 = lat1 * pi / 180;
  final phi2 = lat2 * pi / 180;
  final dPhi = (lat2 - lat1) * pi / 180;
  final dLam = (lng2 - lng1) * pi / 180;
  final a = sin(dPhi / 2) * sin(dPhi / 2) +
      cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

class GeofenceSetupScreen extends StatefulWidget {
  const GeofenceSetupScreen({super.key});

  @override
  State<GeofenceSetupScreen> createState() => _GeofenceSetupScreenState();
}

class _GeofenceSetupScreenState extends State<GeofenceSetupScreen> {
  GoogleMapController? _mapController;
  LatLng? _center;
  double _radius = 100;

  static const _defaultCamera = CameraPosition(
    target: LatLng(26.8206, 30.8025),
    zoom: 6,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<TrackingProvider>().location;
      if (loc != null && mounted) {
        final pos = LatLng(loc.latitude, loc.longitude);
        setState(() => _center = pos);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(pos, 15),
        );
      }
    });
  }

  void _onMapTap(LatLng pos) => setState(() => _center = pos);

  Future<void> _useDeviceLocation() async {
    final prov = context.read<TrackingProvider>();
    await prov.refreshOnce();
    if (!mounted) return;
    final loc = prov.location;
    if (loc == null) return;
    final pos = LatLng(loc.latitude, loc.longitude);
    setState(() => _center = pos);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  Future<void> _onConfirm() async {
    if (_center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اضغط على الخريطة لتحديد مركز سور الحماية',
              style: TextStyle(fontFamily: _kFont)),
          backgroundColor: _kRed,
        ),
      );
      return;
    }

    final prov = context.read<TrackingProvider>();
    final loc = prov.location;

    // Warn if device is currently outside the chosen circle
    if (loc != null) {
      final dist = _haversineMeters(
        loc.latitude, loc.longitude,
        _center!.latitude, _center!.longitude,
      );
      if (dist > _radius) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('الجهاز خارج النطاق',
                  style: TextStyle(
                      fontFamily: _kFont, fontWeight: FontWeight.bold)),
              content: const Text(
                'الجهاز حالياً خارج نطاق سور الحماية الذي حددته.\nهل تريد الاستمرار؟',
                style: TextStyle(fontFamily: _kFont, height: 1.6),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء',
                      style: TextStyle(fontFamily: _kFont, color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('استمرار',
                      style: TextStyle(
                          fontFamily: _kFont, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
        if (proceed != true) return;
      }
    }

    await prov.setGeofenceCenter(_center!.latitude, _center!.longitude);
    await prov.setGeofenceRadius(_radius);
    await prov.setGeofenceEnabled(true);
    if (mounted) Navigator.of(context).pop();
  }

  Set<Marker> get _markers {
    if (_center == null) return {};
    return {
      Marker(
        markerId: const MarkerId('geo_center'),
        position: _center!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Set<Circle> get _circles {
    if (_center == null) return {};
    return {
      Circle(
        circleId: const CircleId('geo_preview'),
        center: _center!,
        radius: _radius,
        fillColor: _kRed.withAlpha(40),
        strokeColor: _kRed,
        strokeWidth: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = context.watch<TrackingProvider>().location != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-screen map ─────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: _defaultCamera,
              markers: _markers,
              circles: _circles,
              onMapCreated: (c) => _mapController = c,
              onTap: _onMapTap,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),

            // ── Header ──────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward,
                            color: _kRed, size: 22, textDirection: TextDirection.ltr),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Text(
                        'اختر مركز سور الحماية',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: _kFont,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // ── Instruction chip when no center picked ──────────────────────
            if (_center == null)
              Positioned(
                top: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'اضغط على الخريطة لتحديد المركز',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: _kFont,
                          fontSize: 13),
                    ),
                  ),
                ),
              ),

            // ── Bottom control card ─────────────────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Use device location button
                    if (hasLocation) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _useDeviceLocation,
                        icon: const Icon(Icons.my_location,
                            color: _kRed, size: 18),
                        label: const Text(
                          'استخدم موقع الجهاز الحالي',
                          style: TextStyle(
                              fontFamily: _kFont,
                              color: Colors.black87,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Radius label
                    const Text(
                      'نطاق سور الحماية',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          fontFamily: _kFont,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 8),

                    // Radius chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: _kRadiusOptions.map((r) {
                          final selected = r == _radius;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _radius = r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color:
                                      selected ? _kRed : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _radiusLabel(r),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: _kFont,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _center != null
                              ? _kRed
                              : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                        onPressed: _center != null ? _onConfirm : null,
                        child: const Text(
                          'تأكيد إعداد سور الحماية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: _kFont,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
