// --- lib/profile/terms_page.dart ---
// Terms of Use Page

import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFBF092F);
const Color kGreen = Color(0xFF01A449);
const String kFontFamily = 'IBM Plex Sans Arabic';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
                  // Terms Content
                  _buildTermsSection(
                    title: '1. مقدمة',
                    content:
                        'مرحباً بك في تطبيق أجيال. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    title: '2. استخدام التطبيق',
                    content:
                        'يجب استخدام التطبيق للأغراض المشروعة فقط. لا يجوز استخدامه بأي طريقة قد تضر بالآخرين أو تنتهك حقوقهم.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    title: '3. حسابات المستخدمين',
                    content:
                        'أنت مسؤول عن الحفاظ على سرية معلومات حسابك وكلمة المرور الخاصة بك. يجب إخطارنا فوراً بأي استخدام غير مصرح به.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    title: '4. المحتوى',
                    content:
                        'جميع المحتويات المنشورة في التطبيق محمية بحقوق الملكية الفكرية. لا يجوز نسخها أو توزيعها دون إذن مسبق.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    title: '5. إخلاء المسؤولية',
                    content:
                        'يتم توفير التطبيق "كما هو" دون أي ضمانات. لا نتحمل المسؤولية عن أي أضرار ناتجة عن استخدام التطبيق.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    title: '6. التعديلات',
                    content:
                        'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية.',
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
          'شروط الاستخدام',
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

  Widget _buildTermsSection({required String title, required String content}) {
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: kGreen,
                  size: 16,
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
