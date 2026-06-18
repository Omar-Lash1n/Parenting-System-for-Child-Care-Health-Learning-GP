import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_stepper.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_step3_page.dart';
import 'package:Ajial/specialist-app/dashboard/providers/clinic_remote_provider.dart';

class SpecialistAddClinicStep2Page extends StatefulWidget {
  final String clinicId;

  const SpecialistAddClinicStep2Page({super.key, required this.clinicId});

  @override
  State<SpecialistAddClinicStep2Page> createState() =>
      _SpecialistAddClinicStep2PageState();
}

class _SpecialistAddClinicStep2PageState
    extends State<SpecialistAddClinicStep2Page> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _examinationPriceController =
      TextEditingController();
  final TextEditingController _consultationPriceController =
      TextEditingController();

  List<Map<String, String>> _confirmedPeriods = [];

  // مواعيد العمل الثابتة بصيغة 24 ساعة المعيارية (HH:mm) — تُرسل للـ backend
  String? _fixedFrom24;
  String? _fixedTo24;

  /// تحويل TimeOfDay إلى صيغة معيارية "HH:mm" (24 ساعة) ليقرأها الـ backend بسهولة.
  String _to24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detail = context.read<ClinicRemoteProvider>().clinicDetail;
      if (detail != null) {
        _examinationPriceController.text = detail.examinationPrice?.toStringAsFixed(0) ?? '';
        _consultationPriceController.text = detail.consultationPrice?.toStringAsFixed(0) ?? '';
        if (detail.workingHoursJson != null && detail.workingHoursJson!.isNotEmpty) {
          try {
            final decoded = jsonDecode(detail.workingHoursJson!);
            if (decoded is Map && decoded['type'] == 'fixed') {
              _fixedFrom24 = decoded['from']?.toString();
              _fixedTo24 = decoded['to']?.toString();
              _scheduleController.text = 'يوميا من ${decoded['from']} الى ${decoded['to']}';
            } else if (decoded is Map && decoded['type'] == 'specific') {
              final periods = decoded['periods'] as List? ?? [];
              _confirmedPeriods = periods.map((p) => Map<String, String>.from(p as Map)).toList();
              _scheduleController.text = _confirmedPeriods.isNotEmpty ? 'مواعيد مخصصة' : '';
            }
          } catch (_) {
            _scheduleController.text = detail.workingHoursJson!;
          }
        }
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    _examinationPriceController.dispose();
    _consultationPriceController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ClinicRemoteProvider>();

      // Build working hours JSON
      String? workingHoursJson;
      if (_scheduleController.text.startsWith('يوميا من')) {
        // Fixed schedule — نرسل الوقت بصيغة معيارية HH:mm
        if (_fixedFrom24 != null && _fixedTo24 != null) {
          workingHoursJson = jsonEncode({'type': 'fixed', 'from': _fixedFrom24, 'to': _fixedTo24});
        }
      } else if (_confirmedPeriods.isNotEmpty) {
        workingHoursJson = jsonEncode({'type': 'specific', 'periods': _confirmedPeriods});
      }

      final success = await provider.updateClinicHours(
        widget.clinicId,
        workingHoursJson: workingHoursJson,
        examinationPrice: double.tryParse(_examinationPriceController.text),
        consultationPrice: double.tryParse(_consultationPriceController.text),
      );

      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SpecialistAddClinicStep3Page(
              clinicId: widget.clinicId,
            ),
          ),
        );
      } else if (provider.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!, style: const TextStyle(fontFamily: specialistFont)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onPrevious() {
    Navigator.of(context).pop();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تنبيه', style: TextStyle(fontFamily: specialistFont, color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(fontFamily: specialistFont, fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسنا', style: TextStyle(fontFamily: specialistFont, color: specialistGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // Pop twice or back to main
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'اضافة عيادة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stepper UI
                        const ClinicStepper(currentStep: 2),
                        const SizedBox(height: 32),

                        // Titles
                        const Center(
                          child: Text(
                            'اوقات عمل العيادة و التكلفة',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'نحتاج لمعلومات صحيحة لضمان أمان المنصة',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Fields
                        _buildLabel('مواعيد العمل*'),
                        _buildTextField(
                          controller: _scheduleController,
                          hint: 'تحديد المواعيد',
                          prefixIcon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: () {
                            _showWorkingDaysBottomSheet(context);
                          },
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'مطلوب' : null,
                        ),

                        // Render confirmed specific periods
                        if (_scheduleController.text == 'مواعيد مخصصة' &&
                            _confirmedPeriods.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (int i = 0; i < _confirmedPeriods.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color:
                                          Colors.black.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_confirmedPeriods[i]['day']} من ${_confirmedPeriods[i]['from']} الى ${_confirmedPeriods[i]['to']}',
                                      style: const TextStyle(
                                        fontFamily: specialistFont,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showWorkingDaysBottomSheet(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: specialistGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                        ),
                                        child: const Text(
                                          'تعديل',
                                          style: TextStyle(
                                            fontFamily: specialistFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 36,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _confirmedPeriods.removeAt(i);
                                            if (_confirmedPeriods.isEmpty) {
                                              _scheduleController.clear();
                                            }
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                              color: Colors.black
                                                  .withValues(alpha: 0.4)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                        ),
                                        child: const Text(
                                          'حذف',
                                          style: TextStyle(
                                            fontFamily: specialistFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 16),

                        _buildLabel('سعر الكشف ج.م*'),
                        _buildTextField(
                          controller: _examinationPriceController,
                          hint: 'مثلاً: 150',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('سعر الاستشارة ج.م*'),
                        _buildTextField(
                          controller: _consultationPriceController,
                          hint: 'مثلاً: 50',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: specialistGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'التالي',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onPrevious,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'السابق',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // Extra padding at bottom
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontFamily: specialistFont, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: specialistFont,
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey, size: 22)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: specialistGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  void _showWorkingDaysBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int sheetStep = 1;
        String selectedType = ''; // 'fixed' or 'specific'
        final TextEditingController fromController = TextEditingController();
        final TextEditingController toController = TextEditingController();

        TimeOfDay? fixedFromTime;
        TimeOfDay? fixedToTime;

        // State for Specific Days (Periods)
        Map<String, List<Map<String, dynamic>>> dayPeriods = {
          'السبت': [],
          'الاحد': [],
          'الاثنين': [],
          'الثلاثاء': [],
          'الاربعاء': [],
          'الخميس': [],
          'الجمعة': [],
        };

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Widget currentStepWidget;
            if (sheetStep == 1) {
              currentStepWidget = _buildSheetStep1(
                  setState, selectedType, (type) => selectedType = type, () {
                if (selectedType == 'fixed') {
                  setState(() => sheetStep = 2);
                } else if (selectedType == 'specific') {
                  setState(() => sheetStep = 3);
                }
              }, ctx);
            } else if (sheetStep == 2) {
              currentStepWidget = _buildSheetStep2(
                  setState,
                  fromController,
                  toController,
                  fixedFromTime,
                  fixedToTime,
                  (TimeOfDay f) => fixedFromTime = f,
                  (TimeOfDay t) => fixedToTime = t, () {
                setState(() => sheetStep = 1);
              }, () {
                // Confirm Fixed
                if (fromController.text.isEmpty || toController.text.isEmpty ||
                    fixedFromTime == null || fixedToTime == null) {
                  _showErrorDialog(ctx, 'الرجاء اختيار جميع مواعيد العمل');
                  return;
                }
                this.setState(() {
                  _fixedFrom24 = _to24(fixedFromTime!);
                  _fixedTo24 = _to24(fixedToTime!);
                  _scheduleController.text =
                      'يوميا من ${fromController.text} الى ${toController.text}';
                });
                Navigator.of(ctx).pop();
              }, ctx);
            } else {
              currentStepWidget = _buildSheetStep3(setState, dayPeriods, () {
                setState(() => sheetStep = 1);
              }, () {
                // Confirm Specific
                _confirmedPeriods.clear();
                bool hasIncompletePeriod = false;
                for (var day in dayPeriods.keys) {
                  for (var p in dayPeriods[day]!) {
                    if (p['fromCtrl']!.text.isEmpty || p['toCtrl']!.text.isEmpty) {
                      hasIncompletePeriod = true;
                    }
                  }
                }
                if (hasIncompletePeriod) {
                  _showErrorDialog(ctx, 'جميع البيانات يجب ان تكون مملوءة');
                  return;
                }
                
                for (var day in dayPeriods.keys) {
                  for (var p in dayPeriods[day]!) {
                    if (p['fromCtrl']!.text.isNotEmpty &&
                        p['toCtrl']!.text.isNotEmpty &&
                        p['fromTime'] != null &&
                        p['toTime'] != null) {
                      _confirmedPeriods.add({
                        'day': day,
                        'from': _to24(p['fromTime'] as TimeOfDay),
                        'to': _to24(p['toTime'] as TimeOfDay),
                      });
                    }
                  }
                }
                this.setState(() {
                  _scheduleController.text =
                      _confirmedPeriods.isNotEmpty ? 'مواعيد مخصصة' : '';
                });
                Navigator.of(ctx).pop();
              }, ctx);
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: currentStepWidget,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetStep1(StateSetter setState, String selectedType,
      Function(String) onSelect, VoidCallback onNext, BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'تحديد ايام العمل',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Outlined Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => onSelect('fixed'));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: selectedType == 'fixed'
                        ? specialistGreen
                        : Colors.black.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: selectedType == 'fixed'
                      ? specialistGreen.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Text(
                  'مواعيد ثابتة يومياً',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedType == 'fixed'
                        ? specialistGreen
                        : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => onSelect('specific'));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: selectedType == 'specific'
                        ? specialistGreen
                        : Colors.black.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: selectedType == 'specific'
                      ? specialistGreen.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Text(
                  'مواعيد محددة',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedType == 'specific'
                        ? specialistGreen
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Next Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: selectedType.isEmpty ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: specialistGreen,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: const Text(
              'التالي',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  bool _isTimeAfter(TimeOfDay t1, TimeOfDay t2) {
    if (t1.hour > t2.hour) return true;
    if (t1.hour == t2.hour && t1.minute > t2.minute) return true;
    return false;
  }

  Widget _buildSheetStep2(
      StateSetter setState,
      TextEditingController fromCtrl,
      TextEditingController toCtrl,
      TimeOfDay? fixedFromTime,
      TimeOfDay? fixedToTime,
      Function(TimeOfDay) setFromTime,
      Function(TimeOfDay) setToTime,
      VoidCallback onPrev,
      VoidCallback onConfirm,
      BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'تحديد اوقات العمل',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Time Inputs
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: fromCtrl,
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: ctx,
                    initialTime: fixedFromTime ?? TimeOfDay.now(),
                  );
                  if (picked != null && ctx.mounted) {
                    setFromTime(picked);
                    final localizations = MaterialLocalizations.of(ctx);
                    setState(() {
                      fromCtrl.text = localizations.formatTimeOfDay(picked,
                          alwaysUse24HourFormat: false);
                    });
                  }
                },
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontFamily: specialistFont, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'من',
                  hintStyle: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  suffixIcon: const Icon(Icons.access_alarm_outlined,
                      color: Colors.grey, size: 22),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: specialistGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: toCtrl,
                readOnly: true,
                onTap: () async {
                  if (fixedFromTime == null) {
                    _showErrorDialog(ctx, 'الرجاء اختيار وقت البدء اولا');
                    return;
                  }
                  final TimeOfDay? picked = await showTimePicker(
                    context: ctx,
                    initialTime: fixedToTime ?? TimeOfDay.now(),
                  );
                  if (picked != null && ctx.mounted) {
                    if (!_isTimeAfter(picked, fixedFromTime)) {
                      _showErrorDialog(ctx, 'وقت الانتهاء يجب ان يكون بعد وقت البدء');
                      return;
                    }
                    setToTime(picked);
                    final localizations = MaterialLocalizations.of(ctx);
                    setState(() {
                      toCtrl.text = localizations.formatTimeOfDay(picked,
                          alwaysUse24HourFormat: false);
                    });
                  }
                },
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontFamily: specialistFont, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'الي',
                  hintStyle: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  suffixIcon: const Icon(Icons.access_alarm_outlined,
                      color: Colors.grey, size: 22),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: specialistGreen),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: specialistGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: const Text(
              'تاكيد',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Previous Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onPrev,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.black.withValues(alpha: 0.8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              'السابق',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSheetStep3(
      StateSetter setState,
      Map<String, List<Map<String, dynamic>>> dayPeriods,
      VoidCallback onPrev,
      VoidCallback onConfirm,
      BuildContext ctx) {
    bool hasSelection = dayPeriods.values.any((list) => list.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'تحديد مواعيد العمل',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Days List
        ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
          child: SingleChildScrollView(
            child: Column(
              children: dayPeriods.keys.map((day) {
                bool isDayActive = dayPeriods[day]!.isNotEmpty;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Switch(
                            value: isDayActive,
                            onChanged: (val) {
                              setState(() {
                                if (val) {
                                  dayPeriods[day]!.add({
                                    'fromCtrl': TextEditingController(),
                                    'toCtrl': TextEditingController(),
                                    'fromTime': null,
                                    'toTime': null,
                                  });
                                } else {
                                  for (var p in dayPeriods[day]!) {
                                    p['fromCtrl']!.dispose();
                                    p['toCtrl']!.dispose();
                                  }
                                  dayPeriods[day]!.clear();
                                }
                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: specialistGreen,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor:
                                Colors.grey.withValues(alpha: 0.3),
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent),
                          ),
                        ],
                      ),
                    ),

                    // Render Periods if Active
                    if (isDayActive) ...[
                      const SizedBox(height: 8),
                      for (int i = 0; i < dayPeriods[day]!.length; i++) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'فترة ${i + 1}',
                            style: const TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: dayPeriods[day]![i]['fromCtrl'],
                                readOnly: true,
                                onTap: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                    context: ctx,
                                    initialTime: dayPeriods[day]![i]
                                            ['fromTime'] ??
                                        TimeOfDay.now(),
                                  );
                                  if (picked != null && ctx.mounted) {
                                    dayPeriods[day]![i]['fromTime'] = picked;
                                    final localizations =
                                        MaterialLocalizations.of(ctx);
                                    setState(() {
                                      dayPeriods[day]![i]['fromCtrl']!.text =
                                          localizations.formatTimeOfDay(picked,
                                              alwaysUse24HourFormat: false);
                                    });
                                  }
                                },
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontFamily: specialistFont, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'من',
                                  hintStyle: TextStyle(
                                    fontFamily: specialistFont,
                                    fontSize: 14,
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                  suffixIcon: const Icon(
                                      Icons.access_alarm_outlined,
                                      color: Colors.grey,
                                      size: 20),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.black
                                            .withValues(alpha: 0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.black
                                            .withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                        color: specialistGreen),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: dayPeriods[day]![i]['toCtrl'],
                                readOnly: true,
                                onTap: () async {
                                  final fromTime =
                                      dayPeriods[day]![i]['fromTime'];
                                  if (fromTime == null) {
                                    _showErrorDialog(ctx, 'الرجاء اختيار وقت البدء اولا');
                                    return;
                                  }
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                    context: ctx,
                                    initialTime: dayPeriods[day]![i]
                                            ['toTime'] ??
                                        TimeOfDay.now(),
                                  );
                                  if (picked != null && ctx.mounted) {
                                    if (!_isTimeAfter(picked, fromTime)) {
                                      _showErrorDialog(ctx, 'وقت الانتهاء يجب ان يكون بعد وقت البدء');
                                      return;
                                    }
                                    dayPeriods[day]![i]['toTime'] = picked;
                                    final localizations =
                                        MaterialLocalizations.of(ctx);
                                    setState(() {
                                      dayPeriods[day]![i]['toCtrl']!.text =
                                          localizations.formatTimeOfDay(picked,
                                              alwaysUse24HourFormat: false);
                                    });
                                  }
                                },
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontFamily: specialistFont, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'الي',
                                  hintStyle: TextStyle(
                                    fontFamily: specialistFont,
                                    fontSize: 14,
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                  suffixIcon: const Icon(
                                      Icons.access_alarm_outlined,
                                      color: Colors.grey,
                                      size: 20),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.black
                                            .withValues(alpha: 0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.black
                                            .withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                        color: specialistGreen),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Add Extra Period Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              dayPeriods[day]!.add({
                                'fromCtrl': TextEditingController(),
                                'toCtrl': TextEditingController(),
                                'fromTime': null,
                                'toTime': null,
                              });
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.black.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            'اضافة فترة عمل اضافية خلال يوم $day',
                            style: const TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (day != 'الجمعة')
                      Divider(
                          color: Colors.grey.withValues(alpha: 0.2), height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: hasSelection ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: specialistGreen,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: const Text(
              'تاكيد',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Previous Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onPrev,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.black.withValues(alpha: 0.8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              'السابق',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
