// --- lib/child-app/recordings/child_record_page.dart ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/recordings/recordings_provider.dart';

// --- Constants ---
const String kFontFamily = 'IBM Plex Sans Arabic';
const Color kBgColorTop = Color(0x80B0CEE3);
const Color kBgColorBottom = Color(0x00B0CEE3);
const Color kOrangeCardStart = Color(0xFFFEA400);
const Color kOrangeCardEnd = Color(0xFFFD5E00);
const Color kStarPillBorder = Color(0xFFC84A00);
const Color kBlueButton = Color(0xFF008CFF);
const Color kBlueBorder = Color(0xFF00579E);
const Color kRedButton = Color(0xFFFF0000);
const Color kRedBorder = Color(0xFF870000);

class ChildRecordPage extends StatefulWidget {
  final String childName;
  final int currentStars;

  const ChildRecordPage({
    super.key,
    required this.childName,
    required this.currentStars,
  });

  @override
  State<ChildRecordPage> createState() => _ChildRecordPageState();
}

class _ChildRecordPageState extends State<ChildRecordPage>
    with TickerProviderStateMixin {
  RecordingsProvider? _provider;
  Timer? _timer;
  int _seconds = 0;
  bool _isRecording = false;
  
  // Animation controllers for wave effect
  late AnimationController _waveController1;
  late AnimationController _waveController2;

  @override
  void initState() {
    super.initState();
    
    // Wave animation controllers (start paused, will start when recording starts)
    _waveController1 = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Don't auto-start - wait for user to tap start button
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get provider from context (passed via ChangeNotifierProvider.value)
    _provider ??= context.read<RecordingsProvider>();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController1.dispose();
    _waveController2.dispose();
    // Don't dispose provider - it's shared and managed by parent
    super.dispose();
  }

  void _startRecording() async {
    if (_provider == null) return;
    final success = await _provider!.startRecording();
    if (success) {
      // Start wave animations
      _waveController1.repeat();
      _waveController2.repeat();
      
      setState(() {
        _isRecording = true;
        _seconds = 0;
      });
      
      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
        _provider!.updateRecordingTime(_seconds);
      });
    }
  }

  void _stopRecording() async {
    _timer?.cancel();
    
    // Stop wave animations
    _waveController1.stop();
    _waveController2.stop();
    
    if (_provider == null) return;
    await _provider!.stopRecording();
    setState(() {
      _isRecording = false;
    });
    
    if (mounted) {
      // Navigate back to recordings list
      Navigator.pop(context);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString()}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // --- Background ---
            _buildBackground(),

            // --- Main Content ---
            Column(
              children: [
                // --- Scrollable Content ---
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.02),

                          // --- Header ---
                          _buildHeader(context),

                          const Spacer(),

                          // --- Microphone with Waves ---
                          _buildMicrophoneWithWaves(),

                          SizedBox(height: size.height * 0.03),

                          // --- Timer Display ---
                          _buildTimerDisplay(),

                          const Spacer(),

                          // --- Action Button (Start/Stop) ---
                          _buildActionButton(),

                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Grass Decoration ---
                _buildGrassDecoration(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Background ---
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgColorTop, kBgColorBottom],
        ),
        color: Colors.white,
      ),
    );
  }

  // --- Header with Back Button and Star Counter ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button (Left in RTL = Right visually)
        _buildBackButton(context),

        // Star Counter (Right in RTL = Left visually)
        _buildStarCounter(widget.currentStars),
      ],
    );
  }

  // --- Star Counter Pill ---
  Widget _buildStarCounter(int stars) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78, minHeight: 45),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kOrangeCardStart, kOrangeCardEnd],
        ),
        border: Border.all(color: kStarPillBorder, width: 1),
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: kStarPillBorder,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star image
          Image.asset(
            'images/stars.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.star, color: Colors.white, size: 24);
            },
          ),
          const SizedBox(width: 6),
          // Number (on right of star)
          Text(
            '$stars',
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- Back Button ---
  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Stop recording before going back
        if (_isRecording && _provider != null) {
          await _provider!.stopRecording();
          _timer?.cancel();
        }
        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back, // Arrow pointing left (back)
            size: 30,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // --- Microphone with Animated Waves ---
  Widget _buildMicrophoneWithWaves() {
    return SizedBox(
      width: 194,
      height: 194,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer wave circle (animated)
          if (_isRecording)
            AnimatedBuilder(
              animation: _waveController1,
              builder: (context, child) {
                return Container(
                  width: 194,
                  height: 194,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kRedButton.withAlpha((255 * (1 - _waveController1.value)).toInt()),
                      width: 4,
                    ),
                  ),
                );
              },
            ),
          
          // Inner wave circle (animated)
          if (_isRecording)
            AnimatedBuilder(
              animation: _waveController2,
              builder: (context, child) {
                return Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kRedButton.withAlpha((50 * (1 - _waveController2.value)).toInt()),
                      width: 4,
                    ),
                  ),
                );
              },
            ),
          
          // Static outer ring (when recording)
          if (_isRecording)
            Container(
              width: 194,
              height: 194,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kRedButton, width: 4),
              ),
            ),
          
          // Static inner ring (semi-transparent)
          if (_isRecording)
            Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: kRedButton.withAlpha(50),
                  width: 4,
                ),
              ),
            ),
          
          // Microphone image
          Image.asset(
            'images/microphone.png',
            width: 118,
            height: 118,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  size: 60,
                  color: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Timer Display ---
  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(61),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2.4, 2.4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator dot
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: kRedButton,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // Time
          Text(
            _formatTime(_seconds),
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- Action Button (Start or Stop) ---
  Widget _buildActionButton() {
    if (_isRecording) {
      // Stop button (Red)
      return GestureDetector(
        onTap: _stopRecording,
        child: Container(
          width: 343,
          height: 55,
          decoration: BoxDecoration(
            color: kRedButton,
            border: Border.all(color: kRedBorder, width: 1),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: kRedBorder,
                offset: Offset(3, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause,
                size: 24,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'توقف',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Start button (Blue)
      return GestureDetector(
        onTap: _startRecording,
        child: Container(
          width: 343,
          height: 55,
          decoration: BoxDecoration(
            color: kBlueButton,
            border: Border.all(color: kBlueBorder, width: 1),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: kBlueBorder,
                offset: Offset(3, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                size: 24,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'ابدأ',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // --- Grass Decoration ---
  Widget _buildGrassDecoration() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Image.asset(
        'images/png-clipart-free-content-graphy-website-grass-s-presentation-computer-wallpaper-removebg-preview 1.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            color: Colors.green.shade400,
          );
        },
      ),
    );
  }
}
