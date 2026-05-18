import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';
import 'package:Ajial/child-app/tasks/child_home_task_repository.dart';
import 'package:Ajial/child-app/tasks/child_task_details_page.dart';
import 'dart:math';

class ChildTasksPage extends StatefulWidget {
  const ChildTasksPage({super.key});

  @override
  State<ChildTasksPage> createState() => _ChildTasksPageState();
}

class _ChildTasksPageState extends State<ChildTasksPage> {
  final _repo = ChildHomeTaskRepository();
  List<ChildHomeTaskItem> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Force landscape mode when entering this page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _loadTasks();
  }

  @override
  void dispose() {
    // Revert to portrait mode when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _repo.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks = response.allTasks;
        _isLoading = false;
      });
      // Sync stars with provider so all pages see the latest value
      // ignore: use_build_context_synchronously
      context.read<ChildHomeProvider>().setStars(response.totalStars);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is in portrait mode
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    final provider = context.watch<ChildHomeProvider>();

    // Build content based on state
    Widget body;
    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8F00)),
      );
    } else if (_errorMessage != null) {
      body = Center(
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
              onPressed: _loadTasks,
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
    } else if (_tasks.isEmpty) {
      body = const Center(
        child: Text(
          'لا توجد مهام حالياً',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Sort tasks by dueDate
      _tasks.sort((a, b) =>
          (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

      body = _buildTasksContent(provider);
    }

    // The main content of the landscape page
    Widget content = Directionality(
      textDirection: TextDirection.ltr, // Left to right for the path to progress forward
      child: Container(
        // Swap width and height if we are forcing rotation in portrait mode
        width: isPortrait ? size.height : size.width,
        height: isPortrait ? size.width : size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/child_tasks_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // --- Body (loading / error / tasks) ---
            Positioned.fill(child: body),

            // --- Top UI Elements ---
            SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl, // RTL for top UI
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Child Points (Stars) - Top Right (in RTL, this is Top Left visually)
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

                      // Back Button - Top Left (in RTL, this is Top Right visually)
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
                            Icons.arrow_forward, // Arrow forward in RTL points right
                            color: Colors.black,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black, // Dark background behind the rotated box if any
      body: isPortrait
          ? Center(
              child: RotatedBox(
                quarterTurns: 1, // Rotate 90 degrees to simulate landscape
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildTasksContent(ChildHomeProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 100),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        // Create a simple oscillating vertical offset for the path curve
        final double yOffset = sin(index * pi / 2) * 0.4;

        return SizedBox(
          width: 140, // Spacing between nodes
          child: Align(
            alignment: Alignment(0, yOffset + 0.2), // slightly lower
            child: _buildTaskNode(task, index + 1, today),
          ),
        );
      },
    );
  }

  Widget _buildTaskNode(ChildHomeTaskItem task, int level, DateTime today) {
    bool isDueToday = false;
    bool isPast = false;

    if (task.dueDate != null) {
      final taskDay =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      if (taskDay.isBefore(today)) {
        isPast = true;
      } else if (taskDay.isAtSameMomentAs(today)) {
        isDueToday = true;
      }
    } else {
      isDueToday = true; // Fallback: treat as today
    }

    Widget nodeContent;
    Color mainColor;
    Color darkColor;
    double size = 85.0;

    // Default content is the level number
    nodeContent = Text(
      '$level',
      style: const TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: Color(0xFFEEEEEE),
      ),
    );

    // Color logic:
    // - isCompleted == true → GREEN
    // - isCompleted == false && dueDate is today → PURPLE  
    // - isCompleted == false (past or no specific date logic) → RED
    if (task.isCompleted) {
      // ✅ Completed → Green
      mainColor = const Color(0xFF4CAF50);
      darkColor = const Color(0xFF388E3C);
      nodeContent = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$level',
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEEEEEE),
            ),
          ),
        ],
      );
    } else if (isDueToday) {
      // 🟣 Today & not completed → Purple (active, playable)
      size = 100.0;
      mainColor = const Color(0xFF9C27B0);
      darkColor = const Color(0xFF7B1FA2);
      nodeContent = const Icon(Icons.play_arrow, color: Colors.white, size: 50);
    } else if (isPast) {
      // 🔴 Past & not completed → Red (missed)
      mainColor = const Color(0xFFE53935);
      darkColor = const Color(0xFFC62828);
    } else {
      // 🔴 Future & not completed → Red
      mainColor = const Color(0xFFE53935);
      darkColor = const Color(0xFFC62828);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildTaskDetailsPage(
              taskId: task.taskId,
              taskTitle: task.title,
              rewardStars: task.stars,
              isCompleted: task.isCompleted,
              onTaskCompleted: () {
                // Reload tasks after completion
                _loadTasks();
              },
            ),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: mainColor,
          shape: BoxShape.circle,
          boxShadow: [
            // The "thickness" of the 3D coin (Darker color, sharp offset)
            BoxShadow(
              color: darkColor,
              offset: const Offset(3, 5),
              blurRadius: 0,
              spreadRadius: 0,
            ),
            // The drop shadow underneath the coin
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(4, 8),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(child: nodeContent),
      ),
    );
  }
}
