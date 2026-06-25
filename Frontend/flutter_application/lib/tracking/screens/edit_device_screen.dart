import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tracker_device.dart';
import '../providers/tracking_provider.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

class EditDeviceScreen extends StatefulWidget {
  const EditDeviceScreen({super.key, required this.device});

  final TrackerDevice device;

  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  int _step = 0;

  // Step 0 — device data
  late final TextEditingController _labelCtrl;
  late final TextEditingController _simCtrl;
  late final TextEditingController _imeiCtrl;
  late final TextEditingController _passCtrl;
  bool _passVisible = false;
  final _step0Key = GlobalKey<FormState>();

  // Step 1 — control numbers
  late final TextEditingController _phone1Ctrl;
  late final TextEditingController _phone2Ctrl;
  late final TextEditingController _phone3Ctrl;
  final _step1Key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final d = widget.device;
    _labelCtrl = TextEditingController(text: d.label);
    _simCtrl = TextEditingController(text: d.sim);
    _imeiCtrl = TextEditingController(text: d.imei);
    _passCtrl = TextEditingController(text: d.devicePassword);
    _phone1Ctrl = TextEditingController(
        text: d.controlNumbers.isNotEmpty ? d.controlNumbers[0] : '');
    _phone2Ctrl = TextEditingController(
        text: d.controlNumbers.length > 1 ? d.controlNumbers[1] : '');
    _phone3Ctrl = TextEditingController(
        text: d.controlNumbers.length > 2 ? d.controlNumbers[2] : '');
  }

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

    final updated = widget.device.copyWith(
      label: _labelCtrl.text.trim(),
      sim: _simCtrl.text.trim(),
      imei: _imeiCtrl.text.trim(),
      devicePassword: _passCtrl.text.trim(),
      controlNumbers: phones,
    );

    await context.read<TrackingProvider>().updateDevice(updated);

    if (mounted) Navigator.of(context).pop();
  }

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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: _step == 0 ? _buildStep0() : _buildStep1(),
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
              child:
                  const Icon(Icons.arrow_forward, color: _kRed, size: 22),
            ),
          ),
          const Spacer(),
          const Text(
            'تحديث قطعة التتبع',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont),
          ),
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
            'تحديث بيانات القطعة',
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
          _EditField(
            label: 'عنوان القطعة',
            hint: 'مثل: قطعة تتبع انس',
            controller: _labelCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 16),
          _EditField(
            label: 'رقم شريحة القطعة',
            hint: 'مثل: 0123456789',
            controller: _simCtrl,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 16),
          _EditField(
            label: 'رقم IMEI للشريحة',
            hint: 'مثل: 4545-*****-*******-*****',
            controller: _imeiCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _EditField(
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
            'تحديث ارقام التحكم في القطعة',
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
          _EditField(
            label: 'رقم هاتف 1 *',
            hint: 'مثل: 0123456789',
            controller: _phone1Ctrl,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'رقم الهاتف الأول مطلوب'
                : null,
          ),
          const SizedBox(height: 16),
          _EditField(
            label: 'رقم هاتف 2',
            hint: 'مثل: 0123456789',
            controller: _phone2Ctrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _EditField(
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _step == 0 ? _toStep1 : _saveDevice,
              child: Text(
                _step == 0 ? 'التالي' : 'تحديث بيانات القطعة',
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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

// ── Shared form field (edit variant) ─────────────────────────────────────────

class _EditField extends StatelessWidget {
  const _EditField({
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
      crossAxisAlignment: CrossAxisAlignment.end,
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
                fontSize: 14,
                color: Colors.black38,
                fontFamily: _kFont),
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
              borderSide:
                  const BorderSide(color: _kRed, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
