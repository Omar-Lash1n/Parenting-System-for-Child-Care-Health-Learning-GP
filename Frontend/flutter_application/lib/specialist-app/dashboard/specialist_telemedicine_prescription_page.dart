import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class Medicine {
  String name;
  String quantity;
  String timing;

  Medicine({required this.name, required this.quantity, required this.timing});
}

class SpecialistTelemedicinePrescriptionPage extends StatefulWidget {
  final List<Medicine> initialMedicines;

  const SpecialistTelemedicinePrescriptionPage({
    super.key,
    required this.initialMedicines,
  });

  @override
  State<SpecialistTelemedicinePrescriptionPage> createState() =>
      _SpecialistTelemedicinePrescriptionPageState();
}

class _SpecialistTelemedicinePrescriptionPageState
    extends State<SpecialistTelemedicinePrescriptionPage> {
  late List<Medicine> _medicines;
  bool _showForm = false;
  int? _editingIndex;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _timingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Copy the list so changes are tracked separately
    _medicines = List.from(widget.initialMedicines);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _timingController.dispose();
    super.dispose();
  }

  void _openForm({int? editIndex}) {
    setState(() {
      _editingIndex = editIndex;
      if (editIndex != null) {
        final med = _medicines[editIndex];
        _nameController.text = med.name;
        _quantityController.text = med.quantity;
        _timingController.text = med.timing;
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
      _editingIndex = null;
      _nameController.clear();
      _quantityController.clear();
      _timingController.clear();
    });
  }

  void _submitForm() {
    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    final timing = _timingController.text.trim();

    if (name.isEmpty || quantity.isEmpty || timing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال جميع بيانات الدواء',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: specialistFont, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (_editingIndex != null) {
        _medicines[_editingIndex!] = Medicine(name: name, quantity: quantity, timing: timing);
      } else {
        _medicines.add(Medicine(name: name, quantity: quantity, timing: timing));
      }
      _showForm = false;
      _editingIndex = null;
      _nameController.clear();
      _quantityController.clear();
      _timingController.clear();
    });
  }

  void _showDeleteDialog(int index) {
    final medicineName = _medicines[index].name.isEmpty ? 'الدواء' : _medicines[index].name;

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
                          setState(() {
                            _medicines.removeAt(index);
                          });
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

  Widget _buildMedicineCard(Medicine med, int index) {
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
                              onTap: () => _openForm(editIndex: index),
                              child: Image.asset(
                                'images/edit.png',
                                width: 20,
                                height: 20,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _showDeleteDialog(index),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    if (med.name.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(med.name,
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
              const Text(
                'دواء جديد',
                style: TextStyle(
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
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: specialistGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'اضف الدواء',
                style: TextStyle(
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
              onPressed: _closeForm,
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.pop(context, _medicines);
          }
        },
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
                            onTap: () => Navigator.pop(context, _medicines),
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
                    Expanded(
                      child: _medicines.isEmpty
                          ? Center(
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
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _medicines.length,
                              itemBuilder: (context, index) =>
                                  _buildMedicineCard(_medicines[index], index),
                            ),
                    ),

                    // Add Medicine Button
                    if (!_showForm)
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
                      onTap: _closeForm,
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
      ),
    );
  }
}

