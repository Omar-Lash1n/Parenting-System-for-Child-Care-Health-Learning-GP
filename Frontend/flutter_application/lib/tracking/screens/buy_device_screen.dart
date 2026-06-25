import 'package:flutter/material.dart';
import 'add_device_screen.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

class BuyDeviceScreen extends StatelessWidget {
  const BuyDeviceScreen({super.key});

  static const _features = [
    'تتبع لحظي فائق الدقة',
    'سياج جغرافي ذكي (Geofencing)',
    'اتصال صوتي مباشر وبجهتين',
    'سجل تحركات تفصيلي',
    'بطارية ذكية طويلة الأمد',
    'مؤشرات أداء وقتية',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProductCard(),
                      const SizedBox(height: 12),
                      _buildDescriptionSection(),
                      const SizedBox(height: 12),
                      _buildFeaturesSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AddDeviceScreen()),
                    ),
                    child: const Text(
                      'اطلب القطعة الان 2500ج.م',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: _kFont,
                        color: Colors.white,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: _kPinkLight, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: _kRed, size: 22),
            ),
          ),
          const Spacer(),
          const Text(
            'شراء قطعة التتبع',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, fontFamily: _kFont),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 200,
              color: Colors.grey.shade100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 16,
                        )
                      ],
                    ),
                    child: const Icon(Icons.watch_rounded,
                        size: 64, color: Color(0xFF888888)),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'QBIT',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '2500ج.م',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: _kFont,
                        color: _kRed,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '3000ج.م',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: _kFont,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'قطعة QBIT للتتبع',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: _kFont),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'قطعة ذكية لتتبع الطفل',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontFamily: _kFont),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Text(
            'وصف القطعة',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont),
          ),
          SizedBox(height: 10),
          Text(
            'لأن سلامة طفلك هي أولويتك الأولى، صممنا لك قطعة التتبع الذكية لتكون عينك الحارسة التي لا تنام. قطعة صغيرة الحجم، خفيفة الوزن، وسهلة الارتداء، تمنحك طمأنينة كاملة ومتابعة لحظية لتحركات طفلك على مدار اليوم مباشرة عبر تطبيقنا. لا مزيد من القلق بعد اليوم، طفلك دائماً في أمان وتحت رعايتك أينما كان.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: _kFont,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'مميزات القطعة',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: _kFont),
          ),
          const SizedBox(height: 12),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(f,
                      style: const TextStyle(
                          fontSize: 13, fontFamily: _kFont)),
                  const SizedBox(width: 10),
                  const Icon(Icons.check_circle_outline,
                      color: _kRed, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
