import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/models/doctor_consultation_models.dart';
import 'package:Ajial/specialist-app/dashboard/services/doctor_consultation_api_service.dart';

class SpecialistTelemedicinePrescriptionPage extends StatefulWidget {
  final String bookingId;

  const SpecialistTelemedicinePrescriptionPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<SpecialistTelemedicinePrescriptionPage> createState() =>
      _SpecialistTelemedicinePrescriptionPageState();
}

class _SpecialistTelemedicinePrescriptionPageState
    extends State<SpecialistTelemedicinePrescriptionPage> {
  final DoctorConsultationApiService _api = DoctorConsultationApiService();

  List<PrescriptionMedicine> _medicines = [];
  bool _loading = true;
  String? _error;

  bool _showForm = false;
  bool _submitting = false;
  String? _editingId; // id of the medicine being edited (null = adding)

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _timingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _timingController.dispose();
    super.dispose();
  }

  // ============================================================
  // ==================== Data ==================================
  // ============================================================

  Future<void> _loadPrescription() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getPrescription(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _medicines = result.medicines;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _loading = false;
      });
    }
  }

  void _openForm({PrescriptionMedicine? medicine}) {
    setState(() {
      _editingId = medicine?.id;
      if (medicine != null) {
        _nameController.text = medicine.medicineName;
        _quantityController.text = medicine.quantity;
        _timingController.text = medicine.timing;
      } else {
        _nameController.clear();
        _quantityController.clear();
        _timingController.clear();
      }
      _showForm = true;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingId = null;
      _nameController.clear();
      _quantityController.clear();
      _timingController.clear();
    });
  }

  Future<void> _submitForm() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    final timing = _timingController.text.trim();

    if (name.isEmpty || quantity.isEmpty || timing.isEmpty) {
      _showSnack('الرجاء إدخال جميع بيانات الدواء', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final editingId = _editingId;
      if (editingId != null) {
        final updated = await _api.updatePrescriptionMedicine(
          widget.bookingId,
          editingId,
          medicineName: name,
          quantity: quantity,
          timing: timing,
        );
        if (!mounted) return;
        final index = _medicines.indexWhere((m) => m.id == editingId);
        setState(() {
          if (index != -1) _medicines[index] = updated;
        });
        _showSnack('تم تعديل الدواء بنجاح');
      } else {
        final added = await _api.addPrescriptionMedicine(
          widget.bookingId,
          medicineName: name,
          quantity: quantity,
          timing: timing,
        );
        if (!mounted) return;
        setState(() => _medicines.add(added));
        _showSnack('تم إضافة الدواء بنجاح');
      }
      _closeForm();
    } catch (e) {
      _showSnack(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteMedicine(PrescriptionMedicine medicine) async {
    try {
      await _api.deletePrescriptionMedicine(widget.bookingId, medicine.id);
      if (!mounted) return;
      setState(() => _medicines.removeWhere((m) => m.id == medicine.id));
      _showSnack('تم حذف الدواء بنجاح');
    } catch (e) {
      _showSnack(_cleanError(e), isError: true);
    }
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('SocketException') ||
        text.contains('connection') ||
        text.contains('Connection') ||
        text.contains('DioException')) {
      return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
    }
    return text.isEmpty ? 'تعذر الاتصال بالخادم، حاول مرة أخرى' : text;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : specialistGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteDialog(PrescriptionMedicine medicine) {
    final medicineName =
        medicine.medicineName.isEmpty ? 'الدواء' : medicine.medicineName;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // X button top-right (in LTR layout so it appears top-right visually)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Warning icon with light red circle
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'images/warning.png',
                    width: 36,
                    height: 36,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'حذف $medicineName؟',
                  style: const TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم حذف الدواء نهائيا ولا يمكن استعادته مره اخرى',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Buttons: in RTL, first child = right side
                Row(
                  children: [
                    // نعم حذف (red) - right side in RTL
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteMedicine(medicine);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000), // Brighter red
                          padding: const EdgeInsets.symmetric(vertical: 16), // Larger height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'نعم, حذف',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18, // Larger font
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // لا الغاء (white with black border) - left side in RTL
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16), // Larger height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          side: const BorderSide(color: Colors.black87, width: 1.5),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'لا, الغاء',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18, // Larger font
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(PrescriptionMedicine med, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Green left bar
            Container(width: 6, color: specialistGreen),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Header row: title + actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title on the right (first in RTL)
                        Text(
                          'دواء ${index + 1}',
                          style: const TextStyle(
                            fontFamily: specialistFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        // Action icons on the left (last in RTL)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _openForm(medicine: med),
                              child: Image.asset(
                                'images/edit.png',
                                width: 20,
                                height: 20,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _showDeleteDialog(med),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    if (med.medicineName.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(med.medicineName,
                            style: const TextStyle(fontFamily: specialistFont, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ),
                      const Divider(height: 16, thickness: 0.5),
                    ],
                    if (med.quantity.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(med.quantity,
                            style: const TextStyle(fontFamily: specialistFont, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ),
                      const Divider(height: 16, thickness: 0.5),
                    ],
                    if (med.timing.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(med.timing,
                            style: const TextStyle(fontFamily: specialistFont, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            return TextField(
              controller: controller,
              maxLength: 50,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: specialistFont,
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                counterText: '50/${value.text.length}',
                counterStyle: TextStyle(
                  fontFamily: specialistFont,
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: specialistGreen, width: 1.5),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddMedicineForm() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _closeForm,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.black),
                ),
              ),
              Text(
                _editingId != null ? 'تعديل الدواء' : 'دواء جديد',
                style: const TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 30),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          _buildTextField(
            controller: _nameController,
            label: 'اسم الدواء',
            placeholder: 'مثل كونجستال',
          ),
          const Divider(height: 24, thickness: 0.5),
          _buildTextField(
            controller: _quantityController,
            label: 'الكمية',
            placeholder: 'مثل قرص يومياً',
          ),
          const Divider(height: 24, thickness: 0.5),
          _buildTextField(
            controller: _timingController,
            label: 'الموعد',
            placeholder: 'مثل قبل الغذاء',
          ),
          const SizedBox(height: 24),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: specialistGreen,
                disabledBackgroundColor: specialistGreen.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _editingId != null ? 'حفظ التعديل' : 'اضف الدواء',
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _submitting ? null : _closeForm,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F7F0),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'images/back arrow.png',
                              width: 24,
                              height: 24,
                              color: specialistGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'الروشتة الطبية',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Expanded(child: _buildBody()),

                  // Add Medicine Button
                  if (!_showForm && !_loading && _error == null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openForm(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: specialistGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'اضافة دواء',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Form overlay (bottom sheet style)
              if (_showForm)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _submitting ? null : _closeForm,
                    child: Container(color: Colors.black.withValues(alpha: 0.35)),
                  ),
                ),
              if (_showForm)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {}, // prevent dismiss on form tap
                    child: SingleChildScrollView(
                      child: _buildAddMedicineForm(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: specialistGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: Colors.black.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadPrescription,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    color: specialistGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/syringe empty.png',
              width: 140,
              height: 140,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'يبدو انه لا يتوفر ادوية تم اضافتها,\nاضغط على زر اضافة دواء',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _medicines.length,
      itemBuilder: (context, index) =>
          _buildMedicineCard(_medicines[index], index),
    );
  }
}
