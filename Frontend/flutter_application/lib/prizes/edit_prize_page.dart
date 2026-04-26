// lib/prizes/edit_prize_page.dart
//
// "تعديل المكافئة" — edit/delete an existing prize.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/prizes/add_edit_prize_provider.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';
import 'package:Ajial/prizes/widgets/prize_form_body.dart';
import 'package:Ajial/prizes/widgets/prize_modals.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kDanger = Color(0xFFFF0000);
const String _kFont = 'IBM Plex Sans Arabic';

/// Returned via Navigator.pop from EditPrizePage:
/// - updated: non-null when the user successfully saved.
/// - deleted: true when the user deleted the prize.
class PrizeEditResult {
  final PrizeDetail? updated;
  final bool deleted;
  const PrizeEditResult({this.updated, this.deleted = false});
}

class EditPrizePage extends StatelessWidget {
  final PrizeDetail prize;
  const EditPrizePage({super.key, required this.prize});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditPrizeProvider()..initEdit(prize),
      child: _EditPrizePageBody(prize: prize),
    );
  }
}

class _EditPrizePageBody extends StatelessWidget {
  final PrizeDetail prize;
  const _EditPrizePageBody({required this.prize});

  bool get _isLocked => prize.isDelivered;

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
                title: 'تعديل المكافأة',
                onClose: () => Navigator.pop(context),
              ),
              if (_isLocked)
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'لا يمكن تعديل مكافئة تم تسليمها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        color: Colors.black54),
                  ),
                ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _isLocked,
                  child: const PrizeFormBody(),
                ),
              ),
              _ActionButtons(
                disabled: _isLocked,
                onUpdate: () => _submit(context),
                onDelete: () => _delete(context),
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
    final updated = await provider.submitUpdate();
    if (updated == null || !context.mounted) return;
    Navigator.pop<PrizeEditResult>(
      context,
      PrizeEditResult(updated: updated),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showPrizeDeleteConfirmDialog(context);
    if (!confirm || !context.mounted) return;
    final provider = context.read<AddEditPrizeProvider>();
    final ok = await provider.deleteCurrent();
    if (!ok || !context.mounted) return;
    Navigator.pop<PrizeEditResult>(
      context,
      const PrizeEditResult(deleted: true),
    );
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
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final bool disabled;
  const _ActionButtons({
    required this.onUpdate,
    required this.onDelete,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AddEditPrizeProvider>(
      builder: (context, p, _) {
        final isBusy = p.submitting;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              GestureDetector(
                onTap: (disabled || isBusy) ? null : onUpdate,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: disabled
                        ? Colors.grey.shade300
                        : _kPrimary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('تحديث المكافئة',
                          style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color:
                                  disabled ? Colors.black45 : Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: isBusy ? null : onDelete,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _kDanger.withValues(alpha: 0.7)),
                  ),
                  child: const Text('حذف المكافئة',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _kDanger)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
