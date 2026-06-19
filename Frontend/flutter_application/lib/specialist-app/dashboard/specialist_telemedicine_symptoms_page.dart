import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/models/doctor_consultation_models.dart';

class SpecialistTelemedicineSymptomsPage extends StatelessWidget {
  final DoctorBookingDetail detail;

  const SpecialistTelemedicineSymptomsPage({super.key, required this.detail});

  Future<void> _openUrl(BuildContext context, String url) async {
    // Capture the messenger before the await to avoid using context across the gap.
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack(messenger, 'الرابط غير صالح');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _showSnack(messenger, 'تعذر فتح الملف');
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: specialistFont),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'images/Box.png',
            width: 48,
            height: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: specialistFont,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildFilledText(String text) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: specialistFont,
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFileRow(String text, String buttonText, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black87),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = detail.complaintDescription;
    final hasComplaint = complaint != null && complaint.trim().isNotEmpty;
    final attachments = detail.attachments;
    final hasMedicalFile =
        detail.shareMedicalFile && detail.medicalFileUrl != null;

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
                    const Expanded(
                      child: Text(
                        'الاعراض والشكوي',
                        style: TextStyle(
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('وصف الشكوى الحالية للمريض'),
                      hasComplaint
                          ? _buildFilledText(complaint)
                          : _buildEmptyBox(
                              'يبدو انه لم يتم ارفاق وصف للشكوى او الاعراض'),
                      const SizedBox(height: 24),
                      _buildSectionTitle('صور تحاليل أو أشعة'),
                      if (attachments.isEmpty)
                        _buildEmptyBox(
                            'يبدو انه لم يتم اضافة صورة تحاليل او اشعة')
                      else
                        ...List.generate(attachments.length, (i) {
                          final att = attachments[i];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: i == attachments.length - 1 ? 0 : 12),
                            child: _buildFileRow(
                              attachments.length > 1
                                  ? 'صورة ${i + 1}'
                                  : 'تم ارفاق صورة',
                              'فتح الصورة',
                              () => _openUrl(context, att.imageUrl),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      _buildSectionTitle('الملف الطبي للطفل'),
                      hasMedicalFile
                          ? _buildFileRow(
                              'تم ارفاق الملف الطبي',
                              'فتح الملف الطبي',
                              () => _openUrl(context, detail.medicalFileUrl!),
                            )
                          : _buildEmptyBox('يبدو انه لم يتم ارفاق الملف الطبي'),
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
}
