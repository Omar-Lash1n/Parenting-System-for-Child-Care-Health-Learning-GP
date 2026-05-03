import 'package:flutter/material.dart';
import 'package:Ajial/homepage/models/upcoming_task_model.dart';
import 'package:Ajial/homepage/providers/parent_home_provider.dart';
import 'package:Ajial/homepage/widgets/home_empty_state_card.dart';
import 'package:Ajial/homepage/widgets/home_task_card.dart';
import 'package:Ajial/homepage/widgets/section_header.dart';
import 'package:Ajial/widgets/skeleton_loading.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class UpcomingTasksSection extends StatelessWidget {
  final HomeDataStatus status;
  final List<UpcomingTaskModel> tasks;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onShowAllTap;

  const UpcomingTasksSection({
    super.key,
    required this.status,
    required this.tasks,
    required this.error,
    required this.onRetry,
    required this.onShowAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'المهام', onShowAllTap: onShowAllTap),
        _buildBody(),
      ],
    );
  }

  Widget _buildBody() {
    switch (status) {
      case HomeDataStatus.initial:
      case HomeDataStatus.loading:
        return const SkeletonShimmer(
          child: Column(
            children: [
              SkeletonBox(width: double.infinity, height: 92, borderRadius: 16),
              SizedBox(height: 16),
              SkeletonBox(width: double.infinity, height: 92, borderRadius: 16),
            ],
          ),
        );
      case HomeDataStatus.error:
        return _SectionError(message: error, onRetry: onRetry);
      case HomeDataStatus.loaded:
        if (tasks.isEmpty) {
          return const HomeEmptyStateCard(
            text: 'يبدو أنه لا يوجد مهام في الوقت الحالي',
          );
        }
        return Column(
          children: List.generate(tasks.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == tasks.length - 1 ? 0 : 16,
              ),
              child: HomeTaskCard(task: tasks[index]),
            );
          }),
        );
    }
  }
}

class _SectionError extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _SectionError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          Text(
            message ?? 'حدث خطأ في تحميل البيانات',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              color: Color(0xBF000000),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontFamily: _kFont),
            ),
            style: TextButton.styleFrom(foregroundColor: _kPrimary),
          ),
        ],
      ),
    );
  }
}
