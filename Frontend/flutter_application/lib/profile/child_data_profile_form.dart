// --- lib/profile/child_data_profile_form.dart ---
// Edit Child Profile Form Screen - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';
import 'package:Ajial/providers/child_profile_provider.dart';

const Color _kPrimaryRed = Color(0xFFBF092F);
const Color _kTextBlack = Colors.black;
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Pass [prefill] = false from "ملئ البيانات" button to start with empty fields
class ChildDataProfileFormPage extends StatefulWidget {
  final bool prefill;
  const ChildDataProfileFormPage({super.key, this.prefill = true});

  @override
  State<ChildDataProfileFormPage> createState() =>
      _ChildDataProfileFormPageState();
}

class _ChildDataProfileFormPageState extends State<ChildDataProfileFormPage> {
  late TextEditingController _nameC;
  late TextEditingController _dobDayC;
  late TextEditingController _dobYearC;
  late TextEditingController _heightC;
  late TextEditingController _weightC;
  late TextEditingController _headCircC;

  String? _selectedMonth;
  String? _selectedBloodType;
  int _genderIndex = 0;

  final _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final p = Provider.of<ChildDataProvider>(context, listen: false);

    if (widget.prefill) {
      // Edit mode: pre-fill with existing values
      _nameC = TextEditingController(text: p.name);
      _dobDayC = TextEditingController(text: p.dobDay);
      _dobYearC = TextEditingController(text: p.dobYear);
      _heightC = TextEditingController(text: p.heightVal);
      _weightC = TextEditingController(text: p.weightVal);
      _headCircC = TextEditingController(text: p.headCircumference);
      _selectedMonth = p.dobMonth.isNotEmpty ? p.dobMonth : null;
      _selectedBloodType = p.bloodType.isNotEmpty ? p.bloodType : null;
      _genderIndex = p.selectedGenderIndex;
    } else {
      // Fill Data mode: all empty
      _nameC = TextEditingController();
      _dobDayC = TextEditingController();
      _dobYearC = TextEditingController();
      _heightC = TextEditingController();
      _weightC = TextEditingController();
      _headCircC = TextEditingController();
      _selectedMonth = null;
      _selectedBloodType = null;
      _genderIndex = 0; // default to male
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _dobDayC.dispose();
    _dobYearC.dispose();
    _heightC.dispose();
    _weightC.dispose();
    _headCircC.dispose();
    super.dispose();
  }

  void _saveAll() {
    final p = Provider.of<ChildDataProvider>(context, listen: false);
    if (_nameC.text.isNotEmpty) p.setName(_nameC.text);
    if (_selectedMonth != null) {
      p.setDob(_dobDayC.text, _selectedMonth!, _dobYearC.text);
    }
    if (_genderIndex >= 0) p.setGender(_genderIndex);
    if (_heightC.text.isNotEmpty) p.setHeight(_heightC.text);
    if (_weightC.text.isNotEmpty) p.setWeight(_weightC.text);
    if (_headCircC.text.isNotEmpty) p.setHeadCircumference(_headCircC.text);
    if (_selectedBloodType != null) p.setBloodType(_selectedBloodType!);

    // Sync to ChildProfileProvider so my_child_profile updates
    final profileProv =
        Provider.of<ChildProfileProvider>(context, listen: false);
    profileProv.setChildData(
      name: p.name.isNotEmpty ? p.name : p.childName,
      age: p.age,
    );
    profileProv.setAgeInYears(p.childAgeInYears);
    profileProv.setAccountCreated(p.isAccountCreated);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildDataProvider>(
      builder: (context, provider, _) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Close button ──────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.close,
                                        size: 20, color: _kTextBlack),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildAvatarSection(provider),
                          const SizedBox(height: 24),

                          // ── Name ──────────────────────────────────────
                          _buildLabel(ChildDataStrings.formNameLabel),
                          const SizedBox(height: 8),
                          _buildTextField(
                              _nameC, ChildDataStrings.formNameHint),

                          const SizedBox(height: 16),

                          // ── Date of Birth ─────────────────────────────
                          _buildLabel(ChildDataStrings.formDobLabel),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Day
                              Expanded(
                                child: _buildNumberField(
                                    _dobDayC, ChildDataStrings.formDobDay),
                              ),
                              const SizedBox(width: 11),
                              // Month dropdown
                              Expanded(
                                child: _buildMonthDropdown(),
                              ),
                              const SizedBox(width: 11),
                              // Year
                              Expanded(
                                child: _buildNumberField(
                                    _dobYearC, ChildDataStrings.formDobYear),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Gender ────────────────────────────────────
                          _buildLabel(ChildDataStrings.formGenderLabel),
                          const SizedBox(height: 8),
                          _buildGenderToggle(),

                          const SizedBox(height: 16),

                          // ── Height ────────────────────────────────────
                          _buildLabel(ChildDataStrings.formHeightLabel),
                          const SizedBox(height: 8),
                          _buildMeasurementField(
                              _heightC,
                              ChildDataStrings.formHeightHint,
                              ChildDataStrings.formUnitCm),

                          const SizedBox(height: 16),

                          // ── Weight ────────────────────────────────────
                          _buildLabel(ChildDataStrings.formWeightLabel),
                          const SizedBox(height: 8),
                          _buildMeasurementField(
                              _weightC,
                              ChildDataStrings.formWeightHint,
                              ChildDataStrings.formUnitKg),

                          const SizedBox(height: 16),

                          // ── Blood Type ────────────────────────────────
                          _buildLabel(ChildDataStrings.formBloodTypeLabel),
                          const SizedBox(height: 8),
                          _buildBloodTypeSelector(),

                          const SizedBox(height: 16),

                          // ── Head Circumference ────────────────────────
                          _buildLabel(ChildDataStrings.formHeadCircLabel),
                          const SizedBox(height: 8),
                          _buildMeasurementField(
                              _headCircC,
                              ChildDataStrings.formHeadCircHint,
                              ChildDataStrings.formUnitCm),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom buttons ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              ChildDataStrings.formSaveAll,
                              style: const TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.black.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              ChildDataStrings.formSkipButton,
                              style: const TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: _kTextBlack,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // AVATAR SECTION
  // ============================================================
  Widget _buildAvatarSection(ChildDataProvider provider) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative frame
                Image.asset(
                  provider.isOlderChild
                      ? 'images/decorative_old.png'
                      : 'images/decorative_little.png',
                  width: 142,
                  height: 142,
                  fit: BoxFit.contain,
                ),

                // Inner avatar circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _kPrimaryRed.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.child_care,
                      size: 32,
                      color: _kPrimaryRed,
                    ),
                  ),
                ),

                // Camera button at bottom center
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kPrimaryRed.withOpacity(0.25),
                        width: 0.9,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_outlined,
                          size: 16, color: _kPrimaryRed),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.childName,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            provider.age,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _kTextBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _buildLabel(String text) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: _kFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _kTextBlack,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color: Colors.black.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String hint) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color: Colors.black.withOpacity(0.5),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 20, color: Colors.black.withOpacity(0.5)),
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color: _kTextBlack,
          ),
          hint: Text(
            ChildDataStrings.formDobMonth,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              color: Colors.black.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          items: ChildDataProvider.monthNames.map((m) {
            return DropdownMenuItem(value: m, child: Center(child: Text(m)));
          }).toList(),
          onChanged: (v) => setState(() => _selectedMonth = v),
        ),
      ),
    );
  }

  Widget _buildGenderToggle() {
    return Row(
      children: [
        _buildGenderButton(ChildDataStrings.formGenderMale, 0),
        const SizedBox(width: 11),
        _buildGenderButton(ChildDataStrings.formGenderFemale, 1),
      ],
    );
  }

  Widget _buildGenderButton(String label, int index) {
    final isSelected = _genderIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _genderIndex = index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD90000).withOpacity(0.05)
                : Colors.white,
            border: Border.all(
              color: isSelected ? _kPrimaryRed : Colors.black.withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? _kTextBlack : Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementField(
      TextEditingController controller, String hint, String unit) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Opacity(
            opacity: 0.5,
            child: Text(
              unit,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                color: _kTextBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBloodType,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 20, color: Colors.black.withOpacity(0.5)),
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color: _kTextBlack,
          ),
          hint: Text(
            ChildDataStrings.formBloodTypeHint,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          items: _bloodTypes.map((t) {
            return DropdownMenuItem(value: t, child: Center(child: Text(t)));
          }).toList(),
          onChanged: (v) => setState(() => _selectedBloodType = v),
        ),
      ),
    );
  }
}
