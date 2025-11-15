// --- data_entry_page.dart (Updated with Sticky Buttons & Fade Transition) ---

import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/login.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFC7002B);
const Color kMainRed = Color(0xFFBF092F);
const Color kFontBlack = Colors.black;
const String kFontFamily = 'IBM Plex Sans Arabic';
const String kLogoImagePath = 'images/logo-primary-color.png'; // (افترض أنه 'images/main-logo.png' ليطابق الصفحات الأخرى)

// --- تعديل: إضافة كلاس مساعد لتأثير التلاشي ---
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300), // سرعة تلاشي عادية
        );
}
// --- نهاية الإضافة ---

class DataEntryPage extends StatefulWidget {
  const DataEntryPage({super.key});

  @override
  _DataEntryPageState createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  String? _selectedCity;
  DateTime? _selectedDateOfBirth;
  String? _selectedRole; // 'أب', 'أم', 'مربي'
  

  // (قائمة المدن كما هي)
  final List<String> _cities = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'الشرقية', 'المنوفية',
    'القليوبية', 'البحيرة', 'الغربية', 'بورسعيد', 'دمياط', 'الإسماعماعيلية',
    'السويس', 'كفر الشيخ', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط',
    'سوهاج', 'قنا', 'الأقصر', 'أسوان', 'البحر الأحمر', 'الوادي الجديد',
    'مطروح', 'شمال سيناء', 'جنوب سيناء', 'حلوان', '6 أكتوبر', 'المنصورة',
    'طنطا', 'الزقازيق', 'المحلة الكبرى', 'شبرا الخيمة', 'دهب', 'شرم الشيخ',
    'الغردقة', 'العريش', 'رفح', 'الشيخ زويد', 'العاشر من رمضان', 'مدينة السادات'
  ];

  /// دالة عرض منتقي التاريخ (Date Picker) (كما هي)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(DateTime.now().year - 20),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kMainRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  /// دالة لمعالجة البيانات (مع تعديل الانتقال)
  void _submitForm() {
    if (_selectedCity == null ||
        _selectedDateOfBirth == null ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء تعبئة جميع الحقول المطلوبة',
            style: TextStyle(fontFamily: kFontFamily),
          ),
          backgroundColor: kMainRed,
        ),
      );
      return;
    }

    print('Form Submitted!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم انشاء الحساب بنجاح!',
          style: TextStyle(fontFamily: kFontFamily),
        ),
        backgroundColor: Colors.green,
      ),
    );

    // --- تعديل: استخدام FadePageRoute للانتقال ---
    Navigator.pushReplacement(
      context,
      FadePageRoute(child: const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- تعديل: جلب أبعاد الشاشة للاستجابة ---
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // (الثوابت كما هي)
    const double mainButtonHeight = 55.0;
    const double fieldAndRoleButtonHeight = 50.0;
    const double mainBorderRadius = 50.0; // <-- تعديل ليتطابق (50)
    const double fieldBorderRadius = 50.0; // <-- تعديل ليتطابق (50)

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false, // (إخفاء سهم الرجوع الافتراضي)
      ),
      // --- تعديل: استخدام Column لتقسيم الشاشة (محتوى + أزرار) ---
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. المحتوى القابل للـ Scroll ---
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600, // لدعم التابلت
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 40.0 : 24.0, // بادنج متجاوب
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // --- اللوجو والعنوان ---
                          SizedBox(height: screenHeight * 0.02), // (مسافة أقل)
                          Center(
                            child: Image.asset(
                              'images/main-logo.png', // <-- (توحيد المسار)
                              height: screenHeight * 0.15, // (حجم متجاوب)
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildHeaderLabel(
                            'تابع ادخال البيانات',
                            fontSize: 26, // (حجم موحد)
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4), // (مسافة أقل)
                          _buildHeaderLabel(
                            'من فضلك ادخل البيانات بعناية',
                            fontSize: 16, // (حجم موحد)
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: screenHeight * 0.04), // (مسافة متجاوبة)

                          // --- 1. حقل اختيار المدينة ---
                          _buildFieldLabel('المدينة *'), // (تمت إضافة النجمة)
                          const SizedBox(height: 8),
                          Container(
                            height: fieldAndRoleButtonHeight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 1.5),
                              borderRadius:
                                  BorderRadius.circular(fieldBorderRadius),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: Text(
                                  'اختر مدينتك من القائمة',
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                value: _selectedCity,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCity = newValue;
                                  });
                                },
                                items: _cities.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontFamily: kFontFamily,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // --- 2. حقل تاريخ الميلاد ---
                          _buildFieldLabel('تاريخ الميلاد *'), // (تمت إضافة النجمة)
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              height: fieldAndRoleButtonHeight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade400, width: 1.5),
                                borderRadius:
                                    BorderRadius.circular(fieldBorderRadius),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end, // (لضمان المحاذاة يميناً)
                                children: <Widget>[
                                  Text(
                                    _selectedDateOfBirth == null
                                        ? 'اضغط لإدخال تاريخ الميلاد'
                                        : DateFormat('yyyy/MM/dd')
                                            .format(_selectedDateOfBirth!),
                                    style: TextStyle(
                                      fontFamily: kFontFamily,
                                      fontSize: 15,
                                      color: _selectedDateOfBirth == null
                                          ? Colors.grey.shade600
                                          : kFontBlack,
                                    ),
                                  ),
                                  const Spacer(), // (لدفع الأيقونة لليسار)
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // --- 3. حقول اختيار الدور (أب، أم، مربي) ---
                          _buildFieldLabel('من أنت؟ *'), // (تمت إضافة النجمة)
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              _buildRoleButton(
                                  'مربي', fieldAndRoleButtonHeight, fieldBorderRadius),
                              const SizedBox(width: 10),
                              _buildRoleButton(
                                  'أم', fieldAndRoleButtonHeight, fieldBorderRadius),
                              const SizedBox(width: 10),
                              _buildRoleButton(
                                  'أب', fieldAndRoleButtonHeight, fieldBorderRadius),
                            ].reversed.toList(), // (للحفاظ على الترتيب أب، أم، مربي)
                          ),
                          
                          // --- تعديل: تم حذف الأزرار من هنا ---
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // --- 2. الأزرار الثابتة في الأسفل ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // --- 4. زر إنشاء حساب جديد ---
                  SizedBox(
                    height: mainButtonHeight,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainRed,
                        minimumSize: const Size(double.infinity, 50), // (للتأكيد)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(mainBorderRadius),
                        ),
                      ),
                      child: const Text(
                        'انشاء حساب جديد',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- 5. زر السابق ---
                  SizedBox(
                    height: mainButtonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side:
                            const BorderSide(color: Colors.black12, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(mainBorderRadius),
                        ),
                        minimumSize: const Size(double.infinity, 50), // (للتأكيد)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // --- تعديل: أيقونة السهم لليمين (RTL Back) ---
                          const Icon(
                            Icons.arrow_forward,
                            color: kFontBlack,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'السابق',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 18,
                              color: kFontBlack,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // (مسافة موحدة)

                  // --- 6. رابط تسجيل الدخول ---
                  Center(
                    child: TextButton( // (تم تحويله لـ TextButton ليكون قابلاً للضغط)
                      onPressed: () {
                        // --- تعديل: إضافة انتقال بالتلاشي ---
                        Navigator.push(
                          context,
                          FadePageRoute(child: const LoginScreen()),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                          children: <TextSpan>[
                            const TextSpan(text: 'لديك حساب بالفعل؟ '),
                            TextSpan(
                              text: 'تسجيل الدخول',
                              style: TextStyle(
                                color: kMainRed,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline, // (إضافة خط)
                                decorationColor: kMainRed,
                              ),
                            ),
                          ],
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
    );
  }

  /// دالة لبناء زر الاختيار (أب/أم/مربي)
  Widget _buildRoleButton(String role, double height, double radius) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            // --- تعديل: لون خلفية موحد (مطابق للصورة) ---
            color: isSelected ? kMainRed.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isSelected ? kMainRed : Colors.grey.shade400,
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              role,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 16,
                // --- تعديل: لون نص موحد (مطابق للصورة) ---
                color: isSelected ? kMainRed : kFontBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// دالة لبناء Labeles العناوين الرئيسية والفرعية
  Widget _buildHeaderLabel(
    String text, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? kFontBlack,
        ),
      ),
    );
  }

  // --- تعديل: الدالة الجديدة لـ Label مع النجمة الحمراء ---
  /// دالة لبناء Labeles فوق الحقول
  Widget _buildFieldLabel(String text) {
    // (هنا نفترض أن كل الحقول مطلوبة)
    final String label = text;
    final String asterisk = ' *';

    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kFontBlack,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: asterisk,
              style: const TextStyle(
                color: kMainRed,
                fontSize: 18, // (تكبير النجمة قليلاً)
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}