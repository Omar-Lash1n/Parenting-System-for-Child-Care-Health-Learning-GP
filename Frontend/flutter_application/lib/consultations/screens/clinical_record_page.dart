import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:Ajial/api/parent_consultation_service.dart';
import 'package:Ajial/consultations/widgets/clinical_record_paper.dart';

/// صفحة عرض السجل الإكلينيكي لولي الأمر (الروشتة الطبية أو التشخيص الطبي).
/// تعرض بطاقة الورقة الطبية ببيانات الطبيب الحقيقية، مع حفظها كـ PDF أو صورة.
class ClinicalRecordPage extends StatefulWidget {
  final String bookingId;
  final ClinicalRecordType type;

  const ClinicalRecordPage({
    super.key,
    required this.bookingId,
    required this.type,
  });

  @override
  State<ClinicalRecordPage> createState() => _ClinicalRecordPageState();
}

class _ClinicalRecordPageState extends State<ClinicalRecordPage> {
  final ParentConsultationService _api = ParentConsultationService();
  final GlobalKey _paperKey = GlobalKey();

  bool _loading = true;
  String? _error;
  bool _exporting = false;

  ParentPrescription? _prescription;
  ParentDiagnosis? _diagnosis;

  bool get _isPrescription => widget.type == ClinicalRecordType.prescription;

  String get _title => _isPrescription ? 'الروشتة الطبية' : 'التشخيص الطبي';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isPrescription) {
        final res = await _api.getPrescription(widget.bookingId);
        if (!mounted) return;
        setState(() {
          _prescription = res;
          _loading = false;
        });
      } else {
        final res = await _api.getDiagnosis(widget.bookingId);
        if (!mounted) return;
        setState(() {
          _diagnosis = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _loading = false;
      });
    }
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('SocketException') || text.contains('onnection') || text.contains('TimeoutException')) {
      return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
    }
    return text.isEmpty ? 'تعذر تحميل البيانات، حاول مرة أخرى' : text;
  }

  // ── التقاط البطاقة كصورة ──────────────────────────────────────────────────
  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _paperKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAsImage() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _capturePng();
      if (bytes == null) throw Exception('تعذر إنشاء الصورة');
      await Gal.putImageBytes(bytes, name: '${_isPrescription ? 'prescription' : 'diagnosis'}_${widget.bookingId}');
      _showSnack('تم حفظ الصورة في معرض الصور بنجاح');
    } catch (e) {
      _showSnack(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _saveAsPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _capturePng();
      if (bytes == null) throw Exception('تعذر إنشاء الملف');
      final doc = pw.Document();
      final img = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
        ),
      );
      final pdfBytes = await doc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${_isPrescription ? 'prescription' : 'diagnosis'}_${widget.bookingId}.pdf',
      );
    } catch (e) {
      _showSnack(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic', color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF01A449),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
              if (!_loading && _error == null) _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _title,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFBF092F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Color(0xFFBF092F), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFBF092F)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'IBM Plex Sans Arabic'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
            ),
          ],
        ),
      );
    }

    final header = _isPrescription ? _prescription : _diagnosis;
    if (header == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RepaintBoundary(
        key: _paperKey,
        child: ClinicalRecordPaper(
          type: widget.type,
          doctorName: header.doctorName,
          specialization: header.specialization,
          patientName: header.patientName,
          patientAge: header.patientAge,
          dateText: header.appointmentDate,
          medicines: _prescription?.medicines ?? const [],
          diagnosisText: _diagnosis?.description,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(child: _exportButton(label: 'تحميل كـ pdf', icon: Icons.description_outlined, onTap: _saveAsPdf)),
          const SizedBox(width: 12),
          Expanded(child: _exportButton(label: 'حفظ كـ صورة', icon: Icons.image_outlined, onTap: _saveAsImage)),
        ],
      ),
    );
  }

  Widget _exportButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _exporting ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
