import 'package:flutter/material.dart';
import '../api/specialist-services.dart';
import 'registeration-pages/specialist-login.dart';

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Temporary Specialist Home Page
/// Shows logo + specialist name + red logout button
class SpecialistHomePage extends StatefulWidget {
  const SpecialistHomePage({super.key});

  @override
  State<SpecialistHomePage> createState() => _SpecialistHomePageState();
}

class _SpecialistHomePageState extends State<SpecialistHomePage> {
  final SpecialistService _service = SpecialistService();
  String _specialistName = '';
  String _specialistStatus = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await _service.getSpecialistName();
    final status = await _service.getSpecialistStatus();
    setState(() {
      _specialistName = name ?? 'متخصص';
      _specialistStatus = status ?? 'Pending';
      _isLoading = false;
    });
  }

  String _statusToArabic(String status) {
    switch (status) {
      case 'Approved':
        return 'تم الموافقة ✅';
      case 'Rejected':
        return 'مرفوض ❌';
      case 'Pending':
      default:
        return 'قيد المراجعة ⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kGreen))
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'images/specialist-ajial-logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Welcome text
                        Text(
                          'مرحباً، $_specialistName',
                          style: const TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(_specialistStatus)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _statusColor(_specialistStatus)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'حالة الحساب: ${_statusToArabic(_specialistStatus)}',
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(_specialistStatus),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'هذه الصفحة مؤقتة — سيتم تحديثها قريباً',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _service.logoutSpecialist();
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SpecialistLoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return _kGreen;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }
}
