import 'package:flutter/material.dart';
import 'package:Ajial/homepage/models/current_vaccination_model.dart';
import 'package:Ajial/homepage/providers/parent_home_provider.dart';
import 'package:Ajial/homepage/widgets/home_empty_state_card.dart';
import 'package:Ajial/homepage/widgets/section_header.dart';
import 'package:Ajial/homepage/widgets/vaccination_card.dart';
import 'package:Ajial/widgets/skeleton_loading.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class CurrentVaccinationsSection extends StatelessWidget {
  final HomeDataStatus status;
  final List<CurrentVaccinationModel> vaccinations;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onShowAllTap;

  const CurrentVaccinationsSection({
    super.key,
    required this.status,
    required this.vaccinations,
    required this.error,
    required this.onRetry,
    required this.onShowAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'التطعيمات', onShowAllTap: onShowAllTap),
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
              SkeletonBox(width: double.infinity, height: 122, borderRadius: 16),
              SizedBox(height: 16),
              SkeletonBox(width: double.infinity, height: 122, borderRadius: 16),
            ],
          ),
        );
      case HomeDataStatus.error:
        return _SectionError(message: error, onRetry: onRetry);
      case HomeDataStatus.loaded:
        if (vaccinations.isEmpty) {
          return const HomeEmptyStateCard(
            text: 'يبدو أنه لا يوجد تطعيم في الوقت الحالي',
          );
        }
        return Column(
          children: List.generate(vaccinations.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == vaccinations.length - 1 ? 0 : 16,
              ),
              child: VaccinationCard(
                vaccination: vaccinations[index],
                onSetReminder: () {},
              ),
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
