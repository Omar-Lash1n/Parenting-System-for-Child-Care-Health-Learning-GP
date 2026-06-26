import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/nav_bar_provider.dart';
import '../models/tracker_device.dart';
import '../providers/tracking_provider.dart';
import '../tracking_config.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  int _step = 0;

  // Step 0 — device data
  final _labelCtrl = TextEditingController();
  final _simCtrl = TextEditingController();
  final _imeiCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passVisible = false;
  final _step0Key = GlobalKey<FormState>();

  // Step 1 — control numbers
  final _phone1Ctrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _phone3Ctrl = TextEditingController();
  final _step1Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _simCtrl.dispose();
    _imeiCtrl.dispose();
    _passCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _phone3Ctrl.dispose();
    super.dispose();
  }

  void _toStep1() {
    if (!(_step0Key.currentState?.validate() ?? false)) return;
    setState(() => _step = 1);
  }

  Future<void> _saveDevice() async {
    if (!(_step1Key.currentState?.validate() ?? false)) return;

    final phones = [
      _phone1Ctrl.text.trim(),
      _phone2Ctrl.text.trim(),
      _phone3Ctrl.text.trim(),
    ].where((p) => p.isNotEmpty).toList();

    final device = TrackerDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelCtrl.text.trim(),
      sim: _simCtrl.text.trim(),
      imei: _imeiCtrl.text.trim(),
      devicePassword: _passCtrl.text.trim(),
      controlNumbers: phones,
      flespiDeviceId: TrackingConfig.flespiDeviceId,
    );

    await context.read<TrackingProvider>().addDevice(device);

    if (mounted) {
      Navigator.of(context)
          .pushReplacementNamed('/tracking/device-card');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: _step == 0
                      ? _buildStep0()
                      : _buildStep1(),
                ),
              ),
              _buildActions(),
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
              child: const Icon(Icons.arrow_forward,
                  color: _kRed, size: 22, textDirection: TextDirection.ltr),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'اضافة قطعة تتبع',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Form(
      key: _step0Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'بيانات القطعة',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont),
          ),
          const SizedBox(height: 6),
          const Text(
            'نحتاج لمعاومات صحيحة لضمان أمان المنصة',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.black54, fontFamily: _kFont),
          ),
          const SizedBox(height: 28),
          _TrackingField(
            label: 'عنوان القطعة',
            hint: 'مثل: قطعة تتبع انس',
            controller: _labelCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 16),
          _TrackingField(
            label: 'رقم شريحة القطعة',
            hint: 'مثل: 0123456789',
            controller: _simCtrl,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 16),
          _TrackingField(
            label: 'رقم IMEI للشريحة',
            hint: 'مثل: 4545-*****-*******-*****',
            controller: _imeiCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _TrackingField(
            label: 'كلمة مرور للقطعة',
            hint: 'كلمة المرور',
            controller: _passCtrl,
            obscureText: !_passVisible,
            suffixIcon: IconButton(
              icon: Icon(
                  _passVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20),
              onPressed: () =>
                  setState(() => _passVisible = !_passVisible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ارقام التحكم في القطعة',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont),
          ),
          const SizedBox(height: 6),
          const Text(
            'نحتاج لمعاومات صحيحة لضمان أمان المنصة',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.black54, fontFamily: _kFont),
          ),
          const SizedBox(height: 28),
          _TrackingField(
            label: 'رقم هاتف 1 *',
            hint: 'مثل: 0123456789',
            controller: _phone1Ctrl,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'رقم الهاتف الأول مطلوب'
                : null,
          ),
          const SizedBox(height: 16),
          _TrackingField(
            label: 'رقم هاتف 2',
            hint: 'مثل: 0123456789',
            controller: _phone2Ctrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _TrackingField(
            label: 'رقم هاتف 3',
            hint: 'مثل: 0123456789',
            controller: _phone3Ctrl,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: _step == 0 ? _toStep1 : _saveDevice,
              child: Text(
                _step == 0 ? 'التالي' : 'اضافة القطعة وبدء التتبع',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: _kFont,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_step == 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: () => setState(() => _step = 0),
                child: const Text(
                  'السابق',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: _kFont,
                      color: Colors.black87),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared form field ─────────────────────────────────────────────────────────

class _TrackingField extends StatelessWidget {
  const _TrackingField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: _kFont),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            hintStyle: const TextStyle(
                fontSize: 14, color: Colors.black38, fontFamily: _kFont),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kRed, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
