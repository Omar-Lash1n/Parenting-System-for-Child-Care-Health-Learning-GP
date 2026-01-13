// --- lib/profile/privacy_page.dart ---
// Privacy Policy Page

import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFBF092F);
const Color kBlue = Color(0xFF008CFF);
const String kFontFamily = 'IBM Plex Sans Arabic';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  // Privacy Content
                  _buildPrivacySection(
                    title: 'جمع البيانات',
                    content:
                        'نقوم بجمع المعلومات التي تقدمها لنا مباشرة، مثل الاسم والبريد الإلكتروني ومعلومات الأطفال، لتوفير خدماتنا.',
                    icon: Icons.data_usage,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'استخدام البيانات',
                    content:
                        'نستخدم المعلومات التي نجمعها لتحسين خدماتنا وتخصيص تجربة المستخدم وإرسال التحديثات المهمة.',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'حماية البيانات',
                    content:
                        'نتخذ تدابير أمنية صارمة لحماية معلوماتك من الوصول غير المصرح به أو التعديل أو الكشف.',
                    icon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'مشاركة البيانات',
                    content:
                        'لا نبيع أو نشارك معلوماتك الشخصية مع أطراف ثالثة إلا عند الضرورة لتقديم خدماتنا أو بموجب القانون.',
                    icon: Icons.share_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'حقوقك',
                    content:
                        'لديك الحق في الوصول إلى بياناتك وتعديلها وحذفها. يمكنك أيضاً طلب نسخة من بياناتك في أي وقت.',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'ملفات تعريف الارتباط',
                    content:
                        'نستخدم ملفات تعريف الارتباط لتحسين تجربة التصفح. يمكنك التحكم في إعدادات ملفات تعريف الارتباط من خلال إعدادات جهازك.',
                    icon: Icons.cookie_outlined,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 38),
        const Text(
          'سياسة الخصوصية',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8.64),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20.73,
              color: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: kBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xBF000000),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
