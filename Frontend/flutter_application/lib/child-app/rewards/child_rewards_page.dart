import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';

class RewardItem {
  final String title;
  final int requiredStars;
  final String imagePath;
  bool isAcquired;

  RewardItem({
    required this.title, 
    required this.requiredStars, 
    required this.imagePath,
    this.isAcquired = false,
  });
}

class ChildRewardsPage extends StatefulWidget {
  const ChildRewardsPage({super.key});

  @override
  State<ChildRewardsPage> createState() => _ChildRewardsPageState();
}

class _ChildRewardsPageState extends State<ChildRewardsPage> {
  final List<RewardItem> mockRewards = [
    RewardItem(title: 'لعبة صيد الاسماك', requiredStars: 50, imagePath: 'images/stars.png'),
    RewardItem(title: 'لعبة المكعبات', requiredStars: 30, imagePath: 'images/stars.png'),
    RewardItem(title: 'قطار الحروف', requiredStars: 100, imagePath: 'images/stars.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildHomeProvider>();
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE2E8F0), // Light grayish-blue background
        body: SafeArea(
          child: Stack(
            children: [
              // Grass Background at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'images/grass_bottom.png', // Fallback to an asset or draw it
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.green],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Column(
                children: [
                  // Header (Points and Back Button)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Star Counter Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8F00),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFC84A00), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFC84A00),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${provider.currentStars}',
                                style: const TextStyle(
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, color: Colors.yellow, size: 24),
                            ],
                          ),
                        ),

                        // Back Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rewards List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: mockRewards.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        return _buildRewardCard(mockRewards[index], provider.currentStars, provider);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(RewardItem reward, int currentStars, ChildHomeProvider provider) {
    // Calculate progress (clamped between 0.0 and 1.0)
    double progress = currentStars / reward.requiredStars;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Reward Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
              border: Border.all(color: Colors.green, width: 4),
              image: DecorationImage(
                image: AssetImage(reward.imagePath),
                fit: BoxFit.contain, // Used for mock image
              ),
            ),
            // Placeholder icon if image is missing
            child: const Center(
              child: Icon(Icons.videogame_asset, size: 60, color: Colors.green),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            reward.title,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar (Hide if acquired)
          if (!reward.isAcquired) ...[
            Container(
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF8F00), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ),
                    // Progress Text overlay
                    Center(
                      child: Text(
                        '$currentStars / ${reward.requiredStars}',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progress > 0.5 ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Collect Button
          GestureDetector(
            onTap: () {
              if (!reward.isAcquired) {
                _handleRewardTap(reward, currentStars, provider);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: reward.isAcquired ? const Color(0xFF4CAF50) : const Color(0xFFFF8F00), // Green if acquired
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Button thickness
                  BoxShadow(
                    color: reward.isAcquired ? const Color(0xFF388E3C) : const Color(0xFFE65100),
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  reward.isAcquired ? 'حصلت عليها' : 'اكسب',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRewardTap(RewardItem reward, int currentStars, ChildHomeProvider provider) {
    if (currentStars >= reward.requiredStars) {
      // Success
      _showPopup(
        isSuccess: true,
        message: 'مبرروووك',
        onClose: () {
          // Deduct stars and mark acquired
          provider.addStars(-reward.requiredStars);
          setState(() {
            reward.isAcquired = true;
          });
          Navigator.pop(context);
        },
      );
    } else {
      // Fail
      _showPopup(
        isSuccess: false,
        message: 'لازم تجمع نجوم تاني\nعشان تكسب',
        onClose: () {
          Navigator.pop(context);
        },
      );
    }
  }

  void _showPopup({required bool isSuccess, required String message, required VoidCallback onClose}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final borderColor = isSuccess ? const Color(0xFFD32F2F) : const Color(0xFFD32F2F); 
        // Wait, the prompt says:
        // isSuccess = true -> Green border, "مبرروووك"
        // isSuccess = false -> Red border, "لازم تجمع نجوم تاني عشان تكسب"
        final actualBorderColor = isSuccess ? const Color(0xFF388E3C) : const Color(0xFFD32F2F);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Main Popup Container
              Container(
                width: 320,
                padding: const EdgeInsets.only(top: 40, bottom: 40, left: 24, right: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    // Bottom border/shadow matching success/fail
                    BoxShadow(
                      color: actualBorderColor,
                      offset: const Offset(0, 10),
                      blurRadius: 0,
                    ),
                    const BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Close Icon (Top Right)
              Positioned(
                top: -15,
                right: -15,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: actualBorderColor, width: 3),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: actualBorderColor,
                      size: 28,
                      weight: 900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
