import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/homepage/providers/parent_home_provider.dart';
import 'package:Ajial/homepage/widgets/children_section.dart';
import 'package:Ajial/homepage/widgets/current_vaccinations_section.dart';
import 'package:Ajial/homepage/widgets/daily_question_card.dart';
import 'package:Ajial/homepage/widgets/hardware_ad_card.dart';
import 'package:Ajial/homepage/widgets/home_header.dart';
import 'package:Ajial/homepage/widgets/parenting_nutrition_section.dart';
import 'package:Ajial/homepage/widgets/quick_actions_section.dart';
import 'package:Ajial/homepage/widgets/upcoming_tasks_section.dart';
import 'package:Ajial/lessons/providers/lesson_provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/widgets/skeleton_loading.dart';

const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final homeProvider = context.read<ParentHomeProvider>();
      final familyProvider = context.read<FamilyProvider>();
      final profileProvider = context.read<ParentProfileProvider>();
      final lessonProvider = context.read<LessonProvider>();

      if (homeProvider.vaccinationsStatus == HomeDataStatus.initial &&
          homeProvider.tasksStatus == HomeDataStatus.initial) {
        homeProvider.loadAll();
      }
      if (familyProvider.status == FamilyStatus.initial) {
        familyProvider.loadChildren();
      }
      if (profileProvider.profileData == null && !profileProvider.isLoading) {
        profileProvider.fetchProfile();
      }
      if (lessonProvider.lessonsStatus == LessonsStatus.initial) {
        lessonProvider.loadLessons(pageSize: 3);
      }
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ParentHomeProvider>().loadAll(),
      context.read<FamilyProvider>().loadChildren(),
      context.read<ParentProfileProvider>().fetchProfile(),
      context.read<LessonProvider>().loadLessons(pageSize: 3),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
        body: SafeArea(
          bottom: false,
          child: Consumer3<ParentHomeProvider, FamilyProvider,
              ParentProfileProvider>(
            builder: (context, homeProvider, familyProvider, profileProvider, _) {
              if (homeProvider.isInitialLoading &&
                  familyProvider.status == FamilyStatus.initial) {
                return const HomepageSkeleton();
              }

              return RefreshIndicator(
                color: kPrimaryColor,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      HomeHeader(
                        profileProvider: profileProvider,
                        familyProvider: familyProvider,
                      ),
                      const SizedBox(height: 24),
                      const DailyQuestionCard(),
                      const SizedBox(height: 24),
                      HardwareAdCard(
                        onOrderTap: () =>
                            Navigator.pushNamed(context, '/tracking/entry'),
                      ),
                      const SizedBox(height: 24),
                      const QuickActionsSection(),
                      const SizedBox(height: 24),
                      ChildrenSection(
                        children: familyProvider.children,
                        onAddChildTap: () =>
                            Navigator.pushNamed(context, '/add-child'),
                        onShowAllTap: () =>
                            Navigator.pushNamed(context, '/family'),
                      ),
                      const SizedBox(height: 24),
                      Consumer<LessonProvider>(
                        builder: (_, lessonProvider, __) =>
                            ParentingNutritionSection(
                          lessons: lessonProvider.lessons,
                          isLoading: lessonProvider.lessonsStatus ==
                              LessonsStatus.loading,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CurrentVaccinationsSection(
                        status: homeProvider.vaccinationsStatus,
                        vaccinations: homeProvider.vaccinations,
                        error: homeProvider.vaccinationsError,
                        onRetry: homeProvider.loadVaccinations,
                        onShowAllTap: () =>
                            Navigator.pushNamed(context, '/kids-vaccination-home'),
                      ),
                      const SizedBox(height: 24),
                      UpcomingTasksSection(
                        status: homeProvider.tasksStatus,
                        tasks: homeProvider.tasks,
                        error: homeProvider.tasksError,
                        onRetry: homeProvider.loadTasks,
                        onShowAllTap: () => Navigator.pushNamed(context, '/tasks'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
