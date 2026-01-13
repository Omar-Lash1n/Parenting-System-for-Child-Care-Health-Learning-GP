// --- lib/child-app/child-sign-in.dart (Fixed Input Limit & Generic Error Audio) ---

import 'dart:async';
import 'package:Ajial/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:Ajial/child-app/child-home.dart';
import 'package:Ajial/child-app/home/child_home_page.dart';
import 'package:Ajial/role_selection.dart';

// --- الثوابت والألوان ---
const String kFontFamily = 'IBM Plex Sans Arabic';
const Color kBgColorTop = Color(0x80B0CEE3);
const Color kBgColorBottom = Color(0x00B0CEE3);
const Color kErrorColor = Color(0xFFD90000);
const Color kButtonMainColor = Color(0xFF008CFF);
const Color kButtonShadowColor = Color(0xFF00579E);
const Color kSuccessBorderColor = Color(0xFF01A449);
const Color kDefaultShadowColor = Color(0xFFB0BEC5);

// --- موديل الفاكهة ---
class Fruit {
  final String id;
  final String code;
  final String name;
  final String imagePath;
  final String audioPath;
  final Color backgroundColor;

  Fruit({
    required this.id,
    required this.code,
    required this.name,
    required this.imagePath,
    required this.audioPath,
    required this.backgroundColor,
  });
}

// --- زر الألعاب ثلاثي الأبعاد ---
class GameButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback onTap;
  final Color color;
  final Color shadowColor;
  final double height;
  final double width;
  final double fontSize;

  const GameButton({
    super.key,
    this.text,
    this.child,
    required this.onTap,
    this.color = kButtonMainColor,
    this.shadowColor = kButtonShadowColor,
    this.height = 55,
    this.width = double.infinity,
    this.fontSize = 22,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 6.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        height: widget.height + shadowHeight,
        width: widget.width,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.shadowColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeInOut,
              top: _isPressed ? shadowHeight : 0,
              bottom: _isPressed ? 0 : shadowHeight,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: widget.child ??
                      Text(
                        widget.text ?? "",
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: widget.fontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Dashed Border Painter ---
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
    );

    final Path dashedPath = Path();
    final ui.PathMetrics pathMetrics = path.computeMetrics();

    for (ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- Success Dialog Widget ---
class SuccessDialog extends StatelessWidget {
  final String childName;
  final String? profileImageUrl;
  final int? age;

  const SuccessDialog({
    super.key,
    required this.childName,
    this.profileImageUrl,
    this.age,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 3),
                onEnd: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChildHomePage(
                        childName: childName,
                        initialStars: 0,
                        isFirstLogin: true,
                      ),
                    ),
                  );
                },
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSuccessBorderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  profileImageUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.emoji_emotions,
                      size: 80,
                      color: kSuccessBorderColor,
                    );
                  },
                ),
              )
            else
              const Icon(
                Icons.emoji_emotions,
                size: 80,
                color: kSuccessBorderColor,
              ),

            const SizedBox(height: 20),

            Text(
              "أهلاً $childName! ",
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            if (age != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "$age سنوات",
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Icon(
              Icons.workspace_premium,
              size: 60,
              color: kSuccessBorderColor,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Child Login Screen ---
class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();

  final AudioPlayer _mainPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final List<Fruit> availableFruits = [
    Fruit(
      id: '1',
      code: 'apple2025',
      name: 'تفاح',
      imagePath: 'images/apple.png',
      audioPath: 'sounds/apple.mp3',
      backgroundColor: const Color(0xFFFFCDD2),
    ),
    Fruit(
      id: '2',
      code: 'banana2025',
      name: 'موز',
      imagePath: 'images/banana.png',
      audioPath: 'assets/sounds/banana.mp3',
      backgroundColor: const Color(0xFFFFF9C4),
    ),
    Fruit(
      id: '3',
      code: 'orange2025',
      name: 'برتقال',
      imagePath: 'images/orange-juice.png',
      audioPath: 'assets/sounds/orange.mp3',
      backgroundColor: const Color(0xFFFFCC80),
    ),
    Fruit(
      id: '4',
      code: 'grape2025',
      name: 'عنب',
      imagePath: 'images/grapes.png',
      audioPath: 'assets/sounds/grape.mp3',
      backgroundColor: const Color(0xFFE1BEE7),
    ),
    Fruit(
      id: '5',
      code: 'pear2025',
      name: 'كمثرى',
      imagePath: 'images/pear.png',
      audioPath: 'assets/sounds/pear.mp3',
      backgroundColor: const Color(0xFFC8E6C9),
    ),
    Fruit(
      id: '6',
      code: 'strawberry2025',
      name: 'فراولة',
      imagePath: 'images/strawberry.png',
      audioPath: 'assets/sounds/strawberry.mp3',
      backgroundColor: const Color(0xFFEF9A9A),
    ),
    Fruit(
      id: '7',
      code: 'watermelon2025',
      name: 'بطيخ',
      imagePath: 'images/watermelon.png',
      audioPath: 'assets/sounds/watermelon.mp3',
      backgroundColor: const Color(0xFFA5D6A7),
    ),
    Fruit(
      id: '8',
      code: 'pineapple2025',
      name: 'أناناس',
      imagePath: 'images/pineapple.png',
      audioPath: 'assets/sounds/pineapple.mp3',
      backgroundColor: const Color(0xFFFFF176),
    ),
    Fruit(
      id: '9',
      code: 'fig2025',
      name: 'تين',
      imagePath: 'images/fig.png',
      audioPath: 'assets/sounds/fig.mp3',
      backgroundColor: const Color(0xFFD1C4E9),
    ),
    Fruit(
      id: '10',
      code: 'lemon2025',
      name: 'ليمون',
      imagePath: 'images/lemon.png',
      audioPath: 'assets/sounds/lemon.mp3',
      backgroundColor: const Color(0xFFFFF59D),
    ),
  ];

  List<Fruit> selectedPassword = [];

  bool isIdFocused = false;
  bool isIdCompleted = false;
  bool isIdError = false;

  bool showError = false;
  bool showQuestionMarks = false;
  String errorMessage = "";
  String errorAction = "";
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();

    _sfxPlayer.setVolume(0.3);

    _idController.addListener(() {
      setState(() {
        isIdCompleted = _idController.text.length >= 4;
        if (showError) _hideToast();
        if (isIdCompleted || _idController.text.isNotEmpty) isIdError = false;
      });
    });

    _idFocusNode.addListener(() {
      setState(() {
        isIdFocused = _idFocusNode.hasFocus;
      });
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _playSound('assets/sounds/welcome.mp3');
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _idFocusNode.dispose();
    _toastTimer?.cancel();
    _mainPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  // --- Audio Functions ---
  String _normalizeAssetPath(String path) {
    String p = path.trim();
    while (p.startsWith('/')) p = p.substring(1);
    while (p.startsWith('assets/')) {
      p = p.substring('assets/'.length);
    }
    return p;
  }

  Future<void> _playSound(String rawPath) async {
    try {
      final path = _normalizeAssetPath(rawPath);
      await _mainPlayer.stop();
      await _mainPlayer.play(AssetSource(path));
    } catch (e) {
      print("Audio Error (playSound) for '$rawPath' -> $e");
    }
  }

  Future<void> _playClick() async {
    try {
      final path = _normalizeAssetPath('assets/sounds/click.mp3');
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(path));
    } catch (e) {
      print("SFX Error (playClick) -> $e");
    }
  }

  void _addFruit(Fruit fruit) {
    if (selectedPassword.length < 5) {
      setState(() {
        selectedPassword.add(fruit);
        _hideToast();
        showQuestionMarks = false;
      });
      _playSound(fruit.audioPath);
    }
  }

  void _removeFruitAt(int index) {
    setState(() {
      selectedPassword = selectedPassword.sublist(0, index);
      _hideToast();
      showQuestionMarks = false;
    });
    _playClick();
  }

  // --- دالة التحقق والإرسال (المعدلة) ---
  Future<void> _validateAndSubmit() async {
    _hideToast();

    // 1. التحقق من الرقم فارغ
    if (_idController.text.isEmpty) {
      setState(() => isIdError = true);
      _showToast("اكتب رقمك", "رقمك مطلوب");
      _playSound('assets/sounds/error_number.mp3');
      return;
    }

    // 2. التحقق من الرقم ناقص
    if (_idController.text.length < 4) {
      setState(() => isIdError = true);
      _showToast("كمل رقمك", "الرقم ناقص");
      _playSound('assets/sounds/error_number.mp3');
      return;
    }

    // 3. التحقق من الفواكه فارغة
    if (selectedPassword.isEmpty) {
      setState(() => showQuestionMarks = true);
      _showToast("اختر الفواكه", "لم تختر أي فاكهة");
      _playSound('assets/sounds/error_empty.mp3');
      return;
    }

    // 4. التحقق من الفواكه ناقصة
    if (selectedPassword.length < 5) {
      setState(() => showQuestionMarks = true);
      _showToast("اكمل الفواكه", "كلمة السر ناقصة");
      _playSound('assets/sounds/error_incomplete.mp3');
      return;
    }

    // --- الاتصال بالـ Backend ---
    setState(() => _isLoading = true);

    List<String> fruitCodes =
        selectedPassword.map((fruit) => fruit.code).toList();

    print('📤 Sending login with codes: $fruitCodes');

    final result = await _authService.loginChild(
      childLoginId: _idController.text.trim(),
      fruitPasswordCodes: fruitCodes,
    );

    if (mounted) setState(() => _isLoading = false);

    print('📥 Login result: $result');

    if (result.success) {
      // --- نجاح ---
      _playSound('assets/sounds/success.mp3');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            childName: result.childName ?? "يا بطل",
            profileImageUrl: result.profileImageUrl,
            age: result.age,
          ),
        );
      }
    } else {
      // --- فشل (معالجة موحدة للأخطاء) ---
      _handleLoginError(result);
    }
  }

  /// معالجة أخطاء تسجيل الدخول (المعدلة لتوحيد الصوت)
  void _handleLoginError(ChildLoginResult result) {
    // تشغيل صوت الخطأ العام دائماً لأي مشكلة من الباك اند
    _playSound('assets/sounds/error_backend.mp3');

    // إظهار رسالة الخطأ القادمة من الباك اند
    _showToast("حاول تاني", result.errorMessage ?? "بيانات خاطئة");

    // تحديث الحالة البصرية لمساعدة الطفل
    setState(() {
      // تفعيل اللون الأحمر للرقم وعلامات الاستفهام للفواكه
      // ليعرف الطفل أن هناك مشكلة ما في أحد المدخلات
      isIdError = true;
      showQuestionMarks = true;
    });
  }

  void _showToast(String actionText, String debugMsg) {
    setState(() {
      showError = true;
      errorAction = actionText;
      errorMessage = debugMsg;
    });
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _hideToast();
    });
  }

  void _hideToast() {
    if (showError) {
      setState(() => showError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _hideToast();
            _playClick();
          },
          child: Stack(
            children: [
              // 1. الخلفية
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kBgColorTop, kBgColorBottom],
                  ),
                ),
              ),

              // 2. المحتوى الرئيسي
              Positioned.fill(
                bottom: 250,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // الهيدر
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              right: -25,
                              child: Image.asset(
                                'images/coins right.png',
                                width: 90,
                              ),
                            ),
                            Positioned(
                              left: -20,
                              child: Image.asset(
                                'images/coins left.png',
                                width: 75,
                              ),
                            ),
                            const Text(
                              "مرحباً يا أبطال! ",
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // إدخال الرقم
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "رقمى هو",
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: isIdError
                                        ? kErrorColor
                                        : isIdCompleted
                                            ? kSuccessBorderColor
                                            : isIdFocused
                                                ? Colors.black
                                                : kDefaultShadowColor,
                                    blurRadius: 0,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: TextField(
                                controller: _idController,
                                focusNode: _idFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  // ✅ التعديل الأول: تقييد الإدخال بـ 4 أرقام فقط
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText: "اكتب رقمك هنا ...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    letterSpacing: 0,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: isIdError
                                          ? kErrorColor
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: isIdError
                                          ? kErrorColor
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // منطقة كلمة السر
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "كلمة السر",
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // خانات الفواكه المختارة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(5, (index) {
                                bool hasFruit = index < selectedPassword.length;
                                Fruit? fruit =
                                    hasFruit ? selectedPassword[index] : null;

                                return GestureDetector(
                                  onTap: () {
                                    if (hasFruit) _removeFruitAt(index);
                                  },
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child,
                                        Animation<double> animation) {
                                      return ScaleTransition(
                                          scale: animation, child: child);
                                    },
                                    child: hasFruit
                                        ? Container(
                                            key: ValueKey(
                                              fruit!.id + index.toString(),
                                            ),
                                            width: (size.width - 48 - 40) / 5,
                                            height: (size.width - 48 - 40) / 5,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Image.asset(
                                                fruit.imagePath,
                                              ),
                                            ),
                                          )
                                        : showQuestionMarks
                                            ? Container(
                                                key: const ValueKey('error'),
                                                width:
                                                    (size.width - 48 - 40) / 5,
                                                height:
                                                    (size.width - 48 - 40) / 5,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: kErrorColor,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: const Text(
                                                  "؟",
                                                  style: TextStyle(
                                                    color: kErrorColor,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: kFontFamily,
                                                  ),
                                                ),
                                              )
                                            : CustomPaint(
                                                key: ValueKey('empty$index'),
                                                painter: DashedBorderPainter(
                                                  color: Colors.grey.shade400,
                                                  strokeWidth: 1.5,
                                                  gap: 4,
                                                ),
                                                child: Container(
                                                  width:
                                                      (size.width - 48 - 40) /
                                                          5,
                                                  height:
                                                      (size.width - 48 - 40) /
                                                          5,
                                                ),
                                              ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // شبكة الفواكه
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: availableFruits.length,
                          itemBuilder: (context, index) {
                            final fruit = availableFruits[index];
                            return GameButton(
                              text: null,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(fruit.imagePath),
                              ),
                              onTap: () => _addFruit(fruit),
                              height: 65,
                              width: 65,
                              color: fruit.backgroundColor,
                              shadowColor:
                                  fruit.backgroundColor.withOpacity(0.6),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. الجزء السفلي الثابت
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.asset(
                      'images/png-clipart-free-content-graphy-website-grass-s-presentation-computer-wallpaper-removebg-preview 1.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      height: 120,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 140.0,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // أنيميشن التوست
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            reverseDuration: const Duration(milliseconds: 200),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                              );
                              return SlideTransition(
                                position: offsetAnimation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: showError
                                ? GestureDetector(
                                    key: const ValueKey('toast'),
                                    onTap: _hideToast,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 25,
                                        vertical: 15,
                                      ),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: kErrorColor,
                                              offset: Offset(0, 4),
                                              blurRadius: 0,
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Colors.grey.shade200)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.cancel_outlined,
                                            color: kErrorColor,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            errorAction,
                                            style: const TextStyle(
                                              fontFamily: kFontFamily,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),

                          // زر انطلق
                          _isLoading
                              ? const SizedBox(
                                  height: 55,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: kButtonMainColor,
                                    ),
                                  ),
                                )
                              : GameButton(
                                  text: "انطلق",
                                  onTap: _validateAndSubmit,
                                ),

                          const SizedBox(height: 25),

                          // زر رجوع
                          GestureDetector(
                            onTap: () {
                              _playClick();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RoleSelectionScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_forward,
                                  size: 28,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "رجوع",
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
  }
}
