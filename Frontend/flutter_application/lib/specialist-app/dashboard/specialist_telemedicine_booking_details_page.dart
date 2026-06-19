import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_symptoms_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_prescription_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_diagnosis_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_chat_page.dart';

class SpecialistTelemedicineBookingDetailsPage extends StatefulWidget {
  final String dateText;
  final String timeText;
  final DateTime sessionStartTime;
  final bool hasSymptomsData;
  final bool isAlreadyCompleted;

  const SpecialistTelemedicineBookingDetailsPage({
    super.key,
    required this.dateText,
    required this.timeText,
    required this.sessionStartTime,
    required this.hasSymptomsData,
    required this.isAlreadyCompleted,
  });

  @override
  State<SpecialistTelemedicineBookingDetailsPage> createState() =>
      _SpecialistTelemedicineBookingDetailsPageState();
}

class _SpecialistTelemedicineBookingDetailsPageState
    extends State<SpecialistTelemedicineBookingDetailsPage> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isCompleted = false;
  List<Medicine> _prescriptionMedicines = [];
  String? _diagnosis;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isAlreadyCompleted;
    if (!_isCompleted) {
      _updateRemainingTime();
      _startTimer();
    }
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (widget.sessionStartTime.isAfter(now)) {
      _remainingTime = widget.sessionStartTime.difference(now);
    } else {
      _remainingTime = Duration.zero;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _updateRemainingTime();
        if (_remainingTime.inSeconds <= 0) {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      return 'حان موعد الجلسة';
    }
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;
    
    if (days > 0) {
      return 'متبقي $days يوم : $hours س : $minutes ق : $seconds ث';
    } else if (hours > 0) {
      return 'متبقي $hours س : $minutes ق : $seconds ث';
    } else {
      return 'متبقي $minutes ق : $seconds ث';
    }
  }

  Widget _buildGridButton({
    required String title,
    required String iconPath,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFFF0FAF5)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    iconPath,
                    width: 32,
                    height: 32,
                    color: isEnabled ? specialistGreen : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? Colors.black : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F7F0), // Light green
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'images/back arrow.png',
                          width: 24,
                          height: 24,
                          color: specialistGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'جلسة ${widget.dateText}',
                        style: const TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Info Card
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                color: specialistGreen,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.dateText,
                                            style: const TextStyle(
                                              fontFamily: specialistFont,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${widget.timeText} . 45 دقيقة',
                                            style: TextStyle(
                                              fontFamily: specialistFont,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _isCompleted ? const Color(0xFFE8F7F0) : const Color(0xFFE5F3FE),
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Text(
                                          _isCompleted ? 'جلسة مكتملة' : 'جاري المعالجة',
                                          style: TextStyle(
                                            fontFamily: specialistFont,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _isCompleted ? specialistGreen : const Color(0xFF0085FF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Grid Buttons
                      Row(
                        children: [
                          _buildGridButton(
                            title: 'الاعراض والشكوي',
                            iconPath: 'images/synirge green.png',
                            isEnabled: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SpecialistTelemedicineSymptomsPage(hasData: widget.hasSymptomsData),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildGridButton(
                            title: 'تحدث مع المريض',
                            iconPath: 'images/chat.png',
                            isEnabled: _isCompleted,
                            onTap: _isCompleted ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SpecialistTelemedicineChatPage(
                                    patientName: 'خالد ابراهيم',
                                    patientImage: 'images/pic.png',
                                  ),
                                ),
                              );
                            } : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildGridButton(
                            title: 'الروشتة الطبية',
                            iconPath: 'images/notes.png',
                            isEnabled: _isCompleted,
                            onTap: _isCompleted ? () async {
                              final updatedMedicines = await Navigator.push<List<Medicine>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SpecialistTelemedicinePrescriptionPage(
                                    initialMedicines: _prescriptionMedicines,
                                  ),
                                ),
                              );
                              if (updatedMedicines != null) {
                                setState(() {
                                  _prescriptionMedicines = updatedMedicines;
                                });
                              }
                            } : null,
                          ),
                          const SizedBox(width: 16),
                          _buildGridButton(
                            title: 'التشخيص الطبي',
                            iconPath: 'images/consultation.png',
                            isEnabled: _isCompleted,
                            onTap: _isCompleted ? () async {
                              final updatedDiagnosis = await Navigator.push<String?>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SpecialistTelemedicineDiagnosisPage(
                                    initialDiagnosis: _diagnosis,
                                  ),
                                ),
                              );
                              // Using updatedDiagnosis != null is tricky since null might mean it was deleted.
                              // So we just update the state regardless.
                              setState(() {
                                _diagnosis = updatedDiagnosis;
                              });
                            } : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Countdown Banner
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () {
                    if (!_isCompleted && _remainingTime.inSeconds <= 0) {
                      setState(() {
                        _isCompleted = true;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isCompleted 
                          ? const Color(0xFF81D4A3) // Light green for disabled completed state
                          : (_remainingTime.inSeconds <= 0 
                              ? specialistGreen // Active start button
                              : Colors.grey.shade300), // Countdown state
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _isCompleted 
                          ? 'جلسة مكتملة'
                          : (_remainingTime.inSeconds <= 0 
                              ? 'بدء الجلسة الان'
                              : _formatDuration(_remainingTime)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isCompleted 
                            ? Colors.white
                            : (_remainingTime.inSeconds <= 0 
                                ? Colors.white
                                : Colors.grey.shade700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
