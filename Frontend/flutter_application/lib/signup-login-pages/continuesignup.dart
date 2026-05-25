// --- continuesignup.dart (Refactored with Provider Pattern) ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Ajial/providers/continue_signup_provider.dart';
import 'package:Ajial/signup-login-pages/login.dart';

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFC7002B);
const Color kMainRed = Color(0xFFBF092F);
const Color kFontBlack = Colors.black;
const String kFontFamily = 'IBM Plex Sans Arabic';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class DataEntryPage extends StatefulWidget {
  final String fullName;
  final String username;
  final String email;
  final String password;

  const DataEntryPage({
    super.key,
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  _DataEntryPageState createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  // Cache screen dimensions to avoid rebuilds on keyboard
  late double _screenHeight;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    // Fetch cities from API when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContinueSignupProvider>().fetchCities();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _screenHeight = size.height;
    _screenWidth = size.width;
  }

  @override
  void dispose() {
    // Reset provider state when leaving screen
    context.read<ContinueSignupProvider>().reset();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<ContinueSignupProvider>();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          provider.selectedDateOfBirth ?? DateTime(DateTime.now().year - 20),
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
    if (picked != null) {
      provider.setDateOfBirth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double mainButtonHeight = 55.0;
    const double fieldAndRoleButtonHeight = 50.0;
    const double mainBorderRadius = 50.0;
    const double fieldBorderRadius = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<ContinueSignupProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // --- 1. Scrollable Content ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _screenWidth > 600 ? 40.0 : 24.0,
                            vertical: 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // --- Logo and Title ---
                              SizedBox(height: _screenHeight * 0.02),
                              Center(
                                child: Image.asset(
                                  'images/main-logo.png',
                                  height: _screenHeight * 0.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildHeaderLabel(
                                'تابع ادخال البيانات',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(height: 4),
                              _buildHeaderLabel(
                                'من فضلك ادخل البيانات بعناية',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: _screenHeight * 0.04),

                              // --- 1. City Selection ---
                              _buildFieldLabel('المدينة *'),
                              const SizedBox(height: 8),
                              provider.isCitiesLoading
                                  ? Container(
                                      height: fieldAndRoleButtonHeight,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            fieldBorderRadius),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFBF092F),
                                          ),
                                        ),
                                      ),
                                    )
                                  : provider.citiesError != null &&
                                          provider.cities.isEmpty
                                      ? GestureDetector(
                                          onTap: () => provider.fetchCities(),
                                          child: Container(
                                            height: fieldAndRoleButtonHeight,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.red.shade300,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      fieldBorderRadius),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.refresh,
                                                    color:
                                                        Colors.red.shade400,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  provider.citiesError!,
                                                  style: TextStyle(
                                                    fontFamily: kFontFamily,
                                                    fontSize: 13,
                                                    color:
                                                        Colors.red.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: fieldAndRoleButtonHeight,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    fieldBorderRadius),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              isExpanded: true,
                                              hint: Text(
                                                'اختر مدينتك من القائمة',
                                                style: TextStyle(
                                                  fontFamily: kFontFamily,
                                                  color:
                                                      Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              value:
                                                  provider.selectedCityId,
                                              icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.grey,
                                              ),
                                              onChanged: provider.isLoading
                                                  ? null
                                                  : (int? newValue) {
                                                      provider
                                                          .setCity(newValue);
                                                    },
                                              items: provider.cities
                                                  .map<DropdownMenuItem<int>>((
                                                Map<String, dynamic> city,
                                              ) {
                                                return DropdownMenuItem<int>(
                                                  value: city['id'] as int,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      city['nameAr']
                                                          as String,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            kFontFamily,
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

                              // --- 2. Date of Birth ---
                              _buildFieldLabel('تاريخ الميلاد *'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: provider.isLoading
                                    ? null
                                    : () => _selectDate(context),
                                child: Container(
                                  height: fieldAndRoleButtonHeight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        fieldBorderRadius),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        provider.selectedDateOfBirth == null
                                            ? 'اضغط لإدخال تاريخ الميلاد'
                                            : DateFormat('yyyy/MM/dd').format(
                                                provider.selectedDateOfBirth!),
                                        style: TextStyle(
                                          fontFamily: kFontFamily,
                                          fontSize: 15,
                                          color: provider.selectedDateOfBirth ==
                                                  null
                                              ? Colors.grey.shade600
                                              : kFontBlack,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- 3. Role Selection ---
                              _buildFieldLabel('من أنت؟ *'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  _buildRoleButton(
                                    'أم',
                                    fieldAndRoleButtonHeight,
                                    mainBorderRadius,
                                    provider,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildRoleButton(
                                    'أب',
                                    fieldAndRoleButtonHeight,
                                    mainBorderRadius,
                                    provider,
                                  ),
                                ].reversed.toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- 2. Sticky Buttons at Bottom ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      // --- Submit Button ---
                      SizedBox(
                        height: mainButtonHeight,
                        child: provider.isLoading
                            ? const Center(
                                child:
                                    CircularProgressIndicator(color: kMainRed),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  provider.submitRegistration(
                                    fullName: widget.fullName,
                                    username: widget.username,
                                    email: widget.email,
                                    password: widget.password,
                                    context: context,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMainRed,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(mainBorderRadius),
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

                      // --- Back Button ---
                      SizedBox(
                        height: mainButtonHeight,
                        child: OutlinedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.black12,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(mainBorderRadius),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
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
                      const SizedBox(height: 16),

                      // --- Login Link ---
                      Center(
                        child: TextButton(
                          onPressed: provider.isLoading
                              ? null
                              : () {
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
                                    decoration: TextDecoration.underline,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, double height, double radius,
      ContinueSignupProvider provider) {
    bool isSelected = provider.selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: provider.isLoading
            ? null
            : () {
                provider.setRole(role);
              },
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
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
                color: isSelected ? kMainRed : kFontBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildFieldLabel(String text) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
