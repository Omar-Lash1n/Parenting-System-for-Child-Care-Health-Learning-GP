// // --- continuesignup.dart ---

// import 'package:flutter/material.dart';
// import 'package:flutter_application/signup-login-pages/login.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:intl/intl.dart';

// // --- Global Constants ---
// const Color kPrimaryColor = Color(0xFFBF092F);
// const String kFontFamily = 'IBM Plex Sans Arabic';

// // --- شاشة متابعة التسجيل ---
// class ContinueSignUpScreen extends StatefulWidget {
//   const ContinueSignUpScreen({Key? key}) : super(key: key);

//   @override
//   _ContinueSignUpScreenState createState() => _ContinueSignUpScreenState();
// }

// class _ContinueSignUpScreenState extends State<ContinueSignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _dobController = TextEditingController(); // لحقل تاريخ الميلاد

//   String? _selectedCity; // المدينة المختارة
//   int? _selectedRoleIndex; // الاختيار (0=مربي, 1=أم, 2=أب)
//   final List<String> _roles = const ['مربي', 'أم', 'أب'];

  // // قائمة المدن والمحافظات المصرية
  // final List<String> _egyptianCities = [
  //   'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'الشرقية', 'المنوفية',
  //   'القليوبية', 'البحيرة', 'الغربية', 'بورسعيد', 'دمياط', 'الإسماعيلية',
  //   'السويس', 'كفر الشيخ', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط',
  //   'سوهاج', 'قنا', 'الأقصر', 'أسوان', 'البحر الأحمر', 'الوادي الجديد',
  //   'مطروح', 'شمال سيناء', 'جنوب سيناء', 'حلوان', '6 أكتوبر', 'المنصورة',
  //   'طنطا', 'الزقازيق', 'المحلة الكبرى', 'شبرا الخيمة', 'دهب', 'شرم الشيخ',
  //   'الغردقة', 'العريش', 'رفح', 'الشيخ زويد', 'العاشر من رمضان', 'مدينة السادات'
  // ];

//   @override
//   void dispose() {
//     _dobController.dispose();
//     super.dispose();
//   }

//   /// دالة لإظهار منتقي التاريخ (Calendar Picker)
//   Future<void> _pickDate() async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(), // تاريخ اليوم
//       firstDate: DateTime(1920), // أقدم تاريخ ميلاد ممكن
//       lastDate: DateTime.now(), // لا يمكن اختيار تاريخ في المستقبل
//       locale: const Locale('ar'), // تفعيل اللغة العربية للـ Picker
//       builder: (context, child) {
//         // ستايل للـ Picker عشان يمشي مع لون التطبيق
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: kPrimaryColor, // لون الهيدر واليوم المختار
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: kPrimaryColor, // لون أزرار (OK/Cancel)
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedDate != null) {
//       // تنسيق التاريخ بالشكل المطلوب (yyyy/MM/dd)
//       String formattedDate = DateFormat('yyyy/MM/dd').format(pickedDate);
//       setState(() {
//         _dobController.text = formattedDate; // وضع التاريخ في الحقل
//       });
//     }
//   }

//   /// دالة للـ Validation والـ Submit
//   void _submitForm() {
//     // التحقق من أن المستخدم اختار دور (أب/أم/مربي)
//     if (_selectedRoleIndex == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('الرجاء تحديد "من أنت؟" أولاً',
//               style: TextStyle(fontFamily: kFontFamily)),
//           backgroundColor: kPrimaryColor,
//         ),
//       );
//       return; // أوقف التنفيذ
//     }

//     // التحقق من باقي الفورم (المدينة وتاريخ الميلاد)
//     if (_formKey.currentState!.validate()) {
//       // --- هنا يتم إرسال البيانات للـ Backend ---
//       print('Form is valid!');
//       print('City: $_selectedCity');
//       print('Date of Birth: ${_dobController.text}');
//       print('Role: ${_roles[_selectedRoleIndex!]}');

//       // --- *** مكان الانتقال للصفحة التالية بعد انشاء الحساب *** ---
//       // شيل الكومنت وحط اسم الصفحة اللي عاوز تروحها
//       /*
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()), 
//       );
//       */
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('تم انشاء الحساب بنجاح!',
//               style: TextStyle(fontFamily: kFontFamily)),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   const SizedBox(height: 40),
//                   // --- اللوجو ---
//                   Center(
//                     child: Image.asset(
//                       'images/main-logo.png',
//                       width: 80,
//                       height: 80,
//                       errorBuilder: (context, error, stackTrace) =>
//                           const Icon(Icons.group, size: 80, color: kPrimaryColor),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // --- العناوين ---
//                   const Center(
//                     child: Text(
//                       'تابع ادخال البيانات',
//                       style: TextStyle(
//                         fontFamily: kFontFamily,
//                         fontSize: 26,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Center(
//                     child: Text(
//                       'من فضلك ادخل البيانات بعناية',
//                       style: TextStyle(
//                         fontFamily: kFontFamily,
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // --- حقل المدينة (Dropdown قابل للبحث) ---
//                   _buildLabel('المدينة *'),
//                   const SizedBox(height: 8),
//                   DropdownSearch<String>(
//                     mode: Mode.MODAL, // يفتح في شاشة جديدة
//                     showSearchBox: true, // تفعيل صندوق البحث
//                     items: _egyptianCities, // قائمة المدن
//                     // ستايل الـ Dropdown عشان يطابق الـ TextFormField
//                     dropdownSearchDecoration: _buildInputDecoration(
//                       hintText: 'اختر مدينتك من القائمة',
//                       // الأيقونة اللي بتظهر (السهم)
//                       suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
//                     ),
//                     // ستايل صندوق البحث داخل الـ Modal
//                     searchFieldProps: TextFieldProps(
//                       textDirection: TextDirection.rtl, // الكتابة عربي
//                       decoration: _buildInputDecoration(
//                         hintText: 'ابحث عن مدينتك...',
//                         prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
//                       ),
//                       style: const TextStyle(fontFamily: kFontFamily),
//                     ),
//                     // ستايل الـ Modal
//                     modalSheetProps: ModalSheetProps(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedCity = value;
//                       });
//                     },
//                     validator: (value) {
//                       if (value == null) {
//                         return 'الرجاء اختيار مدينتك';
//                       }
//                       return null;
//                     },
//                     // لضمان أن الـ hint يظهر من اليمين
//                     popupProps: PopupProps.modal(
//                       itemBuilder: (context, item, isSelected) {
//                         return ListTile(
//                           title: Text(item,
//                               style: const TextStyle(fontFamily: kFontFamily),
//                               textAlign: TextAlign.right),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // --- حقل تاريخ الميلاد (Picker) ---
//                   _buildLabel('تاريخ الميلاد *'),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _dobController,
//                     readOnly: true, // يمنع الكتابة اليدوية
//                     decoration: _buildInputDecoration(
//                       hintText: 'اضغط لادخال تاريخ الميلاد',
//                       // أيقونة الـ Calendar
//                       prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
//                     ),
//                     onTap: _pickDate, // فتح الـ Picker عند الضغط
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'تاريخ الميلاد مطلوب';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),

//                   // --- اختيارات "من أنت؟" ---
//                   _buildLabel('من أنت؟ *'),
//                   const SizedBox(height: 8),
//                   Center(
//                     child: ToggleButtons(
//                       // قائمة الاختيارات
//                       children: _roles.map((role) {
//                         return Padding(
//                           // زيادة المساحة الأفقية لكل زر
//                           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                           child: Text(
//                             role,
//                             style: const TextStyle(
//                               fontFamily: kFontFamily,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
                            
//                           ),
//                         );
//                       }).toList(),
//                       // قائمة الـ boolean لتحديد المختار
//                       isSelected: List<bool>.generate(
//                           3, (index) => index == _selectedRoleIndex),
//                       onPressed: (int index) {
//                         setState(() {
//                           _selectedRoleIndex = index; // تحديث الاختيار
//                         });
//                       },
//                       // --- ستايل مطابقة الصورة ---
//                       color: Colors.black, // لون النص غير المختار
//                       selectedColor: kPrimaryColor, // لون النص المختار (أحمر)
//                       fillColor: kPrimaryColor.withOpacity(0.1), // الخلفية الحمراء الفاتحة
//                       borderColor: Colors.grey[400], // لون الحد غير المختار
//                       selectedBorderColor: kPrimaryColor, // لون الحد المختار (أحمر)
//                       borderRadius: BorderRadius.circular(12),
//                       borderWidth: 1.5,
//                       selectedBorderWidth: 2.0,
//                       constraints: const BoxConstraints(minHeight: 50.0),
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // --- زر "انشاء حساب جديد" ---
//                   ElevatedButton(
//                     onPressed: _submitForm, // دالة الـ Submit
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: kPrimaryColor,
//                       minimumSize: const Size(double.infinity, 50),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     child: const Text(
//                       'انشاء حساب جديد',
//                       style: TextStyle(
//                         fontFamily: kFontFamily,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // --- رابط "تسجيل الدخول" ---
//                   Center(
//                     child: TextButton(
//                       onPressed: () {
//                         // --- *** مكان الانتقال لصفحة تسجيل الدخول *** ---
//                         // شيل الكومنت وحط اسم صفحة تسجيل الدخول
                        
//                         Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(builder: (context) => const LoginScreen()),
//                           (Route<dynamic> route) => false, // احذف كل الصفحات اللي قبل
//                         );
                        
//                         print('Navigate to Login Screen');
//                       },
//                       child: RichText(
//                         text: const TextSpan(
//                           style: TextStyle(
//                               fontFamily: kFontFamily,
//                               fontSize: 15,
//                               color: Colors.black87),
//                           children: [
//                             TextSpan(text: 'لديك حساب بالفعل؟ '),
//                             TextSpan(
//                               text: 'تسجيل الدخول',
//                               style: TextStyle(
//                                 color: kPrimaryColor,
//                                 fontWeight: FontWeight.bold,
//                                 decoration: TextDecoration.underline,
//                                 decorationColor: kPrimaryColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// دالة لإنشاء الـ Label فوق كل حقل
//   Widget _buildLabel(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontFamily: kFontFamily,
//         fontSize: 16,
//         fontWeight: FontWeight.w500,
//         color: Colors.black,
//       ),
//     );
//   }

//   /// دالة لتوحيد شكل الـ InputDecoration (مستخدمة من الكود السابق)
//   InputDecoration _buildInputDecoration({
//     required String hintText,
//     Widget? prefixIcon,
//     Widget? suffixIcon,
//   }) {
//     final defaultBorderColor = Colors.grey[400]!;
//     final defaultFocusedBorderColor = kPrimaryColor;
//     final defaultErrorBorderColor = kPrimaryColor;

//     return InputDecoration(
//       hintText: hintText,
//       hintStyle: const TextStyle(fontFamily: kFontFamily, color: Colors.grey),
//       prefixIcon: prefixIcon,
//       suffixIcon: suffixIcon,
//       hintTextDirection: TextDirection.rtl,
//       prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: defaultBorderColor),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: defaultBorderColor, width: 1.5),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: defaultFocusedBorderColor, width: 2.0),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: defaultErrorBorderColor, width: 1.5),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: defaultErrorBorderColor, width: 2.0),
//       ),
//       errorStyle: const TextStyle(
//         fontFamily: kFontFamily,
//         color: kPrimaryColor,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }
// }