// --- lib/child-app/home/child_home_page.dart ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';
import 'package:Ajial/child-app/child-sign-in.dart';
import 'package:Ajial/child-app/recordings/child_recordings_page.dart';
import 'package:Ajial/child-app/tasks/child_tasks_page.dart';
import 'package:Ajial/child-app/rewards/child_rewards_page.dart';
import 'package:Ajial/child-app/home/math_game_page.dart';
import 'package:Ajial/child-app/home/memory_game_page.dart';
import 'package:Ajial/child-app/home/draw_game_page.dart';

// --- Constants ---
const String kFontFamily = 'IBM Plex Sans Arabic';
const Color kBgColorTop = Color(0x80B0CEE3); // rgba(176, 206, 227, 0.5)
const Color kBgColorBottom = Color(0x00B0CEE3); // rgba(176, 206, 227, 0)

// Card Colors
const Color kBlueCardStart = Color(0x80008CFF); // rgba(0, 140, 255, 0.5)
const Color kBlueCardEnd = Color(0xFF008CFF);
const Color kPurpleCardStart = Color(0xFFB99AF6);
const Color kPurpleCardEnd = Color(0xFF7B78FB);
const Color kCyanCardStart = Color(0xFF11C2F4);
const Color kCyanCardEnd = Color(0xFF07A5CD);
const Color kOrangeCardStart = Color(0xFFFEA400);
const Color kOrangeCardEnd = Color(0xFFFD5E00);
const Color kStarPillBorder = Color(0xFFC84A00);

class ChildHomePage extends StatefulWidget {
  final String? childName;
  final int? initialStars;
  final bool isFirstLogin;

  const ChildHomePage({
    super.key,
    this.childName,
    this.initialStars,
    this.isFirstLogin = true,
  });

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage>
    with TickerProviderStateMixin {
  late AnimationController _starAnimationController;

  // Global key to get star counter position
  final GlobalKey _starCounterKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChildHomeProvider>();
      provider.initializeWithData(
        name: widget.childName ?? 'طفل',
        stars: widget.initialStars ?? 0,
        isFirstLogin: widget.isFirstLogin,
      );

      // Fetch latest star count from the API
      provider.refreshStarsFromApi();

      // Start first-time experience after a short delay
      if (widget.isFirstLogin) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            provider.startFirstTimeExperience();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _starAnimationController.dispose();
    super.dispose();
  }

  // --- Logout Function ---
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ChildLoginScreen()),
      (route) => false,
    );
  }

  // --- Navigate to Recordings with Star Collection Animation ---
  void _navigateToRecordings(ChildHomeProvider provider) async {
    // If stars not yet collected, show popup first
    if (!provider.microphoneStarsCollected) {
      // Show stars popup - navigation will happen after collection
      provider.showMicrophoneStarsPopup();
      return;
    }
    
    // Navigate to recordings page directly if stars already collected
    _doNavigateToRecordings(provider);
  }

  // --- Actually navigate to recordings ---
  void _doNavigateToRecordings(ChildHomeProvider provider) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildRecordingsPage(
            childName: provider.childName,
            currentStars: provider.currentStars,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Consumer<ChildHomeProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                // --- Background ---
                _buildBackground(),

                // --- Main Layout with Fixed Grass ---
                Column(
                  children: [
                    // --- Fixed Header (Sticky) ---
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.02),
                            // --- Header (RTL: Name on right, Stars on left) ---
                            _buildHeader(provider, size),
                          ],
                        ),
                      ),
                    ),
                    
                    // --- Scrollable Content Area ---
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.02),

                              // --- Cards ---
                              _buildCardsContent(provider, size),
                              
                              // --- Logout Button ---
                              SizedBox(height: size.height * 0.02),
                              _buildLogoutButton(),
                              SizedBox(height: size.height * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- Fixed Grass Decoration at Bottom (Minimized) ---
                    _buildGrassDecoration(size),
                  ],
                ),

                // --- UI Lock Overlay ---
                if (provider.isUILocked)
                  Container(
                    color: const Color(0x4D000000), // Black with 30% opacity
                  ),

                // --- New Hero Dialog (Shows FIRST) ---
                if (provider.showNewHeroDialog)
                  _buildNewHeroDialog(provider, size),

                // --- Collect Stars Dialog (Shows SECOND) ---
                if (provider.showCollectStarsDialog)
                  _buildCollectStarsDialog(provider, size),

                // --- Flying Stars Animation ---
                if (provider.isAnimatingStars)
                  _buildFlyingStarsAnimation(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Background Widget ---
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

  // --- Header with Child Name (Right) and Star Counter (Left) ---
  Widget _buildHeader(ChildHomeProvider provider, Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Child Name Pill (Right side in RTL)
        _buildChildNamePill(provider),

        // Star Counter Pill (Left side in RTL)
        _buildStarCounterPill(provider, key: _starCounterKey),
      ],
    );
  }

  // --- Star Counter Pill (Star on left, Number on right visually) ---
  Widget _buildStarCounterPill(ChildHomeProvider provider, {Key? key}) {
    return Container(
      key: key,
      constraints: const BoxConstraints(minWidth: 85, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kOrangeCardStart, kOrangeCardEnd],
        ),
        border: Border.all(color: kStarPillBorder, width: 2),
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
          // Number (FIRST in Row = appears on RIGHT in RTL)
          Text(
            '${provider.currentStars}',
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          // Star image (SECOND in Row = appears on LEFT in RTL)
          Image.asset(
            'images/stars.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Child Name Pill ---
  Widget _buildChildNamePill(ChildHomeProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile image
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 22,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Text(
            provider.childName,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- Cards Content ---
  Widget _buildCardsContent(ChildHomeProvider provider, Size size) {
    final cardSpacing = size.width * 0.03;
    final topCardHeight = size.height * 0.28;
    final middleCardHeight = size.height * 0.20;
    final bottomCardHeight = size.height * 0.18;

    return Column(
      children: [
        // Row 1: Full width "انس يتكلم" card with shine effect
        SizedBox(
          height: topCardHeight,
          width: double.infinity,
          child: _buildMicrophoneCard(
            title: '${provider.childName} يتكلم',
            badgeNumber: 10,
            showBadge: !provider.microphoneStarsCollected, // Hide after collection
            onTap: () => _navigateToRecordings(provider),
          ),
        ),
        SizedBox(height: cardSpacing),

        // Row 2: "تحدي جديد" full width card
        SizedBox(
          height: middleCardHeight, // Or maybe a bit larger, let's use the same height as microphone but a bit smaller, or just full width
          width: double.infinity,
          child: _buildActivityCard(
            title: 'تحدي جديد',
            gradientColors: [kOrangeCardStart, kOrangeCardEnd], // #FEA400 to #FD5E00
            imagePath: 'images/target.png',
            imageSize: 70,
            fontSize: 26,
            onTap: () {
              provider.playClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChildTasksPage()),
              );
            },
          ),
        ),
        SizedBox(height: cardSpacing),

        // Row 3: "ارسم" and "ارقام"
        SizedBox(
          height: middleCardHeight,
          child: Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  title: 'ارسم',
                  gradientColors: [kPurpleCardStart, kPurpleCardEnd],
                  imagePath: 'images/art.png',
                  imageSize: 70,
                  fontSize: 24,
                  onTap: () {
                    provider.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DrawGamePage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildActivityCard(
                  title: 'ارقام',
                  gradientColors: [kCyanCardStart, kCyanCardEnd],
                  imagePath: 'images/numbers.png',
                  imageSize: 70,
                  fontSize: 24,
                  onTap: () {
                    provider.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MathGamePage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: cardSpacing),

        // Row: Full width "لعبة الذاكرة" (Memory Match) card
        SizedBox(
          height: middleCardHeight,
          width: double.infinity,
          child: _buildActivityCard(
            title: 'لعبة الذاكرة',
            gradientColors: const [Color(0xFF7BD88F), Color(0xFF34A853)],
            imagePath: 'images/grapes.png',
            imageSize: 70,
            fontSize: 24,
            onTap: () {
              provider.playClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemoryGamePage()),
              );
            },
          ),
        ),
        SizedBox(height: cardSpacing),

        // Row 4: Full width "جوائز" card
        SizedBox(
          height: bottomCardHeight,
          width: double.infinity,
          child: _buildActivityCard(
            title: 'جوائز',
            gradientColors: [kBlueCardStart, kBlueCardEnd], // 0x80008CFF to 0xFF008CFF
            imagePath: 'images/prize.png',
            imageSize: 70,
            fontSize: 24,
            onTap: () {
              provider.playClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChildRewardsPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Microphone Card with Lighter Background + Shine Effect ---
  Widget _buildMicrophoneCard({
    required String title,
    required int badgeNumber,
    bool showBadge = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Lighter blue background gradient
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7EC8E3), // Lighter blue at top
              Color(0xFF56A0D3), // Medium blue at bottom
            ],
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
              color: Color(0x664AA3DF),
              offset: Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shine/Glow effect behind microphone
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFFFFF).withAlpha(120), // White glow center
                        const Color(0xFFFFFFFF).withAlpha(40),  // Fade out
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Sound wave lines (left and right of microphone)
            Positioned.fill(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left sound waves
                    _buildSoundWaves(),
                    const SizedBox(width: 100), // Space for microphone
                    // Right sound waves
                    _buildSoundWaves(),
                  ],
                ),
              ),
            ),

            // Card content - centered microphone and title
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Microphone image (bigger)
                  Image.asset(
                    'images/microphone.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.mic,
                        size: 100,
                        color: Color(0xFF1E6091),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Title (bigger font)
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Star badge at top right with stars beside each other
            if (showBadge)
              Positioned(
                top: 14,
                right: 14,
                child: _buildStarBadge(badgeNumber),
              ),
          ],
        ),
      ),
    );
  }

  // --- Sound Wave Lines ---
  Widget _buildSoundWaves() {
    return Row(
      children: List.generate(3, (index) {
        final height = 20.0 + (index * 10);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0x80FFFFFF), // Semi-transparent white
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // --- Star Badge (Pill style with number + overlapping colored stars) ---
  Widget _buildStarBadge(int number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kOrangeCardStart, kOrangeCardEnd],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF8F00), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFC84A00),
            offset: Offset(2, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Number (FIRST in Row = appears on RIGHT in RTL)
          Text(
            '$number',
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Overlapping stars with shadow (SECOND in Row = appears on LEFT in RTL)
          SizedBox(
            width: 52,
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Star 1 (back)
                Positioned(
                  left: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'images/stars.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.star, color: Colors.amber, size: 20);
                      },
                    ),
                  ),
                ),
                // Star 2 (middle - slightly bigger)
                Positioned(
                  left: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'images/stars.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.star, color: Colors.amber, size: 22);
                      },
                    ),
                  ),
                ),
                // Star 3 (front)
                Positioned(
                  left: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'images/stars.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.star, color: Colors.amber, size: 20);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Logout Button ---
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE53935), width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFB71C1C),
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              color: Color(0xFFE53935),
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'تسجيل خروج',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Activity Card Widget (Enlarged images and text) ---
  Widget _buildActivityCard({
    required String title,
    required List<Color> gradientColors,
    required String imagePath,
    double imageSize = 60,
    double fontSize = 22,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                gradientColors.last.r.toInt(),
                gradientColors.last.g.toInt(),
                gradientColors.last.b.toInt(),
                0.4,
              ),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image from assets (bigger)
              Image.asset(
                imagePath,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: imageSize,
                    color: const Color(0xE6FFFFFF),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Title (bigger font)
              Text(
                title,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Grass Decoration at Bottom (Same as child-sign-in.dart) ---
  Widget _buildGrassDecoration(Size size) {
    return Image.asset(
      'images/png-clipart-free-content-graphy-website-grass-s-presentation-computer-wallpaper-removebg-preview 1.png',
      width: double.infinity,
      fit: BoxFit.cover,
      height: 120,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image not found
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade300,
                Colors.green.shade500,
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Collect Stars Dialog (Figma Design) ---
  Widget _buildCollectStarsDialog(ChildHomeProvider provider, Size size) {
    return Center(
      child: Container(
        width: 282,
        padding: const EdgeInsets.fromLTRB(24, 35, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            // Figma: box-shadow: 0px 0px 25px rgba(0, 0, 0, 0.25), 3px 6px 0px #FE8F00;
            BoxShadow(
              color: Color(0x40000000), // rgba(0, 0, 0, 0.25)
              blurRadius: 25,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: Color(0xFFFE8F00), // #FE8F00
              blurRadius: 0,
              offset: Offset(3, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars row with overlapping stars + number badge
            SizedBox(
              height: 99,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Overlapping stars with glow effect (from Figma)
                  Positioned(
                    left: 0,
                    child: _buildGlowingStar(size: 70),
                  ),
                  Positioned(
                    left: 25,
                    child: _buildGlowingStar(size: 80),
                  ),
                  Positioned(
                    left: 55,
                    child: _buildGlowingStar(size: 90),
                  ),
                  Positioned(
                    left: 90,
                    child: _buildGlowingStar(size: 80),
                  ),
                  
                  // Number badge (orange circle with number)
                  Positioned(
                    right: 0,
                    top: 22,
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [kOrangeCardStart, kOrangeCardEnd],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${provider.pendingStars}',
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Collect button (Figma style)
            GestureDetector(
              onTap: () async {
                _starAnimationController.forward(from: 0);
                
                // Check if this was triggered from microphone card tap
                final shouldNavigate = provider.pendingNavigateToRecordings;
                
                await provider.collectStars();
                
                // If from microphone card, mark stars as collected and navigate
                if (shouldNavigate) {
                  provider.markMicrophoneStarsCollected();
                  _doNavigateToRecordings(provider);
                }
              },
              child: Container(
                width: 234,
                height: 55,
                decoration: BoxDecoration(
                  // Figma: background: linear-gradient(180deg, #FEA400 0%, #FD5E00 100%);
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kOrangeCardStart, kOrangeCardEnd],
                  ),
                  // Figma: border: 1px solid #FD5E00;
                  border: Border.all(color: kOrangeCardEnd, width: 1),
                  // Figma: box-shadow: 3px 6px 0px #C84A00;
                  boxShadow: const [
                    BoxShadow(
                      color: kStarPillBorder, // #C84A00
                      blurRadius: 0,
                      offset: Offset(3, 6),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    'اجمع النجوم',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- Glowing Star Widget (Just the star image - NO glow/shadow) ---
  Widget _buildGlowingStar({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'images/stars.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.star,
            size: size,
            color: Colors.amber,
          );
        },
      ),
    );
  }

  // --- New Hero Dialog (Figma Design) ---
  Widget _buildNewHeroDialog(ChildHomeProvider provider, Size size) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card
          Container(
            width: 282,
            height: 236,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                // Figma: box-shadow: 0px 0px 25px rgba(0, 0, 0, 0.25), 3px 6px 0px #FE8F00;
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 25,
                  offset: Offset(0, 0),
                ),
                BoxShadow(
                  color: Color(0xFFFE8F00),
                  blurRadius: 0,
                  offset: Offset(3, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Badge Image (123x123 from Figma)
                SizedBox(
                  width: 123,
                  height: 123,
                  child: Image.asset(
                    'images/premium-star.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.workspace_premium,
                        size: 100,
                        color: Color(0xFFFFA500),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Title with gradient text effect (Figma style)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kOrangeCardStart, kOrangeCardEnd],
                  ).createShader(bounds),
                  child: const Text(
                    'بطل جديد',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // This gets masked by gradient
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Close button (positioned outside top-right corner)
          Positioned(
            top: -15,
            right: -15,
            child: GestureDetector(
              onTap: () => provider.claimHeroBadge(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    // Figma: box-shadow: 1px 2px 0px #FD7700, 0px 0px 15px rgba(0, 0, 0, 0.25);
                    BoxShadow(
                      color: Color(0xFFFD7700),
                      blurRadius: 0,
                      offset: Offset(1, 2),
                    ),
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 15,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    size: 36,
                    color: Color(0xFFFE8F00), // Figma: background: #FE8F00;
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Flying Stars Animation ---
  Widget _buildFlyingStarsAnimation(ChildHomeProvider provider) {
    return AnimatedBuilder(
      animation: _starAnimationController,
      builder: (context, child) {
        return Stack(
          children: List.generate(5, (index) {
            final delay = index * 0.15;
            final progress =
                (_starAnimationController.value - delay).clamp(0.0, 1.0);

            return Positioned(
              top: MediaQuery.of(context).size.height * 0.4 -
                  (progress * MediaQuery.of(context).size.height * 0.35),
              left: MediaQuery.of(context).size.width * 0.5 -
                  (progress * MediaQuery.of(context).size.width * 0.35) +
                  (index - 2) * 15,
              child: Opacity(
                opacity: 1.0 - progress,
                child: Transform.scale(
                  scale: 1.0 - (progress * 0.5),
                  child: Image.asset(
                    'images/stars.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.star,
                        size: 40,
                        color: Colors.amber,
                      );
                    },
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
