// --- add-child-flow.dart (Refactored with Provider Pattern) ---

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';

import 'package:Ajial/providers/add_child_flow_provider.dart';
import 'package:Ajial/homepage/homepage.dart';

// --- CONSTANTS ---
const String kFontFamily = 'IBM Plex Sans Arabic';
const Color kPrimaryColor = Color(0xFFBF092F);
const Color kBgColor = Colors.white;

class AddChildFlow extends StatefulWidget {
  const AddChildFlow({super.key});

  @override
  State<AddChildFlow> createState() => _AddChildFlowState();
}

class _AddChildFlowState extends State<AddChildFlow> {
  final PageController _pageController = PageController();

  // Controllers stay in widget for proper disposal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _childIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _childIdController.dispose();
    _pageController.dispose();
    // Reset provider state when leaving screen
    context.read<AddChildFlowProvider>().reset();
    super.dispose();
  }

  // --- Logic ---
  void _nextPage() {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // --- Submit to Backend ---
  Future<void> _submitDataToBackend() async {
    final provider = context.read<AddChildFlowProvider>();

    final success = await provider.submitDataToBackend(
      name: _nameController.text,
      day: _dayController.text,
      month: _monthController.text,
      year: _yearController.text,
      childId: _childIdController.text,
      context: context,
    );

    if (success) {
      // Jump to success page
      _pageController.jumpToPage(5);
    }
  }

  void _validateAndProceed(int stepIndex) {
    final provider = context.read<AddChildFlowProvider>();

    bool isValid = provider.validateStep(
      stepIndex: stepIndex,
      name: _nameController.text,
      day: _dayController.text,
      month: _monthController.text,
      year: _yearController.text,
      childId: _childIdController.text,
      context: context,
    );

    if (!isValid) {
      setState(() {}); // Refresh to show errors
      return;
    }

    switch (stepIndex) {
      case 0: // Name
      case 1: // Birth Date
      case 2: // Gender
        _nextPage();
        break;

      case 3: // Picture
        if (provider.isOlderChild) {
          _nextPage(); // Older child -> go to account page
        } else {
          // Young child -> submit now
          _submitDataToBackend();
        }
        break;

      case 4: // Account (for older children)
        _submitDataToBackend();
        break;
    }
  }

  // --- Image Picker ---
  void _showImageSourceDialog() {
    final provider = context.read<AddChildFlowProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختر مصدر الصورة",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: kFontFamily)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
              title: const Text("التقاط صورة",
                  style: TextStyle(fontFamily: kFontFamily)),
              onTap: () {
                Navigator.pop(ctx);
                provider.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: kPrimaryColor),
              title: const Text("اختيار من المعرض",
                  style: TextStyle(fontFamily: kFontFamily)),
              onTap: () {
                Navigator.pop(ctx);
                provider.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================   UI BUILD   ===================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<AddChildFlowProvider>(
            builder: (context, provider, _) {
              return PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => provider.setCurrentStep(idx),
                children: [
                  _buildNamePage(provider), // 0
                  _buildBirthDatePage(provider), // 1
                  _buildGenderPage(provider), // 2
                  _buildPicturePage(provider), // 3
                  _buildAccountPage(provider), // 4
                  _buildSuccessPage(provider), // 5
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildPageLayout({
    required String title,
    required int stepNumber,
    required Widget content,
    required AddChildFlowProvider provider,
    VoidCallback? onNext,
    String nextText = "التالي",
    bool showBack = true,
    bool canSkip = false,
    VoidCallback? onSkip,
  }) {
    int total = provider.isOlderChild ? 5 : 4;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
          const Spacer(),
          if (canSkip)
            TextButton(
                onPressed: onSkip ?? onNext,
                style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                child: const Text("تخطي",
                    style:
                        TextStyle(color: Colors.grey, fontFamily: kFontFamily)))
        ]),
      ),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value: stepNumber / total,
                    backgroundColor: Colors.grey[200],
                    color: kPrimaryColor,
                    minHeight: 6)),
            const SizedBox(height: 8),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE6E9),
                    borderRadius: BorderRadius.circular(12)),
                child: Text("خطوة $stepNumber من $total",
                    style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 12,
                        fontFamily: kFontFamily,
                        fontWeight: FontWeight.bold)))
          ])),
      const SizedBox(height: 20),
      Text(title,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: kFontFamily)),
      const SizedBox(height: 30),
      Expanded(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: content)),
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ]),
          child: Column(children: [
            // Submit/Next button (with loading indicator)
            SizedBox(
                width: double.infinity,
                height: 55,
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor))
                    : ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            elevation: 0),
                        child: Text(nextText,
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: kFontFamily,
                                fontWeight: FontWeight.bold)))),
            if (showBack && !provider.isLoading) ...[
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                      onPressed: _prevPage,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50))),
                      child: const Text("السابق",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontFamily: kFontFamily))))
            ]
          ])),
    ]);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    int? maxLength,
    String? errorText,
  }) {
    Color borderColor = Colors.grey[300]!;
    if (errorText != null)
      borderColor = Colors.red;
    else if (controller.text.isNotEmpty) borderColor = Colors.green;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  if (maxLength != null)
                    LengthLimitingTextInputFormatter(maxLength)
                ]
              : [],
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.grey[400], fontFamily: kFontFamily),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.5)),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel,
                          color: Colors.grey, size: 20),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      })
                  : null)),
      if (errorText != null)
        Padding(
            padding: const EdgeInsets.only(right: 10, top: 5),
            child: Text(errorText,
                style: const TextStyle(
                    color: Colors.red, fontSize: 12, fontFamily: kFontFamily))),
    ]);
  }

  Widget _buildLabel(String text, bool required) {
    return RichText(
        text: TextSpan(children: [
      TextSpan(
          text: text,
          style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: kFontFamily)),
      if (required)
        const TextSpan(
            text: " *",
            style: TextStyle(
                color: kPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold))
    ]));
  }

  Widget _buildGenderOption(
      String label, String val, IconData icon, AddChildFlowProvider provider) {
    bool selected = provider.selectedGender == val;
    return GestureDetector(
        onTap: () => provider.setGender(val),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
                color: selected ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected ? Colors.blue : Colors.grey[300]!,
                    width: 2)),
            child: Column(children: [
              Icon(icon,
                  size: 40, color: selected ? Colors.blue : Colors.black),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: kFontFamily,
                      color: selected ? Colors.blue : Colors.black))
            ])));
  }

  // --- Pages ---

  Widget _buildNamePage(AddChildFlowProvider provider) => _buildPageLayout(
      title: "ادخل اسم الطفل",
      stepNumber: 1,
      showBack: false,
      provider: provider,
      onNext: () => _validateAndProceed(0),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLabel("اسم الطفل كامل", true),
        const SizedBox(height: 10),
        _buildTextField(
            controller: _nameController,
            hint: "على جمال",
            errorText: provider.nameError)
      ]));

  Widget _buildBirthDatePage(AddChildFlowProvider provider) => _buildPageLayout(
      title: "ادخل عمر الطفل",
      stepNumber: 2,
      provider: provider,
      onNext: () => _validateAndProceed(1),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLabel("تاريخ ميلاد الطفل", true),
        const SizedBox(height: 16),
        // Day field
        _buildDateField(
          controller: _dayController,
          label: "اليوم",
          hint: "مثال: 15",
          maxLength: 2,
          hasError: provider.dateError != null,
        ),
        const SizedBox(height: 12),
        // Month dropdown
        _buildMonthDropdownField(provider),
        const SizedBox(height: 12),
        // Year field
        _buildDateField(
          controller: _yearController,
          label: "السنة",
          hint: "مثال: 2020",
          maxLength: 4,
          hasError: provider.dateError != null,
        ),
        if (provider.dateError != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(provider.dateError!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontFamily: kFontFamily)),
                    ),
                  ],
                ),
              ))
      ]));

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    bool hasError = false,
  }) {
    Color borderColor = Colors.grey[300]!;
    if (hasError && controller.text.isEmpty) {
      borderColor = Colors.red;
    } else if (controller.text.isNotEmpty) {
      borderColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: kFontFamily,
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.cancel, color: Colors.grey, size: 20),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDropdownField(AddChildFlowProvider provider) {
    Color borderColor = Colors.grey[300]!;
    if (provider.dateError != null && provider.selectedMonth == null) {
      borderColor = Colors.red;
    } else if (provider.selectedMonth != null) {
      borderColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "الشهر",
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedMonth,
              hint: Text(
                "اختر الشهر",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: kFontFamily,
                  fontSize: 16,
                ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 16,
                color: Colors.black,
              ),
              items: provider.monthsList.map((month) {
                return DropdownMenuItem<String>(
                  value: month['val'],
                  child: Text(
                    month['label']!,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                provider.setSelectedMonth(val);
                _monthController.text = val ?? "";
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPage(AddChildFlowProvider provider) => _buildPageLayout(
      title: "ادخل نوع الطفل",
      stepNumber: 3,
      provider: provider,
      onNext: () => _validateAndProceed(2),
      content: Column(children: [
        _buildGenderOption("طفل", "male", Icons.face, provider),
        const SizedBox(height: 15),
        _buildGenderOption("طفلة", "female", Icons.face_3, provider)
      ]));

  Widget _buildPicturePage(AddChildFlowProvider provider) {
    return _buildPageLayout(
      title: "اضف صورة الطفل",
      stepNumber: 4,
      canSkip: true,
      provider: provider,
      onSkip: () => _validateAndProceed(3),
      onNext: () => _validateAndProceed(3),
      content: Center(
          child: Column(children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: provider.childImage == null
              ? CustomPaint(
                  painter: DashedCirclePainter(),
                  child: Container(
                    width: 180,
                    height: 180,
                    alignment: Alignment.center,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text("اضغط هنا لتحميل\nصورة الطفل",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontFamily: kFontFamily))
                        ]),
                  ),
                )
              : Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: FileImage(provider.childImage!),
                          fit: BoxFit.cover),
                      border: Border.all(color: Colors.grey[300]!, width: 1))),
        ),
        const SizedBox(height: 20),
        if (provider.childImage != null)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
                onPressed: _showImageSourceDialog,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child:
                    const Text("تغيير", style: TextStyle(color: Colors.white))),
            const SizedBox(width: 10),
            OutlinedButton(
                onPressed: () => provider.clearChildImage(),
                child: const Text("حذف", style: TextStyle(color: Colors.red)))
          ]),
        const SizedBox(height: 10),
        Text("الحد الأقصى 4MB بصيغة png او jpg",
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: kFontFamily)),
      ])),
    );
  }

  Widget _buildAccountPage(AddChildFlowProvider provider) {
    return _buildPageLayout(
        title: "ادخل بيانات حساب الطفل",
        stepNumber: 5,
        nextText: "انهاء",
        canSkip: true,
        provider: provider,
        onNext: () => _validateAndProceed(4),
        onSkip: () {
          _submitDataToBackend();
        },
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildLabel("الرقم التعريفي id", true), const SizedBox(height: 8),
          _buildTextField(
              controller: _childIdController,
              hint: "اكتب 4 أرقام...",
              isNumber: true,
              maxLength: 4,
              errorText: provider.idError),
          const SizedBox(height: 25), _buildLabel("كلمة المرور", true),
          const SizedBox(height: 10),

          // Password slots
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                bool filled = index < provider.selectedFruitImages.length;
                return Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey[300]!, width: 1.5)),
                    child: filled
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                                provider.selectedFruitImages[index]))
                        : null);
              })),
          const SizedBox(height: 20),

          // Fruits grid
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: provider.fruitsList.length,
              itemBuilder: (ctx, idx) {
                return GestureDetector(
                    onTap: () => provider.addFruit(idx),
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(8),
                        child:
                            Image.asset(provider.fruitsList[idx].imagePath)));
              }),

          if (provider.selectedFruitImages.isNotEmpty)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: () => provider.clearFruits(),
                    icon: const Icon(Icons.refresh, color: kPrimaryColor),
                    label: const Text("إعادة تعيين",
                        style: TextStyle(
                            color: kPrimaryColor, fontFamily: kFontFamily))))
        ]));
  }

  Widget _buildSuccessPage(AddChildFlowProvider provider) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                      color: kPrimaryColor, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 70)),
              const SizedBox(height: 30),
              const Text("تم اضافة الطفل بنجاح!",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: kFontFamily)),
              const SizedBox(height: 10),
              const Text("يمكنك الآن التوجه لمساحتك الخاصة",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: kFontFamily)),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChildProfileTestPage(
                                    childName: _nameController.text,
                                    childImage: provider.childImage)));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50))),
                      child: const Text("التالي",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: kFontFamily)))),
              const SizedBox(height: 30)
            ])));
  }
}

// --- Helpers ---
class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 6, dashSpace = 5;
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    Path path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
            pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- Test Page ---
class ChildProfileTestPage extends StatelessWidget {
  final String childName;
  final File? childImage;
  const ChildProfileTestPage(
      {super.key, required this.childName, this.childImage});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("ملف الطفل",
              style: TextStyle(fontFamily: kFontFamily)),
          centerTitle: true,
          backgroundColor: kPrimaryColor,
          automaticallyImplyLeading: false),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: childImage != null ? FileImage(childImage!) : null,
            child: childImage == null
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null),
        const SizedBox(height: 20),
        Text("أهلاً يا $childName!",
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: kFontFamily)),
        const SizedBox(height: 50),
        ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false);
            },
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text("العودة للرئيسية",
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: kFontFamily,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))))
      ])),
    );
  }
}
