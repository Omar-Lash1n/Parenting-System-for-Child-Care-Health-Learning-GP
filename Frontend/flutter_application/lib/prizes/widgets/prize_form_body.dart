// lib/prizes/widgets/prize_form_body.dart
//
// Shared scrollable form body used by Add and Edit prize pages.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/prizes/add_edit_prize_provider.dart';
import 'package:Ajial/prizes/widgets/child_avatar_selector.dart';
import 'package:Ajial/prizes/widgets/prize_image_picker.dart';
import 'package:Ajial/prizes/widgets/star_stepper_widget.dart';
import 'package:Ajial/prizes/widgets/task_selector_dropdown.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class PrizeFormBody extends StatefulWidget {
  const PrizeFormBody({super.key});

  @override
  State<PrizeFormBody> createState() => _PrizeFormBodyState();
}

class _PrizeFormBodyState extends State<PrizeFormBody> {
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<AddEditPrizeProvider>();
    _titleCtrl = TextEditingController(text: p.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            text,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<AddEditPrizeProvider>(
      builder: (context, p, _) {
        // Keep the controller in sync with provider title (edit init).
        if (_titleCtrl.text != p.title) {
          _titleCtrl
            ..text = p.title
            ..selection =
                TextSelection.collapsed(offset: _titleCtrl.text.length);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: PrizeImagePicker(
                  pickedBytes: p.pickedImageBytes,
                  existingImageUrl: p.existingImageUrl,
                  prizeName: p.title.isNotEmpty ? p.title : null,
                  onPick: () => _pickImage(context),
                  onRemove: p.hasImage ? p.removeImage : null,
                ),
              ),
              const SizedBox(height: 16),
              _label('عنوان المكافئة'),
              TextField(
                controller: _titleCtrl,
                textDirection: TextDirection.rtl,
                maxLength: 60,
                onChanged: p.setTitle,
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'مثل: لعبة صيد الأسماك',
                  hintStyle: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      color: Color(0xFF999999)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.55)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('عدد نجوم الحصول على المكافئة'),
              StarStepperWidget(
                value: p.stars,
                onIncrement: p.incrementStars,
                onDecrement: p.decrementStars,
              ),
              const SizedBox(height: 16),
              _label('ارفاق مهام محددة'),
              TaskSelectorDropdown(
                tasks: p.availableTasks,
                selectedTaskIds: p.selectedTaskIds,
                onToggle: p.toggleTask,
                loading: p.loadingTasks,
                enabled: p.selectedChildId != null,
              ),
              if (p.selectedChildId == null && !p.isEdit) ...[
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'اختر الطفل أولاً لعرض مهامه',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12,
                        color: Color(0xFF999999)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _label('ظهور المكافئة عند'),
              if (p.loadingChildren)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                ChildAvatarSelector(
                  children: p.eligibleChildren,
                  selectedChildId: p.selectedChildId,
                  onSelect: p.selectChild,
                  readOnly: p.isEdit, // child can't change in edit mode
                ),
              if (p.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFFFF0000).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFFF0000), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.error!,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontFamily: _kFont,
                              fontSize: 13,
                              color: Color(0xFFB00020)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final p = context.read<AddEditPrizeProvider>();
    final source = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 48, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار من الاستوديو',
                    style: TextStyle(fontFamily: _kFont)),
                onTap: () => Navigator.pop(sheetCtx, false),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('التقاط صورة',
                    style: TextStyle(fontFamily: _kFont)),
                onTap: () => Navigator.pop(sheetCtx, true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    await p.pickImage(fromCamera: source);
  }
}
