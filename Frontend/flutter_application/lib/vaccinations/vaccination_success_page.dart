// --- lib/vaccinations/vaccination_success_page.dart ---

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

// ─────────────────────── Design Tokens ───────────────────────────────────────
const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// VaccinationSuccessPage
///
/// Full-screen success page shown after the parent confirms their
/// vaccination selections. Displays a large check icon, a title message,
/// animated confetti, and a single "استمرار" button that returns to profile.
///
/// Route: '/vaccination-success'
class VaccinationSuccessPage extends StatefulWidget {
  const VaccinationSuccessPage({super.key});

  @override
  State<VaccinationSuccessPage> createState() => _VaccinationSuccessPageState();
}

class _VaccinationSuccessPageState extends State<VaccinationSuccessPage> {
  late ConfettiController _confettiControllerTopRight;
  late ConfettiController _confettiControllerBottomLeft;

  @override
  void initState() {
    super.initState();
    _confettiControllerTopRight = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    _confettiControllerBottomLeft = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    _playConfettiTwice();
  }

  void _playConfettiTwice() async {
    _confettiControllerTopRight.play();
    _confettiControllerBottomLeft.play();
    await Future.delayed(const Duration(milliseconds: 700));
    _confettiControllerTopRight.play();
    _confettiControllerBottomLeft.play();
  }

  @override
  void dispose() {
    _confettiControllerTopRight.dispose();
    _confettiControllerBottomLeft.dispose();
    super.dispose();
  }

  Path _drawConfettiPath(Size size) {
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, 0);
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Confetti animation (top-right) ────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiControllerTopRight,
                blastDirection: pi * 0.75,
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.orange,
                  Colors.purple,
                  _kPrimaryColor,
                ],
                createParticlePath: _drawConfettiPath,
              ),
            ),
            // ── Confetti animation (bottom-left) ──────────────────────────
            Align(
              alignment: Alignment.bottomLeft,
              child: ConfettiWidget(
                confettiController: _confettiControllerBottomLeft,
                blastDirection: -pi * 0.25,
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Color(0xFF01A449),
                ],
                createParticlePath: _drawConfettiPath,
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Header: title + subtitle ─────────────────────────────
                  SizedBox(
                    width: 264,
                    child: Column(
                      children: const [
                        Text(
                          'تم تاكيد التطعيمات بنجاح!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            height: 33 / 22,
                            color: Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'يمكنكم استمرار رحلتكم',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            height: 24 / 16,
                            color: Color(0xBF000000),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Check circle icon centered ───────────────────────────
                  const Expanded(
                    child: Center(
                      child: _CheckCircle(),
                    ),
                  ),

                  // ── "استمرار" button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                            (route) => route.settings.name == '/profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'استمرار',
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Check Circle ─────────────────────────────────────────

class _CheckCircle extends StatelessWidget {
  const _CheckCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      height: 176,
      decoration: const BoxDecoration(
        color: _kPrimaryColor,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 100,
        ),
      ),
    );
  }
}
