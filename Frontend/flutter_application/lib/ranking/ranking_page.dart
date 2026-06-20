import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/ranking/models/ranking_models.dart';
import 'package:Ajial/ranking/providers/ranking_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kGold = Color(0xFFFFD700);
const Color _kSilver = Color(0xFFC0C0C0);
const Color _kBronze = Color(0xFFCD7F32);
const String _kFont = 'IBM Plex Sans Arabic';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RankingProvider>().loadRanking();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<RankingProvider>().loadMoreRanking();
    }
  }

  String _formatCountdown(Duration d) {
    final days = d.inDays;
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$days يوم : $hours س : $mins ق';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<RankingProvider>(
                  builder: (context, provider, _) => _buildBody(provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'لوحة التكريم',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  color: _kPrimary, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RankingProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (provider.error != null && provider.entries.isEmpty) {
      if (provider.error!.contains('لم يتم نشر')) {
        return _buildEmptyState();
      }
      return _buildErrorView(provider);
    }

    if (provider.entries.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildMedalHero(provider),
              const SizedBox(height: 20),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < provider.entries.length) {
                final entry = provider.entries[index];
                final isCurrentUser = provider.currentParentId != null &&
                    entry.parentId == provider.currentParentId;
                return _RankingListItem(
                    entry: entry, isCurrentUser: isCurrentUser);
              }
              return null;
            },
            childCount: provider.entries.length,
          ),
        ),
        // Bottom loader / load-more indicator
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (provider.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: _kPrimary, strokeWidth: 2),
                    ),
                  ),
                )
              else if (!provider.hasMore && provider.entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'تم عرض جميع المشاركين',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _buildCtaButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedalHero(RankingProvider provider) {
    final paged = provider.pagedRanking;
    return Column(
      children: [
        _buildMedalWidget(),
        const SizedBox(height: 12),
        Text(
          paged?.seasonName ?? 'الأب المثالي',
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildCountdownChip(provider.countdownRemaining),
      ],
    );
  }

  Widget _buildMedalWidget() {
    return SizedBox(
      width: 140,
      height: 175,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kGold,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kOrange),
                child: const Icon(Icons.star, size: 70, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRibbonTail(skewLeft: false),
                const SizedBox(width: 20),
                _buildRibbonTail(skewLeft: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonTail({required bool skewLeft}) {
    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.skewX(skewLeft ? 0.2 : -0.2),
      child: Container(
        width: 20,
        height: 40,
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownChip(Duration? countdown) {
    final text = countdown != null
        ? _formatCountdown(countdown)
        : '-- يوم : -- س : -- ق';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.access_time, color: _kPrimary, size: 16),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kOrange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () => Navigator.pushNamed(context, '/lessons'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'تصفح دروس جديدة وجمع نجوم',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15,
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'لم يتم نشر أي ترتيب حتى الآن',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: _kFont, fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorView(RankingProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _kFont, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => context.read<RankingProvider>().loadRanking(),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: _kFont, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ranking List Item ──────────────────────────────────────────────────────

class _RankingListItem extends StatelessWidget {
  final RankingEntry entry;
  final bool isCurrentUser;

  const _RankingListItem({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: _kPrimary, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stars (leftmost in RTL)
          SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_border, color: _kOrange, size: 18),
                const SizedBox(height: 2),
                Text(
                  '${entry.stars}',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Name + children count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.fullName,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.childrenCount > 0
                      ? '${entry.childrenCount} اطفال'
                      : '- اطفال',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (entry.profileImageUrl != null &&
                    entry.profileImageUrl!.isNotEmpty)
                ? NetworkImage(entry.profileImageUrl!)
                : null,
            child: (entry.profileImageUrl == null ||
                    entry.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey, size: 24)
                : null,
          ),
          const SizedBox(width: 8),
          // Medal badge (rightmost in RTL)
          _buildBadge(entry.rank),
        ],
      ),
    );
  }

  Widget _buildBadge(int rank) {
    if (rank > 3) return const SizedBox(width: 28);
    final color = rank == 1 ? _kGold : rank == 2 ? _kSilver : _kBronze;
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const Icon(Icons.star, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}
