import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';
import 'package:Ajial/tasks/models/task_model.dart';
import 'package:Ajial/child-app/tasks/child_task_details_page.dart';
import 'dart:math';

class ChildTasksPage extends StatefulWidget {
  const ChildTasksPage({super.key});

  @override
  State<ChildTasksPage> createState() => _ChildTasksPageState();
}

class _ChildTasksPageState extends State<ChildTasksPage> {
  late List<TaskModel> _tasks;

  @override
  void initState() {
    super.initState();
    // Force landscape mode when entering this page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Mock Tasks to demonstrate the logic
    final now = DateTime.now();
    _tasks = [
      // Past: Completed (Green)
      TaskModel(
        id: '1',
        title: 'مهمة 1',
        category: 'تنظيف',
        assignees: [],
        color: Colors.blue,
        date: now.subtract(const Duration(days: 2)),
        isCompleted: true,
      ),
      // Past: Not Completed (Red)
      TaskModel(
        id: '2',
        title: 'مهمة 2',
        category: 'دراسة',
        assignees: [],
        color: Colors.orange,
        date: now.subtract(const Duration(days: 1)),
        isCompleted: false,
      ),
      // Today: 3 Tasks (First uncompleted = Play, others = Numbered/Active)
      TaskModel(
        id: '3',
        title: 'مهمة 3',
        category: 'لعب',
        assignees: [],
        color: Colors.blue,
        date: now,
        isCompleted: true, // Today completed
      ),
      TaskModel(
        id: '4',
        title: 'مهمة 4',
        category: 'قراءة',
        assignees: [],
        color: Colors.orange,
        date: now,
        isCompleted: false, // Today active (Play Button)
      ),
      TaskModel(
        id: '5',
        title: 'مهمة 5',
        category: 'صلاة',
        assignees: [],
        color: Colors.purple,
        date: now,
        isCompleted: false, // Today active (Next)
      ),
      // Future: 2 Tasks (Grey with Lock)
      TaskModel(
        id: '6',
        title: 'مهمة 6',
        category: 'نوم',
        assignees: [],
        color: Colors.cyan,
        date: now.add(const Duration(days: 1)),
        isCompleted: false,
      ),
      TaskModel(
        id: '7',
        title: 'مهمة 7',
        category: 'ترتيب',
        assignees: [],
        color: Colors.teal,
        date: now.add(const Duration(days: 2)),
        isCompleted: false,
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is in portrait mode
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    // Sort tasks by date
    _tasks.sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    // Find the LAST available task (the furthest task unlocked up to today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    TaskModel? lastAvailableTask;
    for (var task in _tasks) {
      if (task.date != null) {
        final taskDay = DateTime(task.date!.year, task.date!.month, task.date!.day);
        if (!taskDay.isAfter(today)) {
          lastAvailableTask = task;
        }
      }
    }

    final provider = context.watch<ChildHomeProvider>();

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
            // --- The Path and Nodes ---
            Positioned.fill(
              child: ListView.builder(
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
                      child: _buildTaskNode(task, index + 1, task == lastAvailableTask, today),
                    ),
                  );
                },
              ),
            ),

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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            const Icon(Icons.star, color: Colors.yellow, size: 28),
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
                              color: Colors.black.withOpacity(0.2),
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

  Widget _buildTaskNode(TaskModel task, int level, bool isLastAvailable, DateTime today) {
    bool isPast = false;
    bool isToday = false;
    bool isFuture = false;

    if (task.date != null) {
      final taskDay = DateTime(task.date!.year, task.date!.month, task.date!.day);
      if (taskDay.isBefore(today)) {
        isPast = true;
      } else if (taskDay.isAtSameMomentAs(today)) {
        isToday = true;
      } else {
        isFuture = true;
      }
    } else {
      isToday = true; // Fallback
    }

    Widget nodeContent;
    Color mainColor;
    Color darkColor;
    double size = 85.0; // Slightly larger to accommodate 3D effect

    // Default content is the level number
    nodeContent = Text(
      '$level',
      style: const TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: Color(0xFFEEEEEE), // Slightly off-white like the image
      ),
    );

    if (isFuture) {
      // Future tasks are locked (Grey)
      mainColor = const Color(0xFFBDBDBD);
      darkColor = const Color(0xFF9E9E9E);
      nodeContent = const Icon(Icons.lock, color: Colors.white, size: 36);
    } else if (isLastAvailable) {
      // The LAST available task gets the Play icon
      size = 110.0;
      mainColor = const Color(0xFF00C853); // Bright Green
      darkColor = const Color(0xFF009624); // Darker Green
      nodeContent = const Icon(Icons.play_arrow, color: Colors.white, size: 60);
    } else if (isPast) {
      // Past tasks (Done = Green, Missed = Red) - shows number
      if (task.isCompleted) {
        mainColor = const Color(0xFF4CAF50); // Green
        darkColor = const Color(0xFF388E3C);
      } else {
        mainColor = const Color(0xFFE53935); // Red
        darkColor = const Color(0xFFC62828);
      }
    } else {
      // Today tasks (that are not the last available) - Purple
      mainColor = const Color(0xFF9C27B0); // Purple
      darkColor = const Color(0xFF7B1FA2);
    }

    return GestureDetector(
      onTap: () {
        if (!isFuture) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChildTaskDetailsPage(
                task: task,
                rewardStars: 20, // Mock reward
                onTaskCompleted: () {
                  setState(() {
                    task.isCompleted = true;
                  });
                },
              ),
            ),
          );
        }
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
              color: Colors.black.withOpacity(0.3),
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
