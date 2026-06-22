// --- lib/child-app/home/draw_game_page.dart ---
// A kid-friendly "Draw the Letters" game (ارسم الحروف).
// Small kids trace / draw the Arabic alphabet letter by letter. Each letter
// is a "level": a faint guide letter sits behind a finger-drawing canvas,
// the child picks a crayon color and draws, then taps "تم" to celebrate
// (raining stars + sound) and move on to the next letter.
//
// Fully self-contained, mirroring memory_game_page.dart: the win is a local
// celebration only — it does NOT touch the global star counter (there is no
// game-reward endpoint). Sounds are delegated to the home provider.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';

// --- Constants (purple theme — matches the "ارسم" card on the home page) ---
const String _kFontFamily = 'IBM Plex Sans Arabic';
const Color _kBgColorTop = Color(0x80B0CEE3);
const Color _kBgColorBottom = Color(0x00B0CEE3);
const Color _kPurpleStart = Color(0xFFB99AF6);
const Color _kPurpleEnd = Color(0xFF7B78FB);
const Color _kPurpleDark = Color(0xFF5B57D6);
const Color _kOrangeStart = Color(0xFFFEA400);
const Color _kOrangeEnd = Color(0xFFFD5E00);
const Color _kOrangeBorder = Color(0xFFC84A00);

/// The three difficulty levels: trace single letters, then words, then short
/// sentences. Each level has its own content list.
enum _Mode { letters, words, sentences }

extension _ModeInfo on _Mode {
  String get chip => switch (this) {
        _Mode.letters => 'حروف',
        _Mode.words => 'كلمات',
        _Mode.sentences => 'جمل',
      };
  String get title => switch (this) {
        _Mode.letters => 'ارسم الحروف',
        _Mode.words => 'ارسم الكلمات',
        _Mode.sentences => 'ارسم الجمل',
      };
  String get unit => switch (this) {
        _Mode.letters => 'حرف',
        _Mode.words => 'كلمة',
        _Mode.sentences => 'جملة',
      };
  String get allDone => switch (this) {
        _Mode.letters => 'رسمت كل الحروف! أنت فنان 🌟',
        _Mode.words => 'رسمت كل الكلمات! أنت رائع 🌟',
        _Mode.sentences => 'رسمت كل الجمل! أنت بطل 🌟',
      };
}

/// One item to trace: the text itself + a chip caption + a decorative emoji.
class _DrawItem {
  final String text; // what the child traces (letter, word, or sentence)
  final String caption; // small caption shown under the canvas
  final String emoji;
  const _DrawItem(this.text, this.caption, this.emoji);
}

// Level 1 — the 28 Arabic letters. The example word + emoji are garnish.
const List<_DrawItem> _kLetterItems = [
  _DrawItem('ا', 'ا ـ أسد', '🦁'),
  _DrawItem('ب', 'ب ـ بطة', '🦆'),
  _DrawItem('ت', 'ت ـ تفاح', '🍎'),
  _DrawItem('ث', 'ث ـ ثعلب', '🦊'),
  _DrawItem('ج', 'ج ـ جمل', '🐫'),
  _DrawItem('ح', 'ح ـ حصان', '🐴'),
  _DrawItem('خ', 'خ ـ خروف', '🐑'),
  _DrawItem('د', 'د ـ دب', '🐻'),
  _DrawItem('ذ', 'ذ ـ ذرة', '🌽'),
  _DrawItem('ر', 'ر ـ ريشة', '🪶'),
  _DrawItem('ز', 'ز ـ زرافة', '🦒'),
  _DrawItem('س', 'س ـ سمكة', '🐟'),
  _DrawItem('ش', 'ش ـ شمس', '☀️'),
  _DrawItem('ص', 'ص ـ صقر', '🦅'),
  _DrawItem('ض', 'ض ـ ضفدع', '🐸'),
  _DrawItem('ط', 'ط ـ طائر', '🐦'),
  _DrawItem('ظ', 'ظ ـ ظبي', '🦌'),
  _DrawItem('ع', 'ع ـ عنب', '🍇'),
  _DrawItem('غ', 'غ ـ غيمة', '☁️'),
  _DrawItem('ف', 'ف ـ فيل', '🐘'),
  _DrawItem('ق', 'ق ـ قطة', '🐱'),
  _DrawItem('ك', 'ك ـ كلب', '🐶'),
  _DrawItem('ل', 'ل ـ ليمون', '🍋'),
  _DrawItem('م', 'م ـ موز', '🍌'),
  _DrawItem('ن', 'ن ـ نحلة', '🐝'),
  _DrawItem('ه', 'ه ـ هلال', '🌙'),
  _DrawItem('و', 'و ـ وردة', '🌹'),
  _DrawItem('ي', 'ي ـ يد', '✋'),
];

// Level 2 — simple, common words for small kids.
const List<_DrawItem> _kWordItems = [
  _DrawItem('ماما', 'ماما', '👩'),
  _DrawItem('بابا', 'بابا', '👨'),
  _DrawItem('ماء', 'ماء', '💧'),
  _DrawItem('قطة', 'قطة', '🐱'),
  _DrawItem('كلب', 'كلب', '🐶'),
  _DrawItem('شمس', 'شمس', '☀️'),
  _DrawItem('قمر', 'قمر', '🌙'),
  _DrawItem('وردة', 'وردة', '🌹'),
  _DrawItem('بيت', 'بيت', '🏠'),
  _DrawItem('موز', 'موز', '🍌'),
  _DrawItem('تفاح', 'تفاح', '🍎'),
  _DrawItem('سمك', 'سمك', '🐟'),
];

// Level 3 — short, easy sentences.
const List<_DrawItem> _kSentenceItems = [
  _DrawItem('أنا أحب أمي', 'أنا أحب أمي', '❤️'),
  _DrawItem('القطة تلعب', 'القطة تلعب', '🐱'),
  _DrawItem('الشمس مشرقة', 'الشمس مشرقة', '☀️'),
  _DrawItem('الجو جميل', 'الجو جميل', '🌤️'),
  _DrawItem('أنا ولد مطيع', 'أنا ولد مطيع', '🙂'),
  _DrawItem('أحب القراءة', 'أحب القراءة', '📖'),
];

const Map<_Mode, List<_DrawItem>> _kContent = {
  _Mode.letters: _kLetterItems,
  _Mode.words: _kWordItems,
  _Mode.sentences: _kSentenceItems,
};

// Bright crayon palette for the kids to pick from.
const List<Color> _kCrayons = [
  Color(0xFFE53935), // red
  Color(0xFFFB8C00), // orange
  Color(0xFFFDD835), // yellow
  Color(0xFF43A047), // green
  Color(0xFF1E88E5), // blue
  Color(0xFF8E24AA), // purple
  Color(0xFFEC407A), // pink
  Color(0xFF6D4C41), // brown
];

/// A single freehand stroke: the points the finger passed through, plus look.
class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke(this.color, this.width) : points = <Offset>[];
}

class DrawGamePage extends StatefulWidget {
  const DrawGamePage({super.key});

  @override
  State<DrawGamePage> createState() => _DrawGamePageState();
}

class _DrawGamePageState extends State<DrawGamePage>
    with TickerProviderStateMixin {
  _Mode _mode = _Mode.letters; // current difficulty level
  int _index = 0; // current item within the level
  bool _showGuide = true; // trace mode (guide on) vs. freehand (guide off)
  Color _color = _kCrayons.first;
  final double _width = 14;

  final List<_Stroke> _strokes = <_Stroke>[];
  _Stroke? _active; // stroke currently being drawn
  final Set<int> _completed = <int>{}; // items finished in the current level
  bool _showWin = false;

  Size? _canvasSize; // last measured drawing area (for shape validation)
  bool _checking = false; // guard against double taps while validating
  bool _showTryAgain = false; // gentle "try again" banner
  int _tryAgainToken = 0; // cancels stale banner auto-hides
  bool _welcomePlayed = false;

  ChildHomeProvider? _provider;

  late final AnimationController _introController; // canvas entrance
  late final AnimationController _pulseController; // breathing guide letter

  List<_DrawItem> get _items => _kContent[_mode]!;
  _DrawItem get _current => _items[_index];

  // Font size + wrapping width for the guide text — shared by the on-screen
  // guide AND the validation rasterizer so the mask lines up with what the
  // child sees. Bigger letters, smaller words, smallest sentences.
  double _fontSizeFor(Size s) => switch (_mode) {
        _Mode.letters => s.height * 0.70,
        _Mode.words => s.height * 0.30,
        _Mode.sentences => s.height * 0.15,
      };
  double _maxWidthFor(Size s) => switch (_mode) {
        _Mode.letters => s.width,
        _Mode.words => s.width * 0.90,
        _Mode.sentences => s.width * 0.90,
      };

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _provider = context.read<ChildHomeProvider>();
    } catch (_) {
      _provider = null;
    }

    if (!_welcomePlayed) {
      _welcomePlayed = true;
      _playSound('assets/sounds/WelcomeDrawGame.mp3');
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Sound helpers (delegate to the home provider's audio player) ---
  void _playClick() => _provider?.playClick();
  void _playSound(String path) => _provider?.playSound(path);

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _active = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _goToIndex(int index) {
    if (index < 0 || index >= _items.length) return;
    _playClick();
    setState(() {
      _index = index;
      _showWin = false;
      _strokes.clear();
      _active = null;
    });
    _introController
      ..reset()
      ..forward();
  }

  void _changeMode(_Mode mode) {
    if (_mode == mode) return;
    _playClick();
    setState(() {
      _mode = mode;
      _index = 0;
      _completed.clear();
      _showWin = false;
      _strokes.clear();
      _active = null;
    });
    _introController
      ..reset()
      ..forward();
  }

  Future<void> _onDone() async {
    if (_checking) return;
    // Nothing drawn yet — gently nudge instead of celebrating an empty page.
    if (_strokes.isEmpty) {
      _playSound('assets/sounds/TryAgain.mp3');
      _flashTryAgain();
      return;
    }

    setState(() => _checking = true);
    final correct = await _isDrawingCorrect();
    if (!mounted) return;
    setState(() => _checking = false);

    if (correct) {
      _playSound('assets/sounds/collect_stars.mp3');
      setState(() {
        _completed.add(_index);
        _showWin = true;
      });
    } else {
      // Drawing doesn't match the target → encourage another try.
      _playSound('assets/sounds/TryAgain.mp3');
      _flashTryAgain();
    }
  }

  // Briefly show the "try again" banner, auto-hiding after a moment.
  void _flashTryAgain() {
    final token = ++_tryAgainToken;
    setState(() => _showTryAgain = true);
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted || token != _tryAgainToken) return;
      setState(() => _showTryAgain = false);
    });
  }

  /// Decide whether the child's strokes resemble the target text.
  ///
  /// We rasterize the target (letter / word / sentence) to a pixel mask at the
  /// same size/position it is displayed, then check two things against the
  /// drawn strokes:
  ///  - accuracy: most of the drawing lands on (or near) the target shape, and
  ///  - coverage: enough of the target shape was actually drawn over.
  /// Random scribbles, the wrong text, or a tiny mark fail one of these.
  Future<bool> _isDrawingCorrect() async {
    final size = _canvasSize;
    if (size == null) return true; // can't measure → don't punish the child
    final w = size.width.floor();
    final h = size.height.floor();
    if (w <= 0 || h <= 0) return true;

    final fontSize = _fontSizeFor(size);
    final maxWidth = _maxWidthFor(size);
    final alpha = await _renderTextAlpha(_current.text, size, fontSize, maxWidth);
    if (alpha == null) return true;

    final r = fontSize * 0.14; // tolerance radius in pixels (kid-friendly)
    final cell = math.max(4.0, r / 2); // grid cell size
    final cols = (w / cell).ceil();
    final rows = (h / cell).ceil();
    final radCells = (r / cell).ceil();

    // Which grid cells belong to the letter glyph (opaque enough)?
    final glyph = <int>{};
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final px = (col * cell + cell / 2).floor().clamp(0, w - 1);
        final py = (row * cell + cell / 2).floor().clamp(0, h - 1);
        final a = alpha[(py * w + px) * 4 + 3];
        if (a > 40) glyph.add(row * cols + col);
      }
    }
    if (glyph.isEmpty) return true; // glyph failed to render → don't punish

    // Which grid cells did the finger pass through (densely sampled)?
    final samples = _samplePoints();
    if (samples.isEmpty) return false;
    final pointCells = <int>{};
    for (final p in samples) {
      final col = (p.dx / cell).floor();
      final row = (p.dy / cell).floor();
      if (col < 0 || col >= cols || row < 0 || row >= rows) continue;
      pointCells.add(row * cols + col);
    }
    if (pointCells.isEmpty) return false;

    bool nearIn(Set<int> setCells, int row, int col) {
      for (var dr = -radCells; dr <= radCells; dr++) {
        for (var dc = -radCells; dc <= radCells; dc++) {
          final rr = row + dr, cc = col + dc;
          if (rr < 0 || rr >= rows || cc < 0 || cc >= cols) continue;
          if (setCells.contains(rr * cols + cc)) return true;
        }
      }
      return false;
    }

    // accuracy: fraction of drawn cells that sit on/near the letter.
    var onTarget = 0;
    for (final pc in pointCells) {
      if (nearIn(glyph, pc ~/ cols, pc % cols)) onTarget++;
    }
    final accuracy = onTarget / pointCells.length;

    // coverage: fraction of the letter that has a stroke nearby.
    var covered = 0;
    for (final g in glyph) {
      if (nearIn(pointCells, g ~/ cols, g % cols)) covered++;
    }
    final coverage = covered / glyph.length;

    return accuracy >= 0.55 && coverage >= 0.40;
  }

  /// Rasterize the target text (centered & wrapped exactly as displayed) and
  /// return its raw RGBA bytes so we can read per-pixel alpha.
  Future<Uint8List?> _renderTextAlpha(
      String text, Size size, double fontSize, double maxWidth) async {
    final w = size.width.floor();
    final h = size.height.floor();
    if (w <= 0 || h <= 0) return null;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF000000),
        ),
      ),
      textAlign: TextAlign.center,
      textWidthBasis: TextWidthBasis.parent,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: maxWidth);

    final dx = (size.width - tp.width) / 2;
    final dy = (size.height - tp.height) / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    tp.paint(canvas, Offset(dx, dy));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return data?.buffer.asUint8List();
  }

  /// Flatten all strokes into densely-interpolated points so that fast finger
  /// moves (sparse raw points) don't leave gaps in the coverage check.
  List<Offset> _samplePoints() {
    const step = 4.0;
    final out = <Offset>[];
    for (final s in _strokes) {
      final p = s.points;
      if (p.isEmpty) continue;
      out.add(p.first);
      for (var i = 1; i < p.length; i++) {
        final a = p[i - 1], b = p[i];
        final d = (b - a).distance;
        if (d > step) {
          final n = (d / step).floor();
          for (var k = 1; k <= n; k++) {
            out.add(Offset.lerp(a, b, k / (n + 1))!);
          }
        }
        out.add(b);
      }
    }
    return out;
  }

  // --- Drawing gesture handlers ---
  void _onPanStart(DragStartDetails d) {
    final stroke = _Stroke(_color, _width)..points.add(d.localPosition);
    setState(() {
      _active = stroke;
      _strokes.add(stroke);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_active == null) return;
    setState(() => _active!.points.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    _active = null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildModeSelector(),
                  _buildToolbar(),
                  const SizedBox(height: 6),
                  Expanded(child: _buildCanvasArea()),
                  _buildLetterWordChip(),
                  const SizedBox(height: 8),
                  _buildCrayonPalette(),
                  const SizedBox(height: 8),
                  _buildBottomBar(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            _buildTryAgainBanner(),
            if (_showWin) ...[
              const _StarRain(),
              _buildWinDialog(),
            ],
          ],
        ),
      ),
    );
  }

  // --- "Try again" banner shown when the drawing doesn't match the letter ---
  Widget _buildTryAgainBanner() {
    return Positioned(
      top: 96,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showTryAgain ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kOrangeStart, _kOrangeEnd],
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _kOrangeBorder, width: 2),
                boxShadow: const [
                  BoxShadow(color: _kOrangeBorder, offset: Offset(2, 3)),
                ],
              ),
              child: const Text(
                'جرّب مرة أخرى ✏️',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Background ---
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kBgColorTop, _kBgColorBottom],
        ),
      ),
    );
  }

  // --- Header: back button + title + level counter ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PillButton(
            onTap: () {
              _playClick();
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: _kPurpleDark),
          ),
          Text(
            _mode.title,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kPurpleDark,
            ),
          ),
          // Level counter: how many items finished / total in this level.
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kPurpleStart, _kPurpleEnd],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _kPurpleDark, width: 2),
              boxShadow: const [
                BoxShadow(color: _kPurpleDark, offset: Offset(2, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_completed.length}/${_items.length}',
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                _starIcon(18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Level selector: حروف / كلمات / جمل ---
  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          _modeChip(_Mode.letters),
          const SizedBox(width: 8),
          _modeChip(_Mode.words),
          const SizedBox(width: 8),
          _modeChip(_Mode.sentences),
        ],
      ),
    );
  }

  Widget _modeChip(_Mode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kPurpleStart, _kPurpleEnd],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected ? _kPurpleDark : Colors.black26,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? _kPurpleDark : Colors.black12,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            mode.chip,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // --- Toolbar: prev / next item + guide toggle ---
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Previous item (in RTL the "back" arrow points right).
          _PillButton(
            onTap: () => _goToIndex(_index - 1),
            child: Icon(
              Icons.chevron_right,
              size: 26,
              color: _index > 0 ? _kPurpleDark : Colors.black26,
            ),
          ),
          const SizedBox(width: 8),
          // Next item.
          _PillButton(
            onTap: () => _goToIndex(_index + 1),
            child: Icon(
              Icons.chevron_left,
              size: 26,
              color:
                  _index < _items.length - 1 ? _kPurpleDark : Colors.black26,
            ),
          ),
          const Spacer(),
          // Guide on/off — this is the difficulty axis (trace vs. freehand).
          _PillButton(
            onTap: () {
              _playClick();
              setState(() => _showGuide = !_showGuide);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showGuide ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: _kPurpleDark,
                ),
                const SizedBox(width: 6),
                Text(
                  _showGuide ? 'تتبّع' : 'حر',
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPurpleDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- The drawing canvas (guide letter behind + finger strokes on top) ---
  Widget _buildCanvasArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _introController,
          curve: Curves.easeOutBack,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kPurpleStart, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kPurpleEnd.withAlpha(70),
                offset: const Offset(0, 6),
                blurRadius: 14,
              ),
            ],
          ),
          // Clip so strokes never paint outside the rounded card.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Cache the drawing area so validation rasterizes the guide at
                // exactly the same size/position the child sees it.
                final canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                _canvasSize = canvasSize;
                return Stack(
                  children: [
                    // Faint, breathing guide text behind the canvas.
                    if (_showGuide)
                      Positioned.fill(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final t = _pulseController.value;
                              return Transform.scale(
                                scale: 1.0 + t * 0.04,
                                child: child,
                              );
                            },
                            child: _GuideText(
                              text: _current.text,
                              fontSize: _fontSizeFor(canvasSize),
                              maxWidth: _maxWidthFor(canvasSize),
                            ),
                          ),
                        ),
                      ),
                    // Drawing surface. CustomPaint is the direct, same-sized
                    // child of the gesture detector so finger position and
                    // stroke position line up exactly (no padding between).
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _DrawPainter(List<_Stroke>.from(_strokes)),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    // Hint shown only on a blank canvas.
                    if (_strokes.isEmpty)
                      const Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Text(
                            'ارسم بإصبعك ✏️',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black26,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Little chip below the canvas: caption + emoji ---
  Widget _buildLetterWordChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _kPurpleStart, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _current.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kPurpleDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_current.emoji, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  // --- Crayon color palette ---
  Widget _buildCrayonPalette() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kCrayons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = _kCrayons[i];
          final selected = c == _color;
          return GestureDetector(
            onTap: () {
              _playClick();
              setState(() => _color = c);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 44 : 38,
              height: selected ? 44 : 38,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white70,
                  width: selected ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected ? c.withAlpha(160) : Colors.black26,
                    offset: const Offset(0, 3),
                    blurRadius: selected ? 8 : 4,
                  ),
                ],
              ),
              child: selected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  // --- Bottom bar: undo, clear, and the big "تم" done button ---
  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _PillButton(
            onTap: () {
              _playClick();
              _undo();
            },
            child: const Icon(Icons.undo, size: 22, color: _kPurpleDark),
          ),
          const SizedBox(width: 10),
          _PillButton(
            onTap: () {
              _playClick();
              _clearCanvas();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, size: 22, color: _kPurpleDark),
                SizedBox(width: 6),
                Text(
                  'مسح',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPurpleDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _onDone(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kPurpleStart, _kPurpleEnd],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: _kPurpleDark, offset: Offset(3, 5)),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'تم! 🎉',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Win dialog ---
  Widget _buildWinDialog() {
    final isLast = _index >= _items.length - 1;
    return Container(
      color: const Color(0x66000000),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 290,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 25),
                BoxShadow(color: _kPurpleEnd, offset: Offset(3, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _starIcon(48),
                    _starIcon(64),
                    _starIcon(48),
                  ],
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kPurpleStart, _kPurpleEnd],
                  ).createShader(bounds),
                  child: const Text(
                    'أحسنت! 🎉',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLast
                      ? _mode.allDone
                      : 'رسمت ${_mode.unit} "${_current.text}" بشكل رائع',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 22),
                // Next item (hidden on the last one in the level).
                if (!isLast)
                  _BigButton(
                    label: 'التالي',
                    gradient: const [_kPurpleStart, _kPurpleEnd],
                    shadow: _kPurpleDark,
                    onTap: () => _goToIndex(_index + 1),
                  ),
                if (!isLast) const SizedBox(height: 12),
                // Draw this one again.
                _BigButton(
                  label: 'ارسم مرة أخرى',
                  gradient: const [_kOrangeStart, _kOrangeEnd],
                  shadow: _kOrangeBorder,
                  onTap: () {
                    _playClick();
                    setState(() {
                      _showWin = false;
                      _strokes.clear();
                      _active = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Back to home.
                _BigButton(
                  label: 'الرجوع',
                  gradient: const [Color(0xFF90A4AE), Color(0xFF607D8B)],
                  shadow: const Color(0xFF455A64),
                  onTap: () {
                    _playClick();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _starIcon(double size) {
    return Image.asset(
      'images/stars.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.star, size: size, color: Colors.amber),
    );
  }
}

// ============================================================
//  Guide text: a faint, outlined letter / word / sentence to trace.
//  Two stacked Texts — one faint fill, one outline stroke. Each Text sets
//  EITHER color OR foreground (never both) to avoid the framework assertion.
//  Both are boxed to `maxWidth` and center-aligned so they wrap & position
//  identically to the validation rasterizer (which uses the same maxWidth).
// ============================================================
class _GuideText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double maxWidth;
  const _GuideText({
    required this.text,
    required this.fontSize,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint fill.
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _kPurpleStart.withAlpha(45),
            ),
          ),
          // Outline stroke.
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..color = _kPurpleEnd.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Painter that renders all the finger strokes.
// ============================================================
class _DrawPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final pts = stroke.points;
      if (pts.isEmpty) continue;
      if (pts.length == 1) {
        // A single tap → draw a dot.
        canvas.drawCircle(
          pts.first,
          stroke.width / 2,
          Paint()..color = stroke.color,
        );
        continue;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawPainter oldDelegate) => true;
}

// ============================================================
//  Raining stars celebration overlay.
// ============================================================
class _StarRain extends StatefulWidget {
  const _StarRain();

  @override
  State<_StarRain> createState() => _StarRainState();
}

class _StarRainState extends State<_StarRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(22, (i) {
      return _Particle(
        x: _rand.nextDouble(),
        delay: _rand.nextDouble() * 0.6,
        speed: 0.6 + _rand.nextDouble() * 0.7,
        size: 18 + _rand.nextDouble() * 26,
        rotationSpeed: (_rand.nextDouble() - 0.5) * 6,
        drift: (_rand.nextDouble() - 0.5) * 0.15,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: _particles.map((p) {
              final t = ((_controller.value - p.delay) * p.speed) % 1.0;
              if (t < 0) return const SizedBox.shrink();
              final top = t * (size.height + 80) - 60;
              final left = (p.x + p.drift * t) * size.width;
              return Positioned(
                top: top,
                left: left,
                child: Transform.rotate(
                  angle: t * p.rotationSpeed,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Image.asset(
                      'images/stars.png',
                      width: p.size,
                      height: p.size,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.star,
                        size: p.size,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x; // 0..1 horizontal start
  final double delay; // 0..1 start offset
  final double speed;
  final double size;
  final double rotationSpeed;
  final double drift;
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.drift,
  });
}

// ============================================================
//  Small shared widgets.
// ============================================================
class _PillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PillButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black26, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(2, 2)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final Color shadow;
  final VoidCallback onTap;
  const _BigButton({
    required this.label,
    required this.gradient,
    required this.shadow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: shadow, offset: const Offset(3, 5)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
