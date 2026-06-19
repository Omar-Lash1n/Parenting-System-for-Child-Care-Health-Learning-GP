// --- Models for Phase 4 Doctor-Side Remote Consultation API ---
// Base path: /api/doctor/consultations
// Follows the same JSON-reading conventions as clinic_remote_models.dart.

// ============================================================
// ==================== Slots =================================
// ============================================================

/// GET /api/doctor/consultations/slots — a single day's slots.
class DoctorSlotsResponse {
  final String date; // yyyy-MM-dd
  final bool isAvailable;
  final List<DoctorSlot> slots;

  const DoctorSlotsResponse({
    required this.date,
    required this.isAvailable,
    required this.slots,
  });

  factory DoctorSlotsResponse.fromJson(Map<String, dynamic> json) {
    final rawSlots = _read(json, 'slots');
    return DoctorSlotsResponse(
      date: _read(json, 'date').toString(),
      isAvailable: _read(json, 'isAvailable') == true,
      slots: rawSlots is List
          ? rawSlots
              .map((e) => DoctorSlot.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : <DoctorSlot>[],
    );
  }
}

/// A single appointment slot for the doctor's day.
class DoctorSlot {
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final bool isBooked;
  final String? bookingId;
  final String? patientName;
  final String? status;
  final String? statusAr;

  const DoctorSlot({
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.bookingId,
    this.patientName,
    this.status,
    this.statusAr,
  });

  /// "من 7 م الى 7:45 م"
  String get rangeText =>
      'من ${formatArabicTime(startTime)} الى ${formatArabicTime(endTime)}';

  bool get isCompleted => (status ?? '').toLowerCase() == 'completed';

  factory DoctorSlot.fromJson(Map<String, dynamic> json) {
    return DoctorSlot(
      startTime: _read(json, 'startTime').toString(),
      endTime: _read(json, 'endTime').toString(),
      isBooked: _read(json, 'isBooked') == true,
      bookingId: _nullableString(_read(json, 'bookingId')),
      patientName: _nullableString(_read(json, 'patientName')),
      status: _nullableString(_read(json, 'status')),
      statusAr: _nullableString(_read(json, 'statusAr')),
    );
  }
}

// ============================================================
// ==================== Calendar ==============================
// ============================================================

/// GET /api/doctor/consultations/calendar — booked dates in a month.
class DoctorCalendarResponse {
  final String month; // yyyy-MM
  final List<String> bookedDates; // yyyy-MM-dd

  const DoctorCalendarResponse({
    required this.month,
    required this.bookedDates,
  });

  factory DoctorCalendarResponse.fromJson(Map<String, dynamic> json) {
    final raw = _read(json, 'bookedDates');
    return DoctorCalendarResponse(
      month: _read(json, 'month').toString(),
      bookedDates: raw is List ? raw.map((e) => e.toString()).toList() : <String>[],
    );
  }
}

// ============================================================
// ==================== Booking detail ========================
// ============================================================

class DoctorBookingAttachment {
  final String id;
  final String imageUrl;

  const DoctorBookingAttachment({required this.id, required this.imageUrl});

  factory DoctorBookingAttachment.fromJson(Map<String, dynamic> json) {
    return DoctorBookingAttachment(
      id: _read(json, 'id').toString(),
      imageUrl: _read(json, 'imageUrl').toString(),
    );
  }
}

/// GET /api/doctor/consultations/bookings/{bookingId}
class DoctorBookingDetail {
  final String bookingId;
  final String status;
  final String statusAr;
  final String serviceType;
  final String serviceTypeAr;
  final String appointmentDate; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final int durationMinutes;
  final double price;
  final String? childId;
  final bool isChildPatient;
  final String patientName;
  final String? patientImageUrl;
  final int? patientAge;
  final String? patientGender;
  final String? complaintDescription;
  final List<DoctorBookingAttachment> attachments;
  final bool shareMedicalFile;
  final String? medicalFileUrl;
  final DoctorSessionStatus? session;

  const DoctorBookingDetail({
    required this.bookingId,
    required this.status,
    required this.statusAr,
    required this.serviceType,
    required this.serviceTypeAr,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.price,
    this.childId,
    required this.isChildPatient,
    required this.patientName,
    this.patientImageUrl,
    this.patientAge,
    this.patientGender,
    this.complaintDescription,
    required this.attachments,
    required this.shareMedicalFile,
    this.medicalFileUrl,
    this.session,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  /// "من 7 م الى 7:45 م"
  String get rangeText =>
      'من ${formatArabicTime(startTime)} الى ${formatArabicTime(endTime)}';

  factory DoctorBookingDetail.fromJson(Map<String, dynamic> json) {
    final rawAttachments = _read(json, 'attachments');
    final rawSession = json['session'] ?? json['Session'];
    return DoctorBookingDetail(
      bookingId: _read(json, 'bookingId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      serviceType: _read(json, 'serviceType').toString(),
      serviceTypeAr: _read(json, 'serviceTypeAr').toString(),
      appointmentDate: _read(json, 'appointmentDate').toString(),
      startTime: _read(json, 'startTime').toString(),
      endTime: _read(json, 'endTime').toString(),
      durationMinutes: _parseInt(_read(json, 'durationMinutes')) ?? 0,
      price: _parseDouble(_read(json, 'price')) ?? 0,
      childId: _nullableString(_read(json, 'childId')),
      isChildPatient: _read(json, 'isChildPatient') == true,
      patientName: _read(json, 'patientName').toString(),
      patientImageUrl: _nullableString(_read(json, 'patientImageUrl')),
      patientAge: _parseInt(_read(json, 'patientAge')),
      patientGender: _nullableString(_read(json, 'patientGender')),
      complaintDescription: _nullableString(_read(json, 'complaintDescription')),
      attachments: rawAttachments is List
          ? rawAttachments
              .map((e) => DoctorBookingAttachment.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : <DoctorBookingAttachment>[],
      shareMedicalFile: _read(json, 'shareMedicalFile') == true,
      medicalFileUrl: _nullableString(_read(json, 'medicalFileUrl')),
      session: rawSession is Map
          ? DoctorSessionStatus.fromJson(Map<String, dynamic>.from(rawSession))
          : null,
    );
  }
}

// ============================================================
// ==================== Session status ========================
// ============================================================

/// GET /api/doctor/consultations/bookings/{bookingId}/session
/// Also returned (after manual end) by the end-session endpoint.
class DoctorSessionStatus {
  final String bookingId;
  final String status;
  final String statusAr;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final DateTime? serverTimeEgypt;
  final int secondsUntilStart;
  final int secondsUntilEnd;
  final bool sessionStarted;
  final bool sessionEnded;
  final bool canStart;
  final bool canEnd;
  final String? joinUrl;

  const DoctorSessionStatus({
    required this.bookingId,
    required this.status,
    required this.statusAr,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.serverTimeEgypt,
    required this.secondsUntilStart,
    required this.secondsUntilEnd,
    required this.sessionStarted,
    required this.sessionEnded,
    required this.canStart,
    required this.canEnd,
    this.joinUrl,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory DoctorSessionStatus.fromJson(Map<String, dynamic> json) {
    return DoctorSessionStatus(
      bookingId: _read(json, 'bookingId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      appointmentDate: _read(json, 'appointmentDate').toString(),
      startTime: _read(json, 'startTime').toString(),
      endTime: _read(json, 'endTime').toString(),
      durationMinutes: _parseInt(_read(json, 'durationMinutes')) ?? 0,
      serverTimeEgypt: _parseDate(_read(json, 'serverTimeEgypt')),
      secondsUntilStart: _parseInt(_read(json, 'secondsUntilStart')) ?? 0,
      secondsUntilEnd: _parseInt(_read(json, 'secondsUntilEnd')) ?? 0,
      sessionStarted: _read(json, 'sessionStarted') == true,
      sessionEnded: _read(json, 'sessionEnded') == true,
      canStart: _read(json, 'canStart') == true,
      canEnd: _read(json, 'canEnd') == true,
      joinUrl: _nullableString(_read(json, 'joinUrl')),
    );
  }
}

/// POST /api/doctor/consultations/bookings/{bookingId}/start-session
class StartSessionResponse {
  final String bookingId;
  final String joinUrl;
  final DateTime? sessionStartedAt;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String patientName;

  const StartSessionResponse({
    required this.bookingId,
    required this.joinUrl,
    this.sessionStartedAt,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.patientName,
  });

  factory StartSessionResponse.fromJson(Map<String, dynamic> json) {
    return StartSessionResponse(
      bookingId: _read(json, 'bookingId').toString(),
      joinUrl: _read(json, 'joinUrl').toString(),
      sessionStartedAt: _parseDate(_read(json, 'sessionStartedAt')),
      appointmentDate: _read(json, 'appointmentDate').toString(),
      startTime: _read(json, 'startTime').toString(),
      endTime: _read(json, 'endTime').toString(),
      patientName: _read(json, 'patientName').toString(),
    );
  }
}

// ============================================================
// ==================== Helpers ===============================
// ============================================================

/// Formats a backend "HH:mm" time into Arabic 12-hour form,
/// e.g. "19:00" -> "7 م", "19:45" -> "7:45 م", "07:30" -> "7:30 ص".
String formatArabicTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return hhmm;
  final period = h >= 12 ? 'م' : 'ص';
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  final minutePart = m == 0 ? '' : ':${m.toString().padLeft(2, '0')}';
  return '$h12$minutePart $period';
}

dynamic _read(Map<String, dynamic> json, String key) {
  final pascal =
      key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  return json[key] ?? json[pascal] ?? '';
}

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

DateTime? _parseDate(dynamic value) {
  final text = _nullableString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  final text = _nullableString(value);
  if (text == null) return null;
  return int.tryParse(text);
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  final text = _nullableString(value);
  if (text == null) return null;
  return double.tryParse(text);
}
