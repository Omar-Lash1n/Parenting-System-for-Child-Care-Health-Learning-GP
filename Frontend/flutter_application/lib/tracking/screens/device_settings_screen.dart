import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/tracking_provider.dart';
import '../screens/geofence_setup_screen.dart';
import '../widgets/delete_device_dialog.dart';
import '../widgets/factory_reset_dialog.dart';
import '../widgets/geofence_radius_sheet.dart';
import '../widgets/interval_sheet.dart';
import '../widgets/power_off_dialog.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

// ── Location update rate steps (seconds) ──────────────────────────────────────

const List<int> _kUpdateSteps = [5, 10, 15, 30, 60];

String _updateLabel(int seconds) {
  if (seconds < 60) return '1 مرة/$seconds ث';
  return '1 مرة/${seconds ~/ 60} دق';
}

String _intervalLabel(int seconds) {
  if (seconds < 60) return '$seconds ث';
  if (seconds < 3600) return '${seconds ~/ 60} دق';
  return '${seconds ~/ 3600} س';
}

String _radiusLabel(double meters) {
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} كم';
  return '${meters.toStringAsFixed(0)} متر';
}

// ── Location update sheet ──────────────────────────────────────────────────────

Future<void> _showLocationUpdateSheet(
  BuildContext context, {
  required int currentSeconds,
  required void Function(int) onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LocationUpdateSheet(
      currentSeconds: currentSeconds,
      onConfirm: onConfirm,
    ),
  );
}

class _LocationUpdateSheet extends StatefulWidget {
  const _LocationUpdateSheet({
    required this.currentSeconds,
    required this.onConfirm,
  });
  final int currentSeconds;
  final void Function(int) onConfirm;

  @override
  State<_LocationUpdateSheet> createState() => _LocationUpdateSheetState();
}

class _LocationUpdateSheetState extends State<_LocationUpdateSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    int best = 0;
    int bestDiff = (widget.currentSeconds - _kUpdateSteps[0]).abs();
    for (int i = 1; i < _kUpdateSteps.length; i++) {
      final diff = (widget.currentSeconds - _kUpdateSteps[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    _value = best.toDouble();
  }

  int get _selected => _kUpdateSteps[_value.round()];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.black87),
                  ),
                ),
                const Spacer(),
                const Text(
                  'معدل تحديث الموقع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kFont,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _updateLabel(_selected),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: _kFont,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kRed,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: _kRed,
                overlayColor: _kRed.withAlpha(30),
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _value,
                min: 0,
                max: (_kUpdateSteps.length - 1).toDouble(),
                divisions: _kUpdateSteps.length - 1,
                onChanged: (v) => setState(() => _value = v),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(_selected);
                },
                child: const Text(
                  'تاكيد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kFont,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class DeviceSettingsScreen extends StatelessWidget {
  const DeviceSettingsScreen({super.key});

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onDeleteTap(BuildContext context, TrackingProvider prov) {
    showDeleteDeviceDialog(context, onConfirm: () {
      final id = prov.activeDevice?.id;
      if (id != null) prov.deleteDevice(id);
      Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/tracking/device-card');
    });
  }

  void _onFactoryResetTap(BuildContext context, TrackingProvider prov) {
    showFactoryResetDialog(context, onConfirm: prov.factoryReset);
  }

  void _onPowerOffTap(BuildContext context, TrackingProvider prov) {
    showPowerOffDialog(context, onConfirm: prov.powerOff);
  }

  void _onGeofenceToggle(BuildContext context, TrackingProvider prov, bool val) {
    if (!val) {
      prov.setGeofenceEnabled(false);
      return;
    }
    if (!prov.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
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
    if (!prov.geofenceCenterSet) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GeofenceSetupScreen()),
      );
      return;
    }
    prov.setGeofenceEnabled(true);
  }

  Future<void> _callChild(String sim) async {
    final uri = Uri(scheme: 'tel', path: sim);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Consumer<TrackingProvider>(
            builder: (_, prov, __) {
              final sim = prov.activeDevice?.sim ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSettingsCard(context, prov),
                          const SizedBox(height: 24),
                          _buildActionButtons(context, prov, sim),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: _kPinkLight, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: _kRed, size: 22),
            ),
          ),
          const Spacer(),
          const Text(
            'اعدادات القطعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: _kFont,
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings card ──────────────────────────────────────────────────────────

  Widget _buildSettingsCard(BuildContext context, TrackingProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Location update rate ───────────────────────────────────────
          _SettingsRow(
            icon: Icons.timer_outlined,
            label: 'تحديث الموقع/ث',
            trailing: _EditPill(
              label: _updateLabel(prov.locationUpdateSeconds),
              onTap: () => _showLocationUpdateSheet(
                context,
                currentSeconds: prov.locationUpdateSeconds,
                onConfirm: prov.setLocationUpdateSeconds,
              ),
            ),
          ),
          const _Divider(),

          // ── GPS on/off + interval ─────────────────────────────────────
          _SettingsRow(
            icon: Icons.location_on_outlined,
            label: 'تشغيل/ايقاف gps',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EditPill(
                  label: _intervalLabel(prov.intervalSeconds),
                  onTap: () => showIntervalSheet(
                    context,
                    currentSeconds: prov.intervalSeconds,
                    onConfirm: prov.setIntervalSeconds,
                  ),
                ),
                const SizedBox(width: 10),
                _RedSwitch(
                  value: prov.gpsEnabled,
                  onChanged: (_) => prov.toggleGps(),
                ),
              ],
            ),
          ),
          const _Divider(),

          // ── Geofence toggle + radius ──────────────────────────────────
          _SettingsRow(
            icon: Icons.location_on_outlined,
            label: 'سور الحماية',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EditPill(
                  label: _radiusLabel(prov.geofence.radiusMeters),
                  onTap: () => showGeofenceRadiusSheet(
                    context,
                    currentRadius: prov.geofence.radiusMeters,
                    onConfirm: prov.setGeofenceRadius,
                  ),
                ),
                const SizedBox(width: 10),
                _RedSwitch(
                  value: prov.geofence.isEnabled,
                  onChanged: (val) => _onGeofenceToggle(context, prov, val),
                ),
              ],
            ),
          ),
          const _Divider(),

          // ── Live follow ────────────────────────────────────────────────
          _SettingsRow(
            icon: Icons.location_on_outlined,
            label: 'تتبع وقتي',
            trailing: _RedSwitch(
              value: prov.liveFollow,
              onChanged: prov.setLiveFollow,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons(
      BuildContext context, TrackingProvider prov, String sim) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Call child
        if (sim.isNotEmpty) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kRed),
              foregroundColor: _kRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _callChild(sim),
            icon: const Icon(Icons.call_outlined, size: 20),
            label: const Text(
              'اتصل بالطفل الان',
              style: TextStyle(
                fontFamily: _kFont,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Delete device
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => _onDeleteTap(context, prov),
            child: const Text(
              'حذف القطعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Factory reset
        SizedBox(
          height: 54,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kRed),
              foregroundColor: _kRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _onFactoryResetTap(context, prov),
            child: const Text(
              'عمل ضبط مصنع للقطعة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: _kFont,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Power off text link
        GestureDetector(
          onTap: () => _onPowerOffTap(context, prov),
          child: const Text(
            'ايقاف تشغيل القطعة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kRed,
              fontWeight: FontWeight.w600,
              fontFamily: _kFont,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable row widget ────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Controls on the left in RTL
          trailing,
          const Spacer(),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: _kFont,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          // Icon circle on the right in RTL
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

// ── Editable pill ──────────────────────────────────────────────────────────────

class _EditPill extends StatelessWidget {
  const _EditPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: _kFont,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 13, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

// ── Red toggle switch ──────────────────────────────────────────────────────────

class _RedSwitch extends StatelessWidget {
  const _RedSwitch({required this.value, required this.onChanged});
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: _kRed,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    );
  }
}
