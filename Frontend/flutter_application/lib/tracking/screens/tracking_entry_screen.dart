import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

class TrackingEntryScreen extends StatefulWidget {
  const TrackingEntryScreen({super.key});

  @override
  State<TrackingEntryScreen> createState() => _TrackingEntryScreenState();
}

class _TrackingEntryScreenState extends State<TrackingEntryScreen> {
  bool _loading = false;

  Future<void> _onHaveDevice() async {
    setState(() => _loading = true);
    final prov = context.read<TrackingProvider>();
    await prov.reloadDevices();
    if (!mounted) return;
    setState(() => _loading = false);
    if (prov.devices.isNotEmpty) {
      Navigator.of(context).pushNamed('/tracking/device-card');
    } else {
      Navigator.of(context).pushNamed('/tracking/add-device');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _OptionCard(
                            icon: Icons.location_searching,
                            label: 'ليس لدي القطعة, اريد شراؤها',
                            onTap: () => Navigator.of(context)
                                .pushNamed('/tracking/buy-device'),
                          ),
                          const SizedBox(height: 16),
                          _OptionCard(
                            icon: Icons.person_pin_circle_outlined,
                            label: 'لدي القطعة, اريد بدء التتبع',
                            onTap: _loading ? null : _onHaveDevice,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator(color: _kRed)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: _kPinkLight, shape: BoxShape.circle),
              child: Icon(icon, color: _kRed, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: _kFont,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
