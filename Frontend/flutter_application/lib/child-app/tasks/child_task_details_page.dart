import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';
import 'package:Ajial/child-app/tasks/child_home_task_repository.dart';

class ChildTaskDetailsPage extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final int rewardStars;
  final bool isCompleted;
  final VoidCallback onTaskCompleted;

  const ChildTaskDetailsPage({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.onTaskCompleted,
    this.rewardStars = 20,
    this.isCompleted = false,
  });

  @override
  State<ChildTaskDetailsPage> createState() => _ChildTaskDetailsPageState();
}

class _ChildTaskDetailsPageState extends State<ChildTaskDetailsPage> {
  final _repo = ChildHomeTaskRepository();
  ChildHomeTaskDetail? _detail;
  bool _isLoading = true;
  bool _isCompleting = false;
  String? _errorMessage;
  late bool _isCompleted;

  // Audio player for recording playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
    // Force landscape mode when entering this page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _loadDetail();

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    // Reset icon when audio completes
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _repo.fetchTaskDetail(widget.taskId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final url = _detail?.recordingUrl;
    if (url == null || url.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // If player is stopped/completed, set the source again
        if (_audioPlayer.state == PlayerState.completed ||
            _audioPlayer.state == PlayerState.stopped) {
          await _audioPlayer.setSourceUrl(url);
        }
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
      _showSnack('تعذر تشغيل التسجيل');
    }
  }

  Future<void> _completeTask(ChildHomeProvider provider) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      final success = await _repo.completeTask(widget.taskId);
      if (!mounted) return;
      if (success) {
        setState(() => _isCompleted = true);
        // Show completion dialog with stars
        _showCompletionDialog(context, provider);
      } else {
        _showSnack('فشل في إكمال المهمة');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
      backgroundColor: const Color(0xFFBF092F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is in portrait mode
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    final provider = context.watch<ChildHomeProvider>();

    final String title = _detail?.title ?? widget.taskTitle;
    final int stars = _detail?.stars ?? widget.rewardStars;
    final String? imageUrl = _detail?.taskImageUrl;
    final bool hasRecording = _detail?.recordingUrl != null &&
        _detail!.recordingUrl!.isNotEmpty;

    // Build body content
    Widget bodyContent;
    if (_isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8F00)),
      );
    } else if (_errorMessage != null) {
      bodyContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image and Stars
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Task Image
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 140,
                            height: 140,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.task_alt,
                                size: 60,
                                color: Colors.blue),
                          )
                        : const Icon(Icons.task_alt,
                            size: 60, color: Colors.blue),
                  ),
                ),

                // Stars Badge
                Positioned(
                  bottom: -15,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3 Overlapping Stars
                      SizedBox(
                        width: 50,
                        height: 30,
                        child: Stack(
                          children: const [
                            Positioned(
                                left: 0,
                                child: Icon(Icons.star,
                                    color: Colors.amber, size: 28)),
                            Positioned(
                                left: 10,
                                child: Icon(Icons.star,
                                    color: Colors.amber, size: 30)),
                            Positioned(
                                left: 20,
                                child: Icon(Icons.star,
                                    color: Colors.amber, size: 28)),
                          ],
                        ),
                      ),
                      // Number Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8F00),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$stars',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Task Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/Pause Audio Button (always show if there is a recording)
                if (hasRecording)
                  _buildActionButton(
                    color: _isPlaying
                        ? const Color(0xFFFF8F00) // Orange when playing
                        : const Color(0xFF008CFF), // Blue when paused
                    shadowColor: _isPlaying
                        ? const Color(0xFFE65100)
                        : const Color(0xFF005CB2),
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                    iconColor: Colors.white,
                    onTap: _togglePlayback,
                  ),
                if (!_isCompleted) ...[
                  if (hasRecording) const SizedBox(width: 30),
                  // Complete Task Button (✓)
                  _isCompleting
                      ? Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF8F00),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        )
                      : _buildActionButton(
                          color: Colors.white,
                          shadowColor: Colors.black,
                          icon: Icons.check,
                          iconColor: Colors.black,
                          onTap: () {
                            _completeTask(provider);
                          },
                        ),
                ],
                // Show completed badge if already completed
                if (_isCompleted) ...[
                  if (hasRecording) const SizedBox(width: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF388E3C),
                          offset: Offset(2, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'تم الإنجاز',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans Arabic',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    // The main content of the landscape page
    Widget content = Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: isPortrait ? size.height : size.width,
        height: isPortrait ? size.width : size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/child_task_details_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // --- Main Content (Center) ---
              bodyContent,

              // --- Top UI Elements ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Points (Stars) - Top Right in RTL
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star,
                              color: Colors.yellow, size: 28),
                        ],
                      ),
                    ),

                    // Back Button - Top Left in RTL
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () {
                          _audioPlayer.stop();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: isPortrait
          ? Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: content,
              ),
            )
          : content,
    );
  }

  void _showCompletionDialog(
      BuildContext context, ChildHomeProvider provider) {
    // Stop any playing audio before showing the dialog
    _audioPlayer.stop();

    final stars = _detail?.stars ?? widget.rewardStars;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final isPortrait = size.height > size.width;

        Widget dialogContent = Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFFF8F00),
                offset: Offset(0, 10),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars Cluster
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    height: 60,
                    child: Stack(
                      children: const [
                        Positioned(
                            left: 0,
                            bottom: 0,
                            child: Icon(Icons.star,
                                color: Colors.amber, size: 50)),
                        Positioned(
                            left: 25,
                            bottom: 10,
                            child: Icon(Icons.star,
                                color: Colors.amber, size: 55)),
                        Positioned(
                            left: 50,
                            bottom: 10,
                            child: Icon(Icons.star,
                                color: Colors.amber, size: 55)),
                        Positioned(
                            left: 75,
                            bottom: 0,
                            child: Icon(Icons.star,
                                color: Colors.amber, size: 50)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8F00),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            offset: Offset(2, 2),
                            blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      '$stars',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Collect Button
              GestureDetector(
                onTap: () {
                  provider.refreshStarsFromApi();
                  provider.playSound('assets/sounds/collect_stars.mp3');
                  widget.onTaskCompleted();
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFE65100),
                        offset: Offset(0, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'اجمع النجوم',
                      style: TextStyle(
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

        if (isPortrait) {
          dialogContent = RotatedBox(
            quarterTurns: 1,
            child: dialogContent,
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: dialogContent,
        );
      },
    );
  }

  Widget _buildActionButton({
    required Color color,
    required Color shadowColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: color == Colors.white
              ? Border.all(color: Colors.black, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(2, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(4, 6),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 40),
      ),
    );
  }
}
