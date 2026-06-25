import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/live_location.dart';
import '../models/tracker_device.dart';
import '../providers/tracking_provider.dart';
import '../widgets/delete_device_dialog.dart';
import '../widgets/interval_sheet.dart';
import '../widgets/power_off_dialog.dart';
import '../widgets/power_on_dialog.dart';
import 'device_settings_screen.dart';
import 'edit_device_screen.dart';
import 'live_map_screen.dart';
import 'add_device_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

String _intervalLabel(int seconds) {
  if (seconds < 60) return '$seconds ث';
  if (seconds < 3600) return '${seconds ~/ 60} دق';
  return '${seconds ~/ 3600} س';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DeviceCardScreen extends StatefulWidget {
  const DeviceCardScreen({super.key});

  @override
  State<DeviceCardScreen> createState() => _DeviceCardScreenState();
}

class _DeviceCardScreenState extends State<DeviceCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TrackingProvider>().refreshOnce();
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _onToggleGps(TrackingProvider prov, String sim) async {
    await prov.toggleGps();
  }

  void _onIntervalTap(TrackingProvider prov) {
    showIntervalSheet(
      context,
      currentSeconds: prov.intervalSeconds,
      onConfirm: (s) => prov.setIntervalSeconds(s),
    );
  }

  void _onPowerOffTap(TrackingProvider prov) {
    showPowerOffDialog(context, onConfirm: prov.powerOff);
  }

  void _onStartTracking(TrackingProvider prov, String sim) {
    if (prov.isOnline || prov.location != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LiveMapScreen(deviceSim: sim)),
      );
      return;
    }
    showPowerOnDialog(context);
  }

  void _onSettingsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeviceSettingsScreen()),
    );
  }

  void _onEditTap(TrackerDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditDeviceScreen(device: device),
      ),
    );
  }

  void _onDeleteTap(TrackingProvider prov, TrackerDevice device) {
    showDeleteDeviceDialog(
      context,
      onConfirm: () => prov.deleteDevice(device.id),
    );
  }

  void _onAddDevice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<TrackingProvider>(
                  builder: (_, prov, __) {
                    if (prov.devices.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildDeviceContent(prov);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'تتبع الطفل',
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

  // ── Empty state (frame 141) ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/Box.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'يبدو انه لم يتم اضافة قطعة تتبع من قبل,\nاضغط على اضافة القطعة وبدء التتبع',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontFamily: _kFont,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _onAddDevice,
              child: const Text(
                'اضافة القطعة وبدء التتبع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: _kFont,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Device card content ───────────────────────────────────────────────────

  Widget _buildDeviceContent(TrackingProvider prov) {
    final device = prov.activeDevice!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prov.showBreachBanner) ...[
            _BreachBanner(onDismiss: prov.dismissBreachBanner),
            const SizedBox(height: 12),
          ],
          _DeviceCard(
            label: device.label,
            sim: device.sim,
            location: prov.location,
            isOnline: prov.isOnline,
            gpsEnabled: prov.gpsEnabled,
            intervalSeconds: prov.intervalSeconds,
            onToggleGps: () => _onToggleGps(prov, device.sim),
            onIntervalTap: () => _onIntervalTap(prov),
            onStartTracking: () => _onStartTracking(prov, device.sim),
            onPowerOff: () => _onPowerOffTap(prov),
            onSettingsTap: _onSettingsTap,
            onEditTap: () => _onEditTap(device),
            onDeleteTap: () => _onDeleteTap(prov, device),
          ),
        ],
      ),
    );
  }
}

// ── Device Card ───────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.label,
    required this.sim,
    required this.location,
    required this.isOnline,
    required this.gpsEnabled,
    required this.intervalSeconds,
    required this.onToggleGps,
    required this.onIntervalTap,
    required this.onStartTracking,
    required this.onPowerOff,
    required this.onSettingsTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final String label;
  final String sim;
  final LiveLocation? location;
  final bool isOnline;
  final bool gpsEnabled;
  final int intervalSeconds;
  final VoidCallback onToggleGps;
  final VoidCallback onIntervalTap;
  final VoidCallback onStartTracking;
  final VoidCallback onPowerOff;
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(context),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          _buildStatRow(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          _buildGpsRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildStartButton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: GestureDetector(
              onTap: onPowerOff,
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
          ),
        ],
      ),
    );
  }

  // ── Card header (label + SIM + online dot + context menu) ────────────────

  Widget _buildCardHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3-dot context menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54, size: 22),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            onSelected: (value) {
              if (value == 'settings') onSettingsTap();
              if (value == 'edit') onEditTap();
              if (value == 'delete') onDeleteTap();
            },
            itemBuilder: (_) => [
              _menuItem(
                value: 'settings',
                icon: Icons.settings_outlined,
                label: 'اعدادات القطعة',
                color: Colors.black87,
              ),
              _menuItem(
                value: 'edit',
                icon: Icons.edit_outlined,
                label: 'تعديل البيانات',
                color: Colors.black87,
              ),
              _menuItem(
                value: 'delete',
                icon: Icons.delete_outline,
                label: 'حذف القطعة',
                color: _kRed,
              ),
            ],
          ),
          const Spacer(),
          // Label + SIM (right-aligned in RTL)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: _kFont,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sim,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontFamily: _kFont,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Location icon circle + online indicator dot
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: _kPinkLight, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: _kRed, size: 28),
              ),
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
                fontFamily: _kFont, fontSize: 14, color: color),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }

  // ── Speed & Battery row ───────────────────────────────────────────────────

  Widget _buildStatRow() {
    final speedText = (isOnline && location?.speedKmh != null)
        ? '${location!.speedKmh!.toStringAsFixed(0)} كم/س'
        : '--';
    final batteryText = (isOnline && location?.batteryLevel != null)
        ? '${location!.batteryLevel}%'
        : '--';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              icon: Icons.battery_3_bar_rounded,
              label: 'نسبة البطارية',
              value: batteryText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBox(
              icon: Icons.directions_car_rounded,
              label: 'سرعة التحرك',
              value: speedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── GPS toggle row ────────────────────────────────────────────────────────

  Widget _buildGpsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: gpsEnabled,
              onChanged: (_) => onToggleGps(),
              activeThumbColor: Colors.white,
              activeTrackColor: _kRed,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onIntervalTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _intervalLabel(intervalSeconds),
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: _kFont,
                        color: Colors.black87),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 13, color: Colors.black54),
                ],
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'تشغيل/ايقاف gps',
            style: TextStyle(
                fontSize: 14, fontFamily: _kFont, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: _kPinkLight, shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: _kRed, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Start tracking button ─────────────────────────────────────────────────

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: gpsEnabled ? _kRed : Colors.grey.shade300, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor:
              gpsEnabled ? _kRed : Colors.grey.shade400,
        ),
        onPressed: gpsEnabled ? onStartTracking : null,
        child: Text(
          'بدء التتبع',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: _kFont,
            color: gpsEnabled ? _kRed : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

// ── Stat box (speed / battery) ────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontFamily: _kFont,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kFont,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: _kPinkLight, shape: BoxShape.circle),
            child: Icon(icon, color: _kRed, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Geofence breach banner (frame 158) ────────────────────────────────────────

class _BreachBanner extends StatelessWidget {
  const _BreachBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: Colors.black45),
          ),
          const SizedBox(width: 10),
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
                    fontFamily: _kFont,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'اتصل الان بالطفل او اكد اعلامك بذلك',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontFamily: _kFont),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration:
                const BoxDecoration(color: _kRed, shape: BoxShape.circle),
            child: const Icon(Icons.family_restroom,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
