// --- lib/child-app/recordings/child_recordings_page.dart ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/recordings/recordings_provider.dart';
import 'package:Ajial/child-app/recordings/child_record_page.dart';

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

class ChildRecordingsPage extends StatelessWidget {
  final String childName;
  final int currentStars;

  const ChildRecordingsPage({
    super.key,
    required this.childName,
    required this.currentStars,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = RecordingsProvider();
        // Initialize async (will fetch from API)
        provider.initialize(
          name: childName,
          stars: currentStars,
        );
        return provider;
      },
      child: const _RecordingsPageContent(),
    );
  }
}

class _RecordingsPageContent extends StatelessWidget {
  const _RecordingsPageContent();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Consumer<RecordingsProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                // --- Background ---
                _buildBackground(),

                // --- Main Content ---
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
                            // --- Header ---
                            _buildHeader(context, provider),
                          ],
                        ),
                      ),
                    ),
                    
                    // --- Scrollable Content ---
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.02),

                            // --- Recordings List or Empty State ---
                            Expanded(
                              child: provider.isLoading
                                  ? _buildLoadingState()
                                  : provider.errorMessage != null
                                      ? _buildErrorState(provider.errorMessage!)
                                      : provider.recordings.isEmpty
                                          ? _buildEmptyState()
                                          : _buildRecordingsList(provider),
                            ),

                            // --- Start Recording Button ---
                            _buildStartButton(context),

                            SizedBox(height: size.height * 0.02),
                          ],
                        ),
                      ),
                    ),

                    // --- Grass Decoration ---
                    _buildGrassDecoration(),
                  ],
                ),
              ],
            );
          },
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
  Widget _buildHeader(BuildContext context, RecordingsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button (Left in RTL = Right visually)
        _buildBackButton(context),

        // Star Counter (Right in RTL = Left visually)
        _buildStarCounter(provider.currentStars),
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
      onTap: () => Navigator.pop(context),
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

  // --- Loading State ---
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: kBlueButton,
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل التسجيلات...',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // --- Error State ---
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: kRedButton,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'مفيش اي تسجيلات ليك يا بطل',
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // --- Recordings List ---
  Widget _buildRecordingsList(RecordingsProvider provider) {
    return ListView.builder(
      itemCount: provider.recordings.length,
      itemBuilder: (context, index) {
        final recording = provider.recordings[index];
        final isPlaying = provider.currentPlayingId == recording.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRecordingItem(
            recording: recording,
            isPlaying: isPlaying,
            onTap: () => provider.togglePlayback(recording),
          ),
        );
      },
    );
  }

  // --- Recording Item (Pill-shaped) ---
  Widget _buildRecordingItem({
    required Recording recording,
    required bool isPlaying,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 71,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
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
        children: [
          // Play/Pause Button
          Padding(
            padding: const EdgeInsets.all(13),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isPlaying ? kRedButton : kBlueButton,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPlaying ? kRedBorder : kBlueBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPlaying ? kRedBorder : kBlueBorder,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Recording Name
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                recording.name,
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Start Recording Button ---
  Widget _buildStartButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<RecordingsProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: ChildRecordPage(
                childName: provider.childName,
                currentStars: provider.currentStars,
              ),
            ),
          ),
        ).then((_) {
          // Force rebuild to show new recordings
          // ignore: invalid_use_of_protected_member
          (context as Element).markNeedsBuild();
        });
      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microphone icon
            const Icon(
              Icons.mic,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            // Text
            const Text(
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
