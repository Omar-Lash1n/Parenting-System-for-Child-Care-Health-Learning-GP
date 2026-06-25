import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/geofence.dart';
import '../models/live_location.dart';
import '../providers/tracking_provider.dart';
import '../widgets/breach_dialog.dart';
import '../widgets/control_sheet.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({
    super.key,
    this.deviceSim = '01022559963',
  });

  final String deviceSim;

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const _red = Color(0xFFBF092F);

  GoogleMapController? _mapController;
  BitmapDescriptor? _childIcon;
  LatLng? _lastPosition;
  bool _hasZoomedFirst = false;

  late final TrackingProvider _prov;

  @override
  void initState() {
    super.initState();
    _prov = context.read<TrackingProvider>();
    _prov.addListener(_onProviderUpdate);
    _buildChildMarker().then((icon) {
      if (mounted) setState(() => _childIcon = icon);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prov.startPolling();
    });
  }

  @override
  void dispose() {
    _prov.removeListener(_onProviderUpdate);
    _prov.stopPolling();
    _mapController?.dispose();
    super.dispose();
  }

  void _onProviderUpdate() {
    if (_prov.pendingBreachDialog) {
      _prov.consumeBreachDialog();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showBreachDialog(context, sim: widget.deviceSim);
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Custom circular child marker
  // ---------------------------------------------------------------------------

  Future<BitmapDescriptor> _buildChildMarker() async {
    const double size = 88;
    const double iconSize = 50;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = _red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(Icons.child_care.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: Icons.child_care.fontFamily,
          package: Icons.child_care.fontPackage,
          color: _red,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // ---------------------------------------------------------------------------
  // Map overlays
  // ---------------------------------------------------------------------------

  Set<Marker> _buildMarkers(LiveLocation? loc, bool liveFollow) {
    if (loc == null || _childIcon == null) return {};
    final pos = LatLng(loc.latitude, loc.longitude);

    if (!_hasZoomedFirst) {
      _hasZoomedFirst = true;
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    } else if (liveFollow && _lastPosition != pos) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    }
    _lastPosition = pos;

    return {
      Marker(
        markerId: const MarkerId('child'),
        position: pos,
        icon: _childIcon!,
        anchor: const Offset(0.5, 0.5),
      ),
    };
  }

  Set<Circle> _buildCircles(TrackingProvider prov) {
    final geo = prov.geofence;
    if (!geo.isEnabled || !prov.geofenceCenterSet) return {};
    final isInside = geo.lastState != GeofenceState.outside;
    return {
      Circle(
        circleId: const CircleId('geofence'),
        center: LatLng(geo.centerLat, geo.centerLng),
        radius: geo.radiusMeters,
        fillColor: isInside
            ? Colors.green.withAlpha(50)
            : Colors.red.withAlpha(50),
        strokeColor: isInside ? Colors.green : Colors.red,
        strokeWidth: 2,
      ),
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TrackingProvider>();
    final loc = prov.location;
    final isOnline = prov.isOnline;
    final markers = _buildMarkers(loc, prov.liveFollow);
    final circles = _buildCircles(prov);

    const defaultCamera = CameraPosition(
      target: LatLng(26.8206, 30.8025),
      zoom: 6,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-screen map ──────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: defaultCamera,
              markers: markers,
              circles: circles,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (c) => _mapController = c,
            ),

            // ── Top overlay: back button + title ─────────────────────────────
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  // RTL: first child → rightmost.  [button, spacer, text]
                  // renders as [text ... button].
                  children: [
                    _BackButton(),
                    const SizedBox(width: 12),
                    _buildOnlineChip(loc != null ? isOnline : null),
                    const Spacer(),
                    const Text(
                      'تتبع الطفل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBM Plex Sans Arabic',
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Offline banner ────────────────────────────────────────────────
            if (loc != null && !isOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'الجهاز غير متصل حالياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBM Plex Sans Arabic',
                    ),
                  ),
                ),
              ),

            // ── Breach banner ─────────────────────────────────────────────────
            if (prov.showBreachBanner)
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 16,
                right: 16,
                child: _BreachBannerCard(
                  onDismiss: prov.dismissBreachBanner,
                ),
              ),
          ],
        ),

        // ── Control sheet FAB ────────────────────────────────────────────────
        floatingActionButton: FloatingActionButton(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          onPressed: () =>
              showControlSheet(context, sim: widget.deviceSim),
          child: const Icon(Icons.layers),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildOnlineChip(bool? isOnline) {
    if (isOnline == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade600 : Colors.grey.shade500,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOnline ? 'متصل' : '--',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'IBM Plex Sans Arabic',
        ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.arrow_forward, color: Color(0xFFBF092F), size: 22),
      ),
    );
  }
}

// ── Breach banner card (shown on top of map while geofence is breached) ───────

class _BreachBannerCard extends StatelessWidget {
  const _BreachBannerCard({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        // RTL: first child → rightmost
        children: [
          // Dismiss X — leftmost in RTL
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 18, color: Colors.black45),
          ),
          const SizedBox(width: 10),
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'تحذير!! خرج الطفل من منطقة سور الامان',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBM Plex Sans Arabic',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'اتصل الان بالطفل او اكد اعلامك بذلك',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontFamily: 'IBM Plex Sans Arabic',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // App icon circle — rightmost in RTL
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFBF092F),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
