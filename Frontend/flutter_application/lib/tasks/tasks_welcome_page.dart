// --- lib/tasks/tasks_welcome_page.dart ---
// Welcome / intro page for the parent Tasks feature.

import 'package:flutter/material.dart';

const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// TasksWelcomePage
///
/// Full-screen intro page displayed when the parent first opens the Tasks
/// feature. Shows a "To Do" notebook illustration, welcome text, and
/// navigation buttons.
///
/// Route: '/tasks-welcome'
class TasksWelcomePage extends StatelessWidget {
  const TasksWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ── Header ──────────────────────────────────────────────
              const _HeaderSection(),

              // ── Illustration (expands to fill) ──────────────────────
              Expanded(
                child: Center(
                  child: _TodoIllustration(),
                ),
              ),

              // ── Action Buttons ──────────────────────────────────────
              _ActionButtons(
                onNext: () {
                  Navigator.pushNamed(context, '/tasks');
                },
                onBack: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Header Section ──────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'مرحباً بكم في قائمة مهامكم!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 33 / 22,
              color: Color(0xFF000000),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'هنا يمكنكم تنظيم اليوم لمهامكم ومهام الاطفال\nايضاً بخطوات بسيطة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontWeight: FontWeight.w300,
              fontSize: 15,
              height: 24 / 15,
              color: Color(0xBF000000),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Illustration ────────────────────────────────────────────

class _TodoIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pink circle background
          Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF8E8EC),
            ),
          ),

          // To-Do notebook image (clipped as a circle)
          ClipOval(
            child: Image.asset(
              'images/todo_notebook.png',
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.checklist_rounded,
                size: 100,
                color: _kPrimaryColor,
              ),
            ),
          ),

          // Calendar badge – bottom left
          Positioned(
            bottom: 25,
            left: 5,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: const BoxDecoration(
                  color: _kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'images/task_date_icon.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.calendar_today_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Fork badge – top right
          Positioned(
            top: 25,
            right: 5,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: const BoxDecoration(
                  color: _kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'images/task_fork_icon.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.restaurant_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Action Buttons ──────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _ActionButtons({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // التالي (Next) — primary red button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text(
              'التالي',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // رجوع (Back) — white outlined button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'رجوع',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
