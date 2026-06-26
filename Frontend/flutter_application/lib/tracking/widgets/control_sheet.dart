import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/tracking_provider.dart';
import '../screens/geofence_setup_screen.dart';
import 'geofence_radius_sheet.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

/// "وحدة التحكم" bottom sheet — call child, live-follow toggle, geofence toggle + radius.
Future<void> showControlSheet(BuildContext context, {required String sim}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<TrackingProvider>(),
      // Pass outer context so we can navigate after popping the sheet.
      child: _ControlSheet(sim: sim, outerContext: context),
    ),
  );
}

class _ControlSheet extends StatelessWidget {
  const _ControlSheet({required this.sim, required this.outerContext});
  final String sim;
  final BuildContext outerContext;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: sim);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _onGeofenceToggle(BuildContext context, TrackingProvider prov, bool val) {
    if (!val) {
      // Turning OFF — just disable.
      prov.setGeofenceEnabled(false);
      return;
    }

    // Turning ON — GPS must be active first.
    if (!prov.gpsEnabled) {
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب تشغيل GPS أولاً لتفعيل سور الحماية',
            style: TextStyle(fontFamily: _kFont),
          ),
          backgroundColor: _kRed,
        ),
      );
      return;
    }

    // Pop the sheet then open the setup screen.
    final nav = Navigator.of(outerContext);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: prov,
        child: const GeofenceSetupScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TrackingProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          20,
          0,
          MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18,
                          color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'وحدة التحكم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: _kFont,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // ── Row 1: Call child ────────────────────────────────────────────
            _SheetRow(
              icon: Icons.phone_in_talk_rounded,
              label: 'الاتصال بالطفل',
              trailing: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: _call,
                child: const Text(
                  'اتصل الان',
                  style: TextStyle(
                    color: Colors.black87,
                    fontFamily: _kFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // ── Row 2: Live follow toggle ────────────────────────────────────
            _SheetRow(
              icon: Icons.location_on_rounded,
              label: 'تتبع وقتي',
              trailing: Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: prov.liveFollow,
                  onChanged: prov.setLiveFollow,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _kRed,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // ── Row 3: Geofence toggle + radius pill ─────────────────────────
            _SheetRow(
              icon: Icons.shield_outlined,
              label: 'سور الحماية',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Radius pill — only relevant when geofence is on.
                  if (prov.geofence.isEnabled) ...[
                    GestureDetector(
                      onTap: () => showGeofenceRadiusSheet(
                        context,
                        currentRadius: prov.geofence.radiusMeters,
                        onConfirm: prov.setGeofenceRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              geofenceRadiusLabel(prov.geofence.radiusMeters),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: _kFont,
                                  color: Colors.black87),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 13,
                                color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Geofence enabled toggle
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: prov.geofence.isEnabled,
                      onChanged: (val) =>
                          _onGeofenceToggle(context, prov, val),
                      activeThumbColor: Colors.white,
                      activeTrackColor: _kRed,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Sheet row layout ──────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          trailing,
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: _kFont,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                color: _kPinkLight, shape: BoxShape.circle),
            child: Icon(icon, color: _kRed, size: 22),
          ),
        ],
      ),
    );
  }
}
