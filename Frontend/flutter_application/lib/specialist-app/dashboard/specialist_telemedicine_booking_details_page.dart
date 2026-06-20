import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/models/doctor_consultation_models.dart';
import 'package:Ajial/specialist-app/dashboard/services/doctor_consultation_api_service.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_symptoms_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_prescription_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_diagnosis_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_chat_page.dart';

class SpecialistTelemedicineBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final String dateText;

  const SpecialistTelemedicineBookingDetailsPage({
    super.key,
    required this.bookingId,
    required this.dateText,
  });

  @override
  State<SpecialistTelemedicineBookingDetailsPage> createState() =>
      _SpecialistTelemedicineBookingDetailsPageState();
}

class _SpecialistTelemedicineBookingDetailsPageState
    extends State<SpecialistTelemedicineBookingDetailsPage> {
  final DoctorConsultationApiService _api = DoctorConsultationApiService();

  Timer? _tickTimer; // 1s — drives the countdown label
  Timer? _pollTimer; // 5s — re-syncs session flags with the server

  bool _loading = true;
  String? _error;
  DoctorBookingDetail? _detail;
  DoctorSessionStatus? _session;

  // Local countdown bookkeeping, synced from the server clock.
  int _secondsUntilStart = 0;
  DateTime _lastSyncAt = DateTime.now();

  bool _startingSession = false;
  bool _endingSession = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // ==================== Data loading ==========================
  // ============================================================

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.getBookingDetail(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      _applySession(detail.session);
      _startTimers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _loading = false;
      });
    }
  }

  void _applySession(DoctorSessionStatus? session) {
    if (session == null) return;
    setState(() {
      _session = session;
      _secondsUntilStart = session.secondsUntilStart;
      _lastSyncAt = DateTime.now();
    });
  }

  void _startTimers() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();

    // Stop all polling once the session is completed.
    if (_session?.isCompleted ?? false) return;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // re-render the countdown
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollSession());
  }

  Future<void> _pollSession() async {
    try {
      final session = await _api.getSessionStatus(widget.bookingId);
      if (!mounted) return;
      _applySession(session);
      if (session.isCompleted) {
        _tickTimer?.cancel();
        _pollTimer?.cancel();
      }
    } catch (_) {
      // Transient poll failures are ignored; next tick retries.
    }
  }

  /// Seconds left until the session window opens, derived from the last
  /// server sync plus locally-elapsed time.
  int get _remainingSeconds {
    final elapsed = DateTime.now().difference(_lastSyncAt).inSeconds;
    final remaining = _secondsUntilStart - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('SocketException') ||
        text.contains('connection') ||
        text.contains('Connection') ||
        text.contains('DioException')) {
      return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
    }
    return text.isEmpty ? 'تعذر الاتصال بالخادم، حاول مرة أخرى' : text;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: specialistFont),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  // ============================================================
  // ==================== Session actions =======================
  // ============================================================

  Future<void> _startSession() async {
    if (_startingSession) return;
    setState(() => _startingSession = true);
    try {
      final result = await _api.startSession(widget.bookingId);
      await _openMeeting(result.joinUrl);
      await _pollSession();
    } catch (e) {
      _showSnack(_cleanError(e));
    } finally {
      if (mounted) setState(() => _startingSession = false);
    }
  }

  Future<void> _endSession() async {
    if (_endingSession) return;
    final confirmed = await _confirmEndSession();
    if (confirmed != true) return;
    setState(() => _endingSession = true);
    try {
      final session = await _api.endSession(widget.bookingId);
      if (!mounted) return;
      _applySession(session);
      _tickTimer?.cancel();
      _pollTimer?.cancel();
      // Refresh the booking detail so the badge/buttons reflect completion.
      _loadDetail();
    } catch (e) {
      _showSnack(_cleanError(e));
    } finally {
      if (mounted) setState(() => _endingSession = false);
    }
  }

  Future<bool?> _confirmEndSession() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'إنهاء الجلسة',
            style: TextStyle(
              fontFamily: specialistFont,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'هل أنت متأكد من إنهاء الجلسة؟ لا يمكن التراجع بعد الإنهاء.',
            style: TextStyle(fontFamily: specialistFont),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: specialistFont,
                  color: Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'إنهاء',
                style: TextStyle(
                  fontFamily: specialistFont,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMeeting(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('رابط الجلسة غير صالح');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _showSnack('تعذر فتح رابط الجلسة');
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return 'حان موعد الجلسة';
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (days > 0) {
      return 'متبقي $days يوم : $hours س : $minutes ق : $seconds ث';
    } else if (hours > 0) {
      return 'متبقي $hours س : $minutes ق : $seconds ث';
    } else {
      return 'متبقي $minutes ق : $seconds ث';
    }
  }

  // ============================================================
  // ==================== UI ====================================
  // ============================================================

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F7F0),
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
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: specialistGreen),
      );
    }

    if (_error != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Colors.black.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                _error ?? 'تعذر تحميل تفاصيل الحجز',
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadDetail,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    color: specialistGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final isCompleted = (_session?.isCompleted ?? detail.isCompleted);

    return Column(
      children: [
        const SizedBox(height: 8),
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
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Container(width: 8, color: specialistGreen),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        '${detail.rangeText} . ${detail.durationMinutes} دقيقة',
                                        style: TextStyle(
                                          fontFamily: specialistFont,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFFE8F7F0)
                                        : const Color(0xFFE5F3FE),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    _session?.statusAr ?? detail.statusAr,
                                    style: TextStyle(
                                      fontFamily: specialistFont,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted
                                          ? specialistGreen
                                          : const Color(0xFF0085FF),
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
                            builder: (context) =>
                                SpecialistTelemedicineSymptomsPage(
                              detail: detail,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildGridButton(
                      title: 'تحدث مع المريض',
                      iconPath: 'images/chat.png',
                      isEnabled: isCompleted,
                      onTap: isCompleted
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SpecialistTelemedicineChatPage(
                                    bookingId: detail.bookingId,
                                    patientName: detail.patientName,
                                    patientImage: 'images/pic.png',
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildGridButton(
                      title: 'الروشتة الطبية',
                      iconPath: 'images/notes.png',
                      isEnabled: isCompleted,
                      onTap: isCompleted
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SpecialistTelemedicinePrescriptionPage(
                                    bookingId: widget.bookingId,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(width: 16),
                    _buildGridButton(
                      title: 'التشخيص الطبي',
                      iconPath: 'images/consultation.png',
                      isEnabled: isCompleted,
                      onTap: isCompleted
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SpecialistTelemedicineDiagnosisPage(
                                    bookingId: widget.bookingId,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Bottom action button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBottomButton(isCompleted),
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isCompleted) {
    // 1) Completed — disabled light-green pill.
    if (isCompleted) {
      return _bottomPill(
        label: 'جلسة مكتملة',
        background: const Color(0xFF81D4A3),
        textColor: Colors.white,
        onTap: null,
      );
    }

    final session = _session;
    final canEnd = session?.canEnd ?? false;
    final canStart = session?.canStart ?? false;

    // 2) Session in progress — red "End session".
    if (canEnd) {
      return _bottomPill(
        label: _endingSession ? '' : 'إنهاء الجلسة',
        background: const Color(0xFFE53935),
        textColor: Colors.white,
        loading: _endingSession,
        onTap: _endingSession ? null : _endSession,
      );
    }

    // 3) Within the start window — green "Start now".
    if (canStart) {
      return _bottomPill(
        label: _startingSession ? '' : 'بدء الجلسة الان',
        background: specialistGreen,
        textColor: Colors.white,
        loading: _startingSession,
        onTap: _startingSession ? null : _startSession,
      );
    }

    // 4) Before the window opens — grey countdown.
    return _bottomPill(
      label: _formatDuration(_remainingSeconds),
      background: Colors.grey.shade300,
      textColor: Colors.grey.shade700,
      onTap: null,
    );
  }

  Widget _bottomPill({
    required String label,
    required Color background,
    required Color textColor,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
