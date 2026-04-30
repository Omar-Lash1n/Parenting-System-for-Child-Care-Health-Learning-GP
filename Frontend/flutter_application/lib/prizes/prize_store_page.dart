// lib/prizes/prize_store_page.dart
//
// Main page: "متجر مكافئات الاطفال"
// Empty state when there are no prizes, list of cards otherwise,
// FAB to open Add Prize, onboarding overlay on first visit.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/prizes/prize_store_provider.dart';
import 'package:Ajial/prizes/prize_onboarding_overlay.dart';
import 'package:Ajial/prizes/widgets/prize_card_widget.dart';
import 'package:Ajial/prizes/widgets/prize_empty_state.dart';
import 'package:Ajial/prizes/widgets/prize_modals.dart';
import 'package:Ajial/prizes/add_prize_page.dart';
import 'package:Ajial/prizes/edit_prize_page.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class PrizeStorePage extends StatefulWidget {
  const PrizeStorePage({super.key});

  @override
  State<PrizeStorePage> createState() => _PrizeStorePageState();
}

class _PrizeStorePageState extends State<PrizeStorePage> {
  bool _onboardingTriggered = false;

  late ConfettiController _confettiControllerTopRight;
  late ConfettiController _confettiControllerBottomLeft;

  @override
  void initState() {
    super.initState();
    _confettiControllerTopRight = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    _confettiControllerBottomLeft = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<PrizeStoreProvider>().loadPrizes();
      if (!mounted) return;
      if (!_onboardingTriggered) {
        _onboardingTriggered = true;
        if (await shouldShowPrizesOnboarding() && mounted) {
          await showPrizesOnboarding(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _confettiControllerTopRight.dispose();
    _confettiControllerBottomLeft.dispose();
    super.dispose();
  }

  void _playCelebration() {
    _confettiControllerTopRight.play();
    _confettiControllerBottomLeft.play();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _confettiControllerTopRight.play();
        _confettiControllerBottomLeft.play();
      }
    });
  }

  Path _drawConfettiPath(Size size) {
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, 0);
    path.close();
    return path;
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<PrizeDetail?>(
      context,
      MaterialPageRoute(builder: (_) => const AddPrizePage()),
    );
    if (created != null && mounted) {
      await context.read<PrizeStoreProvider>().refresh();
    }
  }

  Future<void> _openEdit(PrizeDetail prize) async {
    final result = await Navigator.push<PrizeEditResult?>(
      context,
      MaterialPageRoute(builder: (_) => EditPrizePage(prize: prize)),
    );
    if (!mounted) return;
    if (result == null) return;
    if (result.deleted) {
      await context.read<PrizeStoreProvider>().refresh();
    } else if (result.updated != null) {
      context.read<PrizeStoreProvider>().replacePrize(result.updated!);
    }
  }

  Future<void> _onDeliverTap(PrizeDetail prize) async {
    if (!prize.canDeliver) {
      // Show appropriate error message — backend conditions explained
      // in the plan: tasks not done OR stars not enough.
      final allDone = prize.completedTasksCount >= prize.totalRequiredTasks;
      final enoughStars = prize.currentStars >= prize.requiredStars;
      String msg;
      if (!allDone) {
        msg = 'لم يتم طلب المكافأة\nيجب ان يطلب الطفل المكافأة حتى يمكن تسليمها اليه';
      } else if (!enoughStars) {
        msg = 'لم يتم تجميع النجوم المطلوبة\nيجب ان يتم تجميع النجوم للطفل بعد بعد ذلك يمكن تسليمها اليه';
      } else {
        msg = 'لا يمكن تسليم المكافأة الآن';
      }
      await showPrizeInfoDialog(context, message: msg);
      return;
    }

    final confirm = await showPrizeDeliverConfirmDialog(context);
    if (!confirm || !mounted) return;

    try {
      await context.read<PrizeStoreProvider>().deliverPrize(prize.prizeId);
      if (!mounted) return;
      _playCelebration();
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').toLowerCase();
      String msg;
      if (raw.contains('star')) {
        msg = 'لم يتم تجميع النجوم المطلوبة';
      } else if (raw.contains('task') || raw.contains('complete')) {
        msg = 'لم يتم طلب المكافأة';
      } else {
        msg = e.toString().replaceFirst('Exception: ', '');
      }
      await showPrizeInfoDialog(context, message: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Consumer<PrizeStoreProvider>(
                      builder: (context, p, _) {
                        if (p.isLoading && p.prizes.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(color: _kPrimary),
                          );
                        }
                        if (p.hasError && p.prizes.isEmpty) {
                          return _ErrorView(
                            message: p.error ?? 'حدث خطأ غير متوقع',
                            onRetry: p.refresh,
                          );
                        }
                        if (p.prizes.isEmpty) {
                          return RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: p.refresh,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                PrizeEmptyState(),
                                SizedBox(height: 240),
                              ],
                            ),
                          );
                        }
                        return RefreshIndicator(
                          color: _kPrimary,
                          onRefresh: p.refresh,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 160),
                            itemCount: p.prizes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, i) {
                              final prize = p.prizes[i];
                              return PrizeCardWidget(
                                prize: prize,
                                isDelivering:
                                    p.isDelivering(prize.prizeId),
                                onDeliver: () => _onDeliverTap(prize),
                                onEdit: () => _openEdit(prize),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // FAB
            Positioned(
              bottom: 80,
              right: 16,
              child: _GiftFab(onPressed: _openAdd),
            ),
            // Bottom nav
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomNavBar(currentIndex: 1),
            ),
            // Confetti celebration (plays on top of everything)
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiControllerTopRight,
                blastDirection: pi * 0.75,
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.orange,
                  Colors.purple,
                  _kPrimary,
                ],
                createParticlePath: _drawConfettiPath,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: ConfettiWidget(
                confettiController: _confettiControllerBottomLeft,
                blastDirection: -pi * 0.25,
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Color(0xFF01A449),
                ],
                createParticlePath: _drawConfettiPath,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              'متجر مكافئات الاطفال',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.arrow_forward,
                  color: _kPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gift FAB ──────────────────────────────────────────────────────────────

class _GiftFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _GiftFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: _kPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'images/gift.png',
            width: 26,
            height: 26,
            color: Colors.white,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.card_giftcard, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
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
              onPressed: () => onRetry(),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: _kFont, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

