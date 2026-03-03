// --- lib/profile/making_child_account.dart ---
// Create Child Account Screen – RTL, Fruit Password

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';
import 'package:Ajial/providers/child_profile_provider.dart';
import 'package:Ajial/providers/add_child_flow_provider.dart';
import 'package:flutter/services.dart';
import 'package:Ajial/api/auth_service.dart';

const Color _kPrimaryRed = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Background colours for each fruit card (same order as fruitsList).
const List<Color> _fruitBgColors = [
  Color(0xFFFFF4B6), // lemon
  Color(0xFFEAE5F3), // grapes
  Color(0xFFFFDBB9), // orange
  Color(0xFFFFF4CF), // banana
  Color(0xFFDFF5C8), // pear
  Color(0xFFFEDADA), // apple
  Color(0xFFE8DDEF), // fig
  Color(0xFFF6D2D8), // strawberry
  Color(0xFFFFF4CF), // pineapple
  Color(0xFFDBF2D1), // watermelon
];

class MakingChildAccountPage extends StatefulWidget {
  final String childId;
  const MakingChildAccountPage({super.key, required this.childId});

  @override
  State<MakingChildAccountPage> createState() => _MakingChildAccountPageState();
}

class _MakingChildAccountPageState extends State<MakingChildAccountPage> {
  final TextEditingController _codeCtrl = TextEditingController();
  final List<int> _selectedFruitIndices = []; // max 5

  // Reuse fruit list from AddChildFlowProvider
  final List<FruitItem> _fruits = [
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

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onFruitTap(int index) {
    setState(() {
      if (_selectedFruitIndices.length < 5) {
        _selectedFruitIndices.add(index);
      }
    });
  }

  void _onSlotTap(int slotIndex) {
    if (slotIndex < _selectedFruitIndices.length) {
      setState(() {
        _selectedFruitIndices.removeAt(slotIndex);
      });
    }
  }

  bool _isLoading = false;

  void _onSave() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يتكون كود الطفل من 4 أرقام',
              style: TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedFruitIndices.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار 5 فواكه لكلمة السر',
              style: TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fruitCodes =
        _selectedFruitIndices.map((i) => _fruits[i].code).toList();

    final provider = context.read<ChildDataProvider>();

    setState(() {
      _isLoading = true;
    });

    // Getting the exact values from provider to recreate the child
    String fullName = provider.fullName;
    if (fullName.isEmpty) {
      fullName = provider.name;
    }
    if (fullName.isEmpty) {
      fullName = provider.childName;
    }

    // Ensure the name has at least two words as the backend might require "Full Name"
    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    if (nameParts.length < 2) {
      fullName =
          '$fullName العائلة'; // Fallback if the user only provided one name
    }

    final result = await AuthService().createChildAccount(
      childId: widget.childId,
      childLoginId: code,
      fruitPasswordCodes: fruitCodes,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.$1) {
      // Sync to Provider so UI updates immediately
      provider.createAccount(
        code,
        fruitCodes,
        _selectedFruitIndices.map((i) => _fruits[i].imagePath).toList(),
      );
      context.read<ChildProfileProvider>().setAccountCreated(true);
      context
          .read<ChildProfileProvider>()
          .fetchProfileSummary(provider.childId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.$2, style: const TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: const Color(0xFF01A449),
        ),
      );

      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.$2, style: const TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: Colors.red,
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
              // Close button (Visual Right / RTL Left)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.close, size: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        ChildDataStrings.makingAccountTitle,
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        ChildDataStrings.makingAccountSubtitle,
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.black.withOpacity(0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 34),

                      // Child Code field
                      _buildChildCodeField(),
                      const SizedBox(height: 34),

                      // Fruit password section
                      _buildFruitPasswordSection(),
                      const SizedBox(height: 74),

                      // Buttons
                      _buildButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          ChildDataStrings.childCodeFieldLabel,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.black.withOpacity(0.25)),
          ),
          child: TextField(
            controller: _codeCtrl,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: ChildDataStrings.childCodeHint,
              counterText: '',
              hintStyle: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFruitPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Label
        Text(
          ChildDataStrings.fruitPasswordLabel,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),

        // 5 selection slots
        _buildSelectionSlots(),
        const SizedBox(height: 24),

        // Fruit grid (2 rows × 5 cols)
        _buildFruitGrid(),
      ],
    );
  }

  Widget _buildSelectionSlots() {
    return Row(
      children: List.generate(5, (i) {
        final bool filled = i < _selectedFruitIndices.length;
        return Expanded(
          child: GestureDetector(
            onTap: () => _onSlotTap(i),
            child: Container(
              height: 60,
              margin: EdgeInsets.only(left: i < 4 ? 10 : 0),
              decoration: BoxDecoration(
                color: filled
                    ? _fruitBgColors[_selectedFruitIndices[i]]
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withOpacity(0.25),
                  style: filled ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              child: filled
                  ? Center(
                      child: Image.asset(
                        _fruits[_selectedFruitIndices[i]].imagePath,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    )
                  : CustomPaint(
                      painter: _DashedBorderPainter(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: 10,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFruitGrid() {
    return Column(
      children: [
        // Row 1: indices 0-4
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: GestureDetector(
                onTap: () => _onFruitTap(i),
                child: Container(
                  height: 60,
                  margin: EdgeInsets.only(left: i < 4 ? 11 : 0),
                  decoration: BoxDecoration(
                    color: _fruitBgColors[i],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Center(
                    child: Image.asset(
                      _fruits[i].imagePath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Row 2: indices 5-9
        Row(
          children: List.generate(5, (i) {
            final idx = i + 5;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onFruitTap(idx),
                child: Container(
                  height: 60,
                  margin: EdgeInsets.only(left: i < 4 ? 11 : 0),
                  decoration: BoxDecoration(
                    color: _fruitBgColors[idx],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Center(
                    child: Image.asset(
                      _fruits[idx].imagePath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Primary: Create Account
        GestureDetector(
          onTap: _isLoading ? null : _onSave,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey : _kPrimaryRed,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'انشاء حساب',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary: Skip
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.black.withOpacity(0.5)),
            ),
            child: const Center(
              child: Text(
                'تخطى',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed border on empty slots
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, this.borderRadius = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashedPath = Path();
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = dashWidth.clamp(0, metric.length - distance);
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
