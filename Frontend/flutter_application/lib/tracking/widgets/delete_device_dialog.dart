import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

/// Frame 163 — confirmation before permanently removing a saved device.
Future<void> showDeleteDeviceDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close X
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Trash icon in pink circle
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: _kPinkLight, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline,
                    color: _kRed, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'حذف قطعة التتبع؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: _kFont,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم حذف القطعة نهائيا ولن يتم استعادة البيانات مرة اخرى',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontFamily: _kFont,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'لا, ابقاء',
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onConfirm();
                        },
                        child: const Text(
                          'نعم, حذف',
                          style: TextStyle(
                            fontFamily: _kFont,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
