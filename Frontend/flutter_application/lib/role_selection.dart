import 'package:Ajial/child-app/child-sign-in.dart';
import 'package:flutter/material.dart';
// Import ParentWelcomeScreen for parent navigation
import 'ParentWelcomeScreen.dart';

// تعريف كلاس للصفحة الجديدة
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  // Cache screen dimensions to avoid rebuilds on keyboard
  late double _screenHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight = MediaQuery.of(context).size.height;
  }

  // تعريف قائمة بيانات الأدوار مع الألوان المخصصة
  final List<Map<String, dynamic>> _rolesData = [
    {
      "roleValue": "parent",
      "icon": Icons.people,
      "title": "أحد الوالدين",
      "description": "إدارة رعاية طفلك وتنميته",
      "color": const Color(0xFFBF092F), // اللون المخصص للوالدين #BF092F
    },
    {
      "roleValue": "child",
      "icon": Icons.face_retouching_natural,
      "title": "طفل",
      "description": "انضم لعالم المكافآت",
      "color": const Color(0xFF008CFF), // اللون المخصص للطفل #008CFF
    },
    {
      "roleValue": "specialist",
      "icon": Icons.work,
      "title": "متخصص",
      "description": "قدم استشاراتك الموثقة",
      "color": const Color(0xFF01A449), // اللون المخصص للمتخصص #01A449
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color defaultButtonColor = Color(
      0xFFBF002D,
    ); // لون الزر "التالي" الافتراضي
    const Color lightGrey = Color(0xFFF5F5F5); // لون خلفية البطاقة غير المختارة
    const Color textBlack = Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: _screenHeight * 0.02),
                const Text(
                  "ابدأ رحلتك نحو التميز!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textBlack,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "سيساعدنا اختيارك لدورك على تهيئة\nمساحتك الخاصة",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: _screenHeight * 0.04),
                ..._rolesData.map((roleData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildRoleCard(
                      icon: roleData["icon"] as IconData,
                      title: roleData["title"] as String,
                      description: roleData["description"] as String,
                      roleValue: roleData["roleValue"] as String,
                      selectionColor: roleData["color"] as Color,
                      isSelected: _selectedRole == roleData["roleValue"],
                      onTap: () {
                        setState(() {
                          _selectedRole = roleData["roleValue"] as String;
                        });
                      },
                    ),
                  );
                }).toList(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedRole != null) {
                        // إذا تم اختيار دور، قم بالمعالجة أو الانتقال
                        print("الدور المختار: $_selectedRole");
                        if (_selectedRole == "parent") {
                          // Navigate to ParentWelcomeScreen when parent is selected
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const ParentWelcomeScreen(),
                            ),
                          );
                        } else if (_selectedRole == "child") {
                          // الانتقال لصفحة تسجيل دخول الطفل
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              // (تأكد من استيراد ChildLoginScreen في الأعلى)
                              builder: (context) => const ChildLoginScreen(),
                            ),
                          );
                        } else {
                          // يمكنك إضافة منطق للانتقال لأدوار أخرى (طفل، متخصص)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم اختيار دور: $_selectedRole'),
                            ),
                          );
                        }
                      } else {
                        // إذا لم يتم اختيار دور، أظهر AlertDialog المخصص مع تأثير التلاشي
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: MaterialLocalizations.of(
                            context,
                          ).modalBarrierDismissLabel,
                          barrierColor: Colors.black.withOpacity(0.5),
                          transitionDuration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                              child: child,
                            );
                          },
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            // هذا هو محتوى الـ AlertDialog نفسه
                            return Center(
                              child: AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                contentPadding: const EdgeInsets.all(24),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // أيقونة التحذير
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFBF092F,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFBF092F),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // عنوان الرسالة
                                    const Text(
                                      "يرجى اختيار دورك",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: textBlack,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    // وصف الرسالة
                                    const Text(
                                      "سيساعدنا اختيارك لدورك على تهيئة\nمساحتك الخاصة",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    // زر "حسنًا"
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                          ).pop(); // إغلاق الـ AlertDialog
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: defaultButtonColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          "حسنًا",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: defaultButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "التالي",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // الكود الخاص بدالة _buildRoleCard
  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String description,
    required String roleValue,
    required Color selectionColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const Color lightGrey = Color(0xFFF5F5F5);
    const Color textBlack = Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? selectionColor.withOpacity(0.1) : lightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectionColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? selectionColor : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : selectionColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? selectionColor : textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected
                          ? selectionColor.withOpacity(0.7)
                          : Colors.black54,
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
}
