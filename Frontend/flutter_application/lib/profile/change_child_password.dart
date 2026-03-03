// --- lib/profile/change_child_password.dart ---
// Change Child Password Screen – 3-step fruit password flow

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';
import 'package:Ajial/providers/add_child_flow_provider.dart';

const Color _kPrimaryRed = Color(0xFFBF092F);
const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

const List<Color> _fruitBgColors = [
  Color(0xFFFFF4B6),
  Color(0xFFEAE5F3),
  Color(0xFFFFDBB9),
  Color(0xFFFFF4CF),
  Color(0xFFDFF5C8),
  Color(0xFFFEDADA),
  Color(0xFFE8DDEF),
  Color(0xFFF6D2D8),
  Color(0xFFFFF4CF),
  Color(0xFFDBF2D1),
];

class ChangeChildPasswordPage extends StatefulWidget {
  const ChangeChildPasswordPage({super.key});

  @override
  State<ChangeChildPasswordPage> createState() =>
      _ChangeChildPasswordPageState();
}

class _ChangeChildPasswordPageState extends State<ChangeChildPasswordPage> {
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

  // 0 = old, 1 = new, 2 = confirm
  int _activeField = 0;
  final List<List<int>> _passwords = [[], [], []];

  void _onFruitTap(int fruitIndex) {
    setState(() {
      if (_passwords[_activeField].length < 5) {
        _passwords[_activeField].add(fruitIndex);
      }
    });
  }

  void _onSlotTap(int fieldIndex, int slotIndex) {
    if (slotIndex < _passwords[fieldIndex].length) {
      setState(() {
        _passwords[fieldIndex].removeAt(slotIndex);
        _activeField = fieldIndex;
      });
    } else {
      setState(() => _activeField = fieldIndex);
    }
  }

  bool _isLoading = false;

  void _onSave() async {
    if (_isLoading) return;

    final provider = context.read<ChildDataProvider>();

    // Validate old password length
    final oldCodes = _passwords[0].map((i) => _fruits[i].code).toList();
    if (oldCodes.length != 5) {
      _showError('يرجى إدخال كلمة المرور القديمة كاملة');
      return;
    }

    // Validate new password
    if (_passwords[1].length != 5) {
      _showError('يرجى إدخال كلمة المرور الجديدة كاملة');
      return;
    }

    // Validate confirmation matches new
    if (_passwords[2].length != 5) {
      _showError('يرجى تاكيد كلمة المرور الجديدة');
      return;
    }

    final newCodes = _passwords[1].map((i) => _fruits[i].code).toList();
    final confirmCodes = _passwords[2].map((i) => _fruits[i].code).toList();

    bool confirmMatch = true;
    for (int i = 0; i < 5; i++) {
      if (newCodes[i] != confirmCodes[i]) {
        confirmMatch = false;
        break;
      }
    }
    if (!confirmMatch) {
      _showError('كلمة المرور الجديدة وتاكيدها غير متطابقتين');
      return;
    }

    final newImages = _passwords[1].map((i) => _fruits[i].imagePath).toList();

    setState(() {
      _isLoading = true;
    });

    final result = await provider.updateAccountPassword(
        oldCodes, newCodes, confirmCodes, newImages);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.$1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.$2, style: const TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: _kGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      _showError(result.$2);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: _kFontFamily)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildDataProvider>();
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Key icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.vpn_key, size: 50, color: _kGreen),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        ChildDataStrings.changePasswordTitle(
                            provider.childName),
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Old password
                      _buildPasswordField(
                        label: ChildDataStrings.oldPasswordLabel,
                        fieldIndex: 0,
                      ),
                      const SizedBox(height: 24),

                      // New password
                      _buildPasswordField(
                        label: ChildDataStrings.newPasswordLabel,
                        fieldIndex: 1,
                      ),
                      const SizedBox(height: 24),

                      // Confirm password
                      _buildPasswordField(
                        label: ChildDataStrings.confirmPasswordLabel,
                        fieldIndex: 2,
                      ),
                      const SizedBox(height: 24),

                      // Fruit grid
                      _buildFruitGrid(),
                      const SizedBox(height: 34),

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

  Widget _buildPasswordField({
    required String label,
    required int fieldIndex,
  }) {
    final isActive = _activeField == fieldIndex;
    return GestureDetector(
      onTap: () => setState(() => _activeField = fieldIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? _kPrimaryRed : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _passwords[fieldIndex].length;
              final fruitIdx = filled ? _passwords[fieldIndex][i] : -1;

              Color borderColor;
              if (filled) {
                borderColor = _kGreen;
              } else if (isActive) {
                borderColor = _kPrimaryRed;
              } else {
                borderColor = Colors.black;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onSlotTap(fieldIndex, i),
                  child: Container(
                    height: 60,
                    margin: EdgeInsets.only(left: i < 4 ? 10 : 0),
                    decoration: BoxDecoration(
                      color: filled ? _fruitBgColors[fruitIdx] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: filled
                        ? Center(
                            child: Image.asset(
                              _fruits[fruitIdx].imagePath,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_fruits.length, (i) {
          return GestureDetector(
            onTap: () => _onFruitTap(i),
            child: Container(
              width: 60,
              height: 60,
              margin: EdgeInsets.only(left: i < _fruits.length - 1 ? 16 : 0),
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
          );
        }),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: _onSave,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: _kPrimaryRed,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      ChildDataStrings.changePasswordButton,
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
