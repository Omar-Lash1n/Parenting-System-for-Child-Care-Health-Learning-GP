import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

// استيراد السيرفس والهوم
import 'package:Ajial/api/auth_service.dart'; // تأكد من المسار
import 'package:Ajial/homepage/homepage.dart';

// --- CONSTANTS ---
const String kFontFamily = 'IBM Plex Sans Arabic';
const Color kPrimaryColor = Color(0xFFBF092F);
const Color kBgColor = Colors.white;

// --- موديل مساعد للفواكه (لربط الصورة بالكود) ---
class FruitItem {
  final String imagePath;
  final String code; // الكود للباك اند
  FruitItem(this.imagePath, this.code);
}

class AddChildFlow extends StatefulWidget {
  const AddChildFlow({super.key});

  @override
  State<AddChildFlow> createState() => _AddChildFlowState();
}

class _AddChildFlowState extends State<AddChildFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  int _totalSteps = 4;

  // --- Data Variables ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _childIdController = TextEditingController();

  String? _selectedGender;
  File? _childImage;

  // سنحتفظ بأكواد الفواكه هنا (مثل apple2025) للباك اند
  List<String> _selectedFruitCodes = [];
  // ونحتفظ بمسارات الصور للعرض في الواجهة
  List<String> _selectedFruitImages = [];

  // --- Validation & State ---
  String? _nameError;
  String? _dateError;
  String? _genderError;
  String? _idError;

  bool _isOlderChild = false;
  String? _selectedMonth;
  bool _isLoading = false; // حالة التحميل

  final AuthService _authService = AuthService(); // نسخة من السيرفس

  // --- Fruit Data (Mapping based on PDF Page 13) ---
  // هذه القائمة تربط الصورة بالكود المطلوب
  final List<FruitItem> _fruitsList = [
    FruitItem('images/lemon.png', 'lemon2025'),
    FruitItem('images/grapes.png', 'grape2025'),
    FruitItem('images/orange-juice.png', 'orange2025'),
    FruitItem('images/banana.png', 'banana2025'),
    FruitItem('images/pear.png', 'pear2025'),
    FruitItem('images/apple.png', 'apple2025'),
    FruitItem('images/fig.png', 'fig2025'),
    FruitItem('images/strawberry.png', 'strawberry2025'),
    FruitItem('images/pineapple.png', 'pineapple2025'),
    FruitItem('images/watermelon.png', 'watermelon2025'),
  ];

  final List<Map<String, String>> _monthsList = [
    {'val': '1', 'label': 'يناير (01)'},
    {'val': '2', 'label': 'فبراير (02)'},
    {'val': '3', 'label': 'مارس (03)'},
    {'val': '4', 'label': 'أبريل (04)'},
    {'val': '5', 'label': 'مايو (05)'},
    {'val': '6', 'label': 'يونيو (06)'},
    {'val': '7', 'label': 'يوليو (07)'},
    {'val': '8', 'label': 'أغسطس (08)'},
    {'val': '9', 'label': 'سبتمبر (09)'},
    {'val': '10', 'label': 'أكتوبر (10)'},
    {'val': '11', 'label': 'نوفمبر (11)'},
    {'val': '12', 'label': 'ديسمبر (12)'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _childIdController.dispose();
    _pageController.dispose();
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

  // --- دالة الإرسال للباك اند ---
  Future<void> _submitDataToBackend() async {
    setState(() => _isLoading = true);

    // 1. تجهيز البيانات
    final String fullName = _nameController.text.trim();

    // تجهيز التاريخ
    final int d = int.parse(_dayController.text);
    final int m = int.parse(_monthController.text);
    final int y = int.parse(_yearController.text);
    final DateTime birthDate = DateTime(y, m, d);

    // تجهيز النوع (تحويل small إلى Capital كما في الـ PDF)
    // الـ PDF يطلب "Male" أو "Female"
    final String gender = (_selectedGender == 'male') ? 'Male' : 'Female';

    // 2. استدعاء الـ API
    final result = await _authService.addChild(
      fullName: fullName,
      birthDate: birthDate,
      gender: gender,
      profileImage: _childImage,
      // نرسل بيانات الحساب فقط لو الطفل كبير
      childLoginId: _isOlderChild ? _childIdController.text.trim() : null,
      fruitPasswordCodes: _isOlderChild ? _selectedFruitCodes : null,
    );

    setState(() => _isLoading = false);

    // 3. التعامل مع الرد
    if (result.$1) {
      // نجاح
      // الانتقال لصفحة النجاح
      // (نحتاج للقفز للصفحة الأخيرة وهي رقم 5)
      _pageController.jumpToPage(5);
    } else {
      // فشل - عرض رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.$2, style: const TextStyle(fontFamily: kFontFamily)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateAndProceed(int stepIndex) {
    setState(() {
      _nameError = null;
      _dateError = null;
      _genderError = null;
      _idError = null;

      switch (stepIndex) {
        case 0: // الاسم
          if (_nameController.text.trim().isEmpty) {
            _nameError = "يرجى إدخال اسم الطفل";
          } else {
            _nextPage();
          }
          break;

        case 1: // العمر
          if (_dayController.text.isEmpty ||
              _monthController.text.isEmpty ||
              _yearController.text.isEmpty) {
            _dateError = "يرجى إدخال تاريخ الميلاد كاملاً";
          } else {
            int? d = int.tryParse(_dayController.text);
            int? m = int.tryParse(_monthController.text);
            int? y = int.tryParse(_yearController.text);

            if (d == null ||
                d < 1 ||
                d > 31 ||
                m == null ||
                m < 1 ||
                m > 12 ||
                y == null ||
                y > DateTime.now().year ||
                y < 2000) {
              _dateError = "تاريخ غير صحيح";
            } else {
              final dob = DateTime(y, m, d);
              final now = DateTime.now();
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) age--;

              _isOlderChild = age >= 4;
              _totalSteps = _isOlderChild ? 5 : 4;
              _nextPage();
            }
          }
          break;

        case 2: // النوع
          if (_selectedGender == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("يرجى اختيار نوع الطفل",
                    style: TextStyle(fontFamily: kFontFamily))));
          } else {
            _nextPage();
          }
          break;

        case 3: // الصورة
          if (_isOlderChild) {
            _nextPage(); // طفل كبير -> يروح لصفحة الحساب
          } else {
            // طفل صغير -> يرسل البيانات الآن
            _submitDataToBackend();
          }
          break;

        case 4: // الحساب (للأطفال الكبار)
          if (_childIdController.text.length != 4) {
            _idError = "يجب أن يتكون الرقم من 4 أرقام";
          } else if (_selectedFruitCodes.length != 5) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("يرجى اختيار 5 فواكه لكلمة السر",
                    style: TextStyle(fontFamily: kFontFamily))));
          } else {
            // طفل كبير -> يرسل البيانات الآن
            _submitDataToBackend();
          }
          break;
      }
    });
  }

  // --- Image Picker ---
  void _showImageSourceDialog() {
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: kPrimaryColor),
              title: const Text("اختيار من المعرض",
                  style: TextStyle(fontFamily: kFontFamily)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _childImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ==========================   UI BUILD   ===================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentStep = idx),
            children: [
              _buildNamePage(), // 0
              _buildBirthDatePage(), // 1
              _buildGenderPage(), // 2
              _buildPicturePage(), // 3
              _buildAccountPage(), // 4
              _buildSuccessPage(), // 5
            ],
          ),
        ),
      ),
    );
  }

  // ... (Helper Widgets نفس السابق) ...
  Widget _buildPageLayout(
      {required String title,
      required int stepNumber,
      required Widget content,
      VoidCallback? onNext,
      String nextText = "التالي",
      bool showBack = true,
      bool canSkip = false,
      VoidCallback? onSkip}) {
    int total = _isOlderChild ? 5 : 4;
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
            // زر الإرسال/التالي (مع مؤشر تحميل)
            SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
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
            if (showBack && !_isLoading) ...[
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

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      bool isNumber = false,
      int? maxLength,
      String? errorText}) {
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

  Widget _buildGenderOption(String label, String val, IconData icon) {
    bool selected = _selectedGender == val;
    return GestureDetector(
        onTap: () => setState(() => _selectedGender = val),
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

  Widget _buildMonthDropdown() {
    Color borderColor = Colors.grey[300]!;
    if (_dateError != null)
      borderColor = Colors.red;
    else if (_selectedMonth != null) borderColor = Colors.green;
    return Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor)),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: _selectedMonth,
                hint: Text("شهر",
                    style: TextStyle(
                        color: Colors.grey[400], fontFamily: kFontFamily)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: _monthsList.map((month) {
                  return DropdownMenuItem<String>(
                      value: month['val'],
                      child: Text(month['label']!,
                          style: const TextStyle(
                              fontFamily: kFontFamily, fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMonth = val;
                    _monthController.text = val ?? "";
                  });
                })));
  }

  // --- Pages ---

  Widget _buildNamePage() => _buildPageLayout(
      title: "ادخل اسم الطفل",
      stepNumber: 1,
      showBack: false,
      onNext: () => _validateAndProceed(0),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLabel("اسم الطفل", true),
        const SizedBox(height: 10),
        _buildTextField(
            controller: _nameController,
            hint: "على جمال",
            errorText: _nameError)
      ]));

  Widget _buildBirthDatePage() => _buildPageLayout(
      title: "ادخل عمر الطفل",
      stepNumber: 2,
      onNext: () => _validateAndProceed(1),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLabel("تاريخ ميلاد الطفل", true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _buildTextField(
                  controller: _dayController,
                  hint: "يوم",
                  isNumber: true,
                  maxLength: 2)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _buildMonthDropdown()),
          const SizedBox(width: 10),
          Expanded(
              child: _buildTextField(
                  controller: _yearController,
                  hint: "عام",
                  isNumber: true,
                  maxLength: 4))
        ]),
        if (_dateError != null)
          Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(_dateError!,
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: kFontFamily)))
      ]));

  Widget _buildGenderPage() => _buildPageLayout(
      title: "ادخل نوع الطفل",
      stepNumber: 3,
      onNext: () => _validateAndProceed(2),
      content: Column(children: [
        _buildGenderOption("طفل", "male", Icons.face),
        const SizedBox(height: 15),
        _buildGenderOption("طفلة", "female", Icons.face_3)
      ]));

  Widget _buildPicturePage() {
    return _buildPageLayout(
      title: "اضف صورة الطفل",
      stepNumber: 4,
      canSkip: true,
      onSkip: () => _validateAndProceed(3),
      onNext: () => _validateAndProceed(3),
      content: Center(
          child: Column(children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: _childImage == null
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
                          image: FileImage(_childImage!), fit: BoxFit.cover),
                      border: Border.all(color: Colors.grey[300]!, width: 1))),
        ),
        const SizedBox(height: 20),
        if (_childImage != null)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
                onPressed: _showImageSourceDialog,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child:
                    const Text("تغيير", style: TextStyle(color: Colors.white))),
            const SizedBox(width: 10),
            OutlinedButton(
                onPressed: () => setState(() => _childImage = null),
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

  // --- صفحة الحساب (المعدلة لربط الفواكه بالأكواد) ---
  Widget _buildAccountPage() {
    return _buildPageLayout(
        title: "ادخل بيانات حساب الطفل",
        stepNumber: 5,
        nextText: "انهاء",
        canSkip: true,
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
              errorText: _idError),
          const SizedBox(height: 25), _buildLabel("كلمة المرور", true),
          const SizedBox(height: 10),

          // خانات كلمة السر
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                bool filled = index <
                    _selectedFruitImages.length; // نستخدم قائمة الصور للعرض
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
                            child: Image.asset(_selectedFruitImages[index]))
                        : null);
              })),
          const SizedBox(height: 20),

          // شبكة الفواكه
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: _fruitsList.length,
              itemBuilder: (ctx, idx) {
                return GestureDetector(
                    onTap: () {
                      if (_selectedFruitImages.length < 5) {
                        setState(() {
                          // إضافة المسار للعرض
                          _selectedFruitImages.add(_fruitsList[idx].imagePath);
                          // إضافة الكود للإرسال
                          _selectedFruitCodes.add(_fruitsList[idx].code);
                        });
                      }
                    },
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(_fruitsList[idx].imagePath)));
              }),

          if (_selectedFruitImages.isNotEmpty)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: () => setState(() {
                          _selectedFruitImages.clear();
                          _selectedFruitCodes.clear();
                        }),
                    icon: const Icon(Icons.refresh, color: kPrimaryColor),
                    label: const Text("إعادة تعيين",
                        style: TextStyle(
                            color: kPrimaryColor, fontFamily: kFontFamily))))
        ]));
  }

  Widget _buildSuccessPage() {
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
                                    childImage: _childImage)));
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
                  MaterialPageRoute(builder: (context) =>  HomeScreen()),
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
