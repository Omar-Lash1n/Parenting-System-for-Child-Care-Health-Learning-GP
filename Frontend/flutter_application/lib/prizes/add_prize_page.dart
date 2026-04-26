// lib/prizes/add_prize_page.dart
//
// "اضف مكافأة" — create a new prize.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/prizes/add_edit_prize_provider.dart';
import 'package:Ajial/prizes/edit_prize_page.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';
import 'package:Ajial/prizes/widgets/prize_form_body.dart';
import 'package:Ajial/prizes/widgets/prize_modals.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class AddPrizePage extends StatelessWidget {
  const AddPrizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditPrizeProvider()
        ..initAdd()
        ..loadChildren(),
      child: const _AddPrizePageBody(),
    );
  }
}

class _AddPrizePageBody extends StatelessWidget {
  const _AddPrizePageBody();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                title: 'اضف مكافأة',
                onClose: () => Navigator.pop(context),
              ),
              const Expanded(child: PrizeFormBody()),
              _ActionButtons(
                primaryLabel: 'اضف المكافئة',
                onPrimary: () => _submit(context),
                onCancel: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final provider = context.read<AddEditPrizeProvider>();
    final created = await provider.submitCreate();
    if (created == null || !context.mounted) return;

    final action = await showPrizeCreateSuccessDialog(
      context,
      childFullName: created.childFullName,
    );
    if (!context.mounted) return;

    switch (action) {
      case CreateSuccessAction.edit:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EditPrizePage(prize: created)),
        );
        break;
      case CreateSuccessAction.view:
      case null:
        Navigator.pop<PrizeDetail>(context, created);
        break;
    }
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
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
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action buttons ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onCancel;
  const _ActionButtons({
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AddEditPrizeProvider>(
      builder: (context, p, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              GestureDetector(
                onTap: p.submitting ? null : onPrimary,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: p.submitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(primaryLabel,
                          style: const TextStyle(
                              fontFamily: _kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: p.submitting ? null : onCancel,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.5)),
                  ),
                  child: const Text('الغاء',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
