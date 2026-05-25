import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/egypt_cities.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_stepper.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_step2_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinic_data_page.dart';

class SpecialistAddClinicPage extends StatefulWidget {
  const SpecialistAddClinicPage({super.key});

  @override
  State<SpecialistAddClinicPage> createState() => _SpecialistAddClinicPageState();
}

class _SpecialistAddClinicPageState extends State<SpecialistAddClinicPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  
  String? _selectedGov;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    if (globalDraftClinic != null) {
      _nameController.text = globalDraftClinic!.name;
      if (egyptianGovernorates.containsKey(globalDraftClinic!.city)) {
        _selectedGov = globalDraftClinic!.city;
        if (egyptianGovernorates[_selectedGov]!.contains(globalDraftClinic!.region)) {
          _selectedCity = globalDraftClinic!.region;
        }
      }
      _addressController.text = globalDraftClinic!.address;
      _mobileController.text = globalDraftClinic!.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      if (globalDraftClinic == null) {
        globalDraftClinic = ClinicData(
          name: _nameController.text,
          city: _selectedGov ?? '',
          region: _selectedCity ?? '',
          address: _addressController.text,
          phone: _mobileController.text,
          schedule: '',
          examinationPrice: '',
          consultationPrice: '',
          submissionDate: DateTime.now(),
        );
      } else {
        globalDraftClinic!.name = _nameController.text;
        globalDraftClinic!.city = _selectedGov ?? '';
        globalDraftClinic!.region = _selectedCity ?? '';
        globalDraftClinic!.address = _addressController.text;
        globalDraftClinic!.phone = _mobileController.text;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SpecialistAddClinicStep2Page(),
        ),
      );
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // Pop back to main
                        Navigator.of(context).pop();
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
                        const ClinicStepper(currentStep: 1),
                        const SizedBox(height: 32),
                        
                        // Titles
                        const Center(
                          child: Text(
                            'تفاصيل العيادة',
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
                        _buildLabel('اسم العيادة*'),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'مثلاً: عيادة الأمل لطب الأطفال',
                          validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('المحافظة*'),
                        _buildDropdown(
                          hint: 'اختر المحافظة',
                          value: _selectedGov,
                          items: egyptianGovernorates.keys.toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGov = val;
                              _selectedCity = null; // reset city when gov changes
                            });
                          },
                          validator: (v) => (v == null) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('المدينة*'),
                        _buildDropdown(
                          hint: _selectedGov == null ? 'اختر المحافظة أولاً' : 'اختر المدينة',
                          value: _selectedCity,
                          items: _selectedGov != null ? egyptianGovernorates[_selectedGov]! : [],
                          onChanged: _selectedGov == null
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedCity = val;
                                  });
                                },
                          validator: (v) => (v == null) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('العنوان التفصيلي*'),
                        _buildTextField(
                          controller: _addressController,
                          hint: 'مثلاً: شارع الأمل تقاطع 2 بجوار ...',
                          validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('رقم موبايل العيادة*'),
                        _buildTextField(
                          controller: _mobileController,
                          hint: 'مثلاً: 0107845963',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'مطلوب';
                            if (v.length != 11) return 'رقم الموبايل يجب أن يكون 11 رقماً';
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: specialistFont)))).toList(),
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      style: const TextStyle(fontFamily: specialistFont, fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: specialistFont,
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
}
