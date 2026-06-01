// --- lib/child-app/home/math_game_page.dart ---
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

const String _kFontFamily = 'IBM Plex Sans Arabic';
const String _kGameUrl =
    'https://fahdzer0.github.io/Math-Adventure-Demo/export/game.html';

class MathGamePage extends StatefulWidget {
  const MathGamePage({super.key});

  @override
  State<MathGamePage> createState() => _MathGamePageState();
}

class _MathGamePageState extends State<MathGamePage> {
  bool _isLoading = true;
  bool _hasError = false;
  late final String _viewType;
  web.HTMLIFrameElement? _iframeElement;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _viewType = 'math-game-iframe-${DateTime.now().millisecondsSinceEpoch}';
      _iframeElement = web.HTMLIFrameElement()
        ..src = _kGameUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay; fullscreen'
        ..setAttribute('allowfullscreen', 'true');

      _iframeElement!.onLoad.listen((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });

      _iframeElement!.onError.listen((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      });

      // Register the view factory
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _iframeElement!,
      );

      // Auto-hide loading after timeout (iframe onLoad may not always fire)
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  void _reloadGame() {
    if (kIsWeb && _iframeElement != null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      _iframeElement!.src = _kGameUrl;
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1b1f26),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'مغامرة الأرقام',
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            // Reload button
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _reloadGame,
              tooltip: 'إعادة تحميل',
            ),
          ],
        ),
        body: kIsWeb ? _buildWebBody() : _buildUnsupportedBody(),
      ),
    );
  }

  Widget _buildWebBody() {
    return Stack(
      children: [
        // IFrame
        HtmlElementView(viewType: _viewType),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF11C2F4)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'جاري تحميل اللعبة...',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error state
        if (_hasError && !_isLoading)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Color(0xFF11C2F4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذر تحميل اللعبة',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تأكد من اتصالك بالإنترنت',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      color: Color(0xAAFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _reloadGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11C2F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnsupportedBody() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Color(0xFF11C2F4),
          ),
          SizedBox(height: 16),
          Text(
            'اللعبة متاحة فقط على نسخة الويب',
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
