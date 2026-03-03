// --- lib/profile/confirm_delete_child.dart ---
// Confirm Delete Child Screen - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/confirm_delete_provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';

const Color _kDangerRed = Color(0xFFD90000);
const Color _kTextBlack = Colors.black;
const String _kFontFamily = 'IBM Plex Sans Arabic';

class ConfirmDeleteChildPage extends StatelessWidget {
  final String childName;
  final String childId;
  const ConfirmDeleteChildPage({
    super.key,
    required this.childName,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfirmDeleteProvider(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                // Main content column
                Column(
                  children: [
                    // ── Top bar with X button ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // start = RIGHT in RTL
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.close,
                                    size: 20, color: _kTextBlack),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Hero: bin icon + title ─────────────────────────
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _kDangerRed.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 50,
                          color: _kDangerRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ConfirmDeleteStrings.screenTitle(childName),
                      style: const TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kTextBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // ── Input section ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Consumer<ConfirmDeleteProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                textDirection: TextDirection.rtl,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kTextBlack,
                                  ),
                                  children: [
                                    TextSpan(text: 'اكتب كلمة '),
                                    TextSpan(
                                      text: 'حذف',
                                      style: TextStyle(
                                        color: _kDangerRed,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' هنا لتاكيد العملية'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: provider.inputController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'حذف',
                                  hintStyle: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.25)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(
                                        color: _kDangerRed, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Bottom actions ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Consumer<ConfirmDeleteProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            children: [
                              // Red delete button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: provider.isDeleteEnabled
                                      ? () async {
                                          // Call delete API
                                          final dataProv =
                                              Provider.of<ChildDataProvider>(
                                                  context,
                                                  listen: false);
                                          final (success, message) =
                                              await dataProv.deleteChild(
                                                  childId: childId);
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(message,
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            _kFontFamily)),
                                                backgroundColor:
                                                    const Color(0xFF01A449),
                                              ),
                                            );
                                            Navigator.of(context)
                                                .pushNamedAndRemoveUntil(
                                                    '/family',
                                                    (route) => false);
                                          } else if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(message,
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            _kFontFamily)),
                                                backgroundColor: _kDangerRed,
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kDangerRed,
                                    disabledBackgroundColor:
                                        _kDangerRed.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'حذف ملف $childName',
                                    style: const TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Skip / Cancel button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.black.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  child: Text(
                                    'الغاء',
                                    style: const TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: _kTextBlack,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Footer link text
                              RichText(
                                textDirection: TextDirection.rtl,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: _kTextBlack,
                                  ),
                                  children: [
                                    TextSpan(text: 'تواجه مشكلة ما؟  '),
                                    TextSpan(
                                      text: 'تواصل معنا',
                                      style: TextStyle(
                                        color: _kDangerRed,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
