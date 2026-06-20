import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class AvailableDoctor {
  final String id;
  final String fullName;
  final String specialization;
  final String? profileImageUrl;
  final bool hasClinic;
  final bool hasRemote;
  final double? remoteSessionPrice;
  final double? clinicExaminationPrice;

  AvailableDoctor({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.profileImageUrl,
    required this.hasClinic,
    required this.hasRemote,
    this.remoteSessionPrice,
    this.clinicExaminationPrice,
  });

  factory AvailableDoctor.fromJson(Map<String, dynamic> json) {
    return AvailableDoctor(
      id: json['specialistId']?.toString() ?? json['doctorId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['doctorName']?.toString() ?? json['fullName']?.toString() ?? 'طبيب',
      specialization: json['specialization']?.toString() ?? '',
      profileImageUrl: json['photoUrl']?.toString() ?? json['profileImageUrl']?.toString(),
      hasClinic: json['hasClinic'] ?? false,
      hasRemote: json['hasRemote'] ?? false,
      remoteSessionPrice: (json['remoteSessionPrice'] as num?)?.toDouble(),
      clinicExaminationPrice: (json['clinicExaminationPrice'] as num?)?.toDouble(),
    );
  }
}

class SpecialtyChip {
  final String name;

  SpecialtyChip({required this.name});

  factory SpecialtyChip.fromJson(Map<String, dynamic> json) {
    return SpecialtyChip(
      name: json['name']?.toString() ?? '',
    );
  }
}

class ParentConsultationService {
  static const String _apiBaseUrl =
      "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api";

  final AuthService _authService = AuthService();

  /// Helper to build headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No auth token found. Please login first.');
    
    print('🔑 Token found: ${token.substring(0, 20)}...');
    return {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    };
  }

  /// Helper to extract data from API response (handles both wrapped and raw responses)
  List<dynamic> _extractList(String responseBody) {
    if (responseBody.trim().isEmpty) return [];
    final dynamic decoded = json.decode(responseBody);
    
    if (decoded is List) {
      return decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Try common wrapper keys
      if (decoded['data'] is List) return decoded['data'];
      if (decoded['result'] is List) return decoded['result'];
      if (decoded['items'] is List) return decoded['items'];
      if (decoded['specialties'] is List) return decoded['specialties'];
      
      // Fallback: look for any list in the map
      for (var value in decoded.values) {
        if (value is List) return value;
      }
      return [];
    }
    return [];
  }

  Future<List<SpecialtyChip>> getSpecialties() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/specialties';
    
    print('📤 GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('📥 Specialties Response: ${response.statusCode}');
      print('📥 Specialties Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractList(response.body);
        return data.map((item) {
          if (item is String) {
            return SpecialtyChip(name: item);
          } else if (item is Map<String, dynamic>) {
            return SpecialtyChip.fromJson(item);
          }
          return SpecialtyChip(name: item.toString());
        }).toList();
      } else {
        print('❌ Error getting specialties: ${response.statusCode} - ${response.body}');
        return []; // Fallback to empty list instead of throwing to prevent breaking the screen
      }
    } catch (e) {
      print('❌ Exception in getSpecialties: $e');
      return []; // Fallback
    }
  }

  Future<List<AvailableDoctor>> getDoctors({String? search, String? specialty}) async {
    final headers = await _getAuthHeaders();
    
    // Build URL with query parameters manually to avoid issues with empty map
    String url = '$_apiBaseUrl/parent/consultations/doctors';
    final List<String> params = [];
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (specialty != null && specialty.isNotEmpty && specialty != 'الكل') {
      params.add('specialty=${Uri.encodeComponent(specialty)}');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    print('📤 GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('📥 Doctors Response: ${response.statusCode}');
      print('📥 Doctors Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractList(response.body);
        return data
            .map((item) => AvailableDoctor.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ Error getting doctors: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load doctors (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getDoctors: $e');
      rethrow;
    }
  }

  /// Helper to extract a single object from API response
  Map<String, dynamic> _extractObject(String responseBody) {
    final dynamic decoded = json.decode(responseBody);
    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        final msg = decoded['message'] ?? 'API Error';
        throw Exception(msg);
      }
      if (decoded.containsKey('data') && decoded['data'] != null && decoded['data'] is Map<String, dynamic>) {
        return decoded['data'];
      }
      return decoded;
    }
    return {};
  }

  /// GET /api/parent/consultations/doctors/{specialistId}
  Future<DoctorProfile> getDoctorProfile(String specialistId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/doctors/$specialistId';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 DoctorProfile Response: ${response.statusCode}');
      print('📥 DoctorProfile Body: ${response.body}');

      if (response.statusCode == 200) {
        return DoctorProfile.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load doctor profile (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getDoctorProfile: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/doctors/{specialistId}/booking-info
  Future<BookingInfo> getBookingInfo(String specialistId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/doctors/$specialistId/booking-info';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 BookingInfo Response: ${response.statusCode}');
      print('📥 BookingInfo Body: ${response.body}');

      if (response.statusCode == 200) {
        return BookingInfo.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load booking info (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getBookingInfo: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/doctors/{specialistId}/slots
  Future<DaySlotsResponse> getSlots(String specialistId, String serviceType, String date) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/doctors/$specialistId/slots'
        '?serviceType=${Uri.encodeComponent(serviceType)}&date=${Uri.encodeComponent(date)}';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 Slots Response: ${response.statusCode}');
      print('📥 Slots Body: ${response.body}');

      if (response.statusCode == 200) {
        return DaySlotsResponse.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load slots (${response.statusCode})\\nURL: $url\\nResponse: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in getSlots: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/doctors/{specialistId}/nearest-slot
  Future<NearestSlot?> getNearestSlot(String specialistId, String serviceType) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/doctors/$specialistId/nearest-slot'
        '?serviceType=${Uri.encodeComponent(serviceType)}';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 NearestSlot Response: ${response.statusCode}');
      print('📥 NearestSlot Body: ${response.body}');

      if (response.statusCode == 200) {
        return NearestSlot.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load nearest slot (${response.statusCode})\\nURL: $url\\nResponse: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in getNearestSlot: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/payment-methods
  Future<PaymentMethods?> getPaymentMethods() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/payment-methods';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = _extractObject(response.body);
        return PaymentMethods.fromJson(data);
      } else {
        throw Exception('Failed to load payment methods (${response.statusCode})\\n$url');
      }
    } catch (e) {
      print('❌ Exception in getPaymentMethods: $e');
      rethrow;
    }
  }

  /// POST /api/parent/consultations/bookings
  Future<String> createBooking({
    required String specialistId,
    required String serviceType,
    String? childId,
    required String slotDate,
    required String startTime,
    String? complaintDescription,
    bool shareMedicalFile = false,
  }) async {
    final token = await _authService.getToken();
    final url = '$_apiBaseUrl/parent/consultations/bookings';
    print('📤 POST $url');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['accept'] = 'application/json';

      request.fields['SpecialistId'] = specialistId;
      // The backend CreateBookingRequest expects an integer for ServiceType (1 = Clinic, 2 = RemoteConsultation)
      String serviceTypeValue = '1';
      final normalizedType = serviceType.trim().toLowerCase();
      if (normalizedType == 'remote' || normalizedType == 'remoteconsultation') {
        serviceTypeValue = '2';
      } else if (normalizedType == 'clinic') {
        serviceTypeValue = '1';
      } else {
        serviceTypeValue = serviceType; // Fallback in case it's already an integer string
      }
      request.fields['ServiceType'] = serviceTypeValue;
      
      if (childId != null) request.fields['ChildId'] = childId;
      request.fields['SlotDate'] = slotDate;
      request.fields['StartTime'] = startTime;
      if (complaintDescription != null && complaintDescription.isNotEmpty) {
        request.fields['ComplaintDescription'] = complaintDescription;
      }
      request.fields['ShareMedicalFile'] = shareMedicalFile.toString();

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Booking Response: ${response.statusCode}');
      print('📥 Booking Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to create booking');
        }
        // Extract bookingId from data
        final data = decoded['data'];
        if (data is String) {
          return data;
        } else if (data is Map && data.containsKey('bookingId')) {
          return data['bookingId'].toString();
        } else if (decoded.containsKey('bookingId')) {
          return decoded['bookingId'].toString();
        }
        return data?.toString() ?? '';
      } else {
        throw Exception('Failed to create booking (${response.statusCode})\n${response.body}');
      }
    } catch (e) {
      print('❌ Exception in createBooking: $e');
      rethrow;
    }
  }

  /// POST /api/parent/consultations/bookings/{bookingId}/payment
  Future<void> submitBookingPayment({
    required String bookingId,
    required int method, // 1 = VodafoneCash, 2 = InstaPay
    required XFile receiptFile,
  }) async {
    final token = await _authService.getToken();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/payment';
    print('📤 POST $url');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['Method'] = method.toString();

      final filename = receiptFile.name.isNotEmpty ? receiptFile.name : 'receipt.jpg';
      final ext = filename.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      final bytes = await receiptFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'Receipt',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Payment Response: ${response.statusCode}');
      print('📥 Payment Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to submit payment');
        }
      } else {
        throw Exception('Failed to submit payment (${response.statusCode})\n${response.body}');
      }
    } catch (e) {
      print('❌ Exception in submitBookingPayment: $e');
      rethrow;
    }
  }

  /// POST /api/parent/consultations/bookings/{bookingId}/attachments
  Future<void> uploadBookingAttachment(String bookingId, XFile attachmentFile) async {
    final token = await _authService.getToken();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/attachments';
    print('📤 POST $url');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      final filename = attachmentFile.name.isNotEmpty ? attachmentFile.name : 'receipt.jpg';
      final ext = filename.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      final bytes = await attachmentFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'File',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Upload Response: ${response.statusCode}');
      print('📥 Upload Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to upload attachment');
        }
      } else {
        throw Exception('Failed to upload attachment (${response.statusCode})\\n${response.body}');
      }
    } catch (e) {
      print('❌ Exception in uploadBookingAttachment: $e');
      rethrow;
    }
  }

  /// POST /api/parent/consultations/bookings/{bookingId}/cancel
  Future<void> cancelBooking(String bookingId) async {
    final token = await _authService.getToken();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/cancel';
    print('📤 POST $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📥 Cancel Response: ${response.statusCode}');
      print('📥 Cancel Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to cancel booking');
        }
      } else {
        throw Exception('Failed to cancel booking (${response.statusCode})\n${response.body}');
      }
    } catch (e) {
      print('❌ Exception in cancelBooking: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/bookings
  Future<List<Booking>> getBookings() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/bookings';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      
      print('📥 Bookings Response: ${response.statusCode}');
      print('📥 Bookings Body: ${response.body}');

      if (response.statusCode == 200) {
        final list = _extractList(response.body);
        return list.map((b) => Booking.fromJson(b as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load bookings (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getBookings: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/bookings/{bookingId}
  Future<Booking> getBookingDetail(String bookingId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      
      print('📥 Booking Detail Response: ${response.statusCode}');
      print('📥 Booking Detail Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractObject(response.body);
        return Booking.fromJson(data);
      } else {
        throw Exception('Failed to load booking details (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getBookingDetail: $e');
      rethrow;
    }
  }

  /// DELETE /api/parent/consultations/bookings/{bookingId}/attachments/{attachmentId}
  Future<void> deleteBookingAttachment(String bookingId, String attachmentId) async {
    final token = await _authService.getToken();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/attachments/$attachmentId';
    print('📤 DELETE $url');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📥 Delete Attachment Response: ${response.statusCode}');
      print('📥 Delete Attachment Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to delete attachment');
        }
      } else {
        throw Exception('Failed to delete attachment (${response.statusCode})\n${response.body}');
      }
    } catch (e) {
      print('❌ Exception in deleteBookingAttachment: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/payments
  Future<List<PaymentTransaction>> getPaymentTransactions() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/payments';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      print('📥 Payments Response: ${response.statusCode}');
      print('📥 Payments Body: ${response.body}');

      if (response.statusCode == 200) {
        final list = _extractList(response.body);
        return list
            .map((item) => PaymentTransaction.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load payments (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getPaymentTransactions: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/patients
  Future<List<Patient>> getPatients() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/patients';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 Patients Response: ${response.statusCode}');
      print('📥 Patients Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractList(response.body);
        return data
            .map((item) => Patient.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ Error getting patients: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load patients (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getPatients: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/bookings/{bookingId}/session
  /// Returns session status including canJoin and joinUrl (Google Meet link)
  Future<SessionStatus> getSessionStatus(String bookingId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/session';

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] as Map<String, dynamic>;
        return SessionStatus.fromJson(data);
      } else {
        throw Exception('Failed to get session status (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/parent/consultations/bookings/{bookingId}/prescription
  /// الروشتة الطبية التي سجّلها الطبيب لهذا الحجز (بطاقة عرض مكتفية بذاتها).
  Future<ParentPrescription> getPrescription(String bookingId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/prescription';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 Prescription Response: ${response.statusCode}');
      print('📥 Prescription Body: ${response.body}');

      if (response.statusCode == 200) {
        return ParentPrescription.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load prescription (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getPrescription: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/bookings/{bookingId}/rating
  /// حالة تقييم الجلسة (هل قُيّمت + هل يمكن تقييمها الان + تفاصيل التقييم).
  Future<SessionRatingStatus> getSessionRating(String bookingId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/rating';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 SessionRating Response: ${response.statusCode}');
      print('📥 SessionRating Body: ${response.body}');

      if (response.statusCode == 200) {
        return SessionRatingStatus.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load session rating (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getSessionRating: $e');
      rethrow;
    }
  }

  /// POST /api/parent/consultations/bookings/{bookingId}/rating
  /// إرسال تقييم الجلسة (الاستبيان) ومنح ولي الأمر 250 نجمة (مرة واحدة لكل حجز).
  Future<SessionRatingStatus> submitSessionRating({
    required String bookingId,
    required int rating,
    required bool wouldBookAgain,
    required bool hadIssue,
    String? issueDescription,
  }) async {
    final token = await _authService.getToken();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/rating';
    print('📤 POST $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: json.encode({
          'rating': rating,
          'wouldBookAgain': wouldBookAgain,
          'hadIssue': hadIssue,
          'issueDescription': issueDescription,
        }),
      ).timeout(const Duration(seconds: 20));

      print('📥 Submit Rating Response: ${response.statusCode}');
      print('📥 Submit Rating Body: ${response.body}');

      final dynamic decoded = json.decode(response.body);
      if (response.statusCode == 200) {
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to submit rating');
        }
        final data = decoded is Map && decoded['data'] is Map
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return SessionRatingStatus.fromJson(data);
      } else {
        final msg = decoded is Map ? (decoded['message']?.toString() ?? '') : '';
        throw Exception(msg.isNotEmpty ? msg : 'Failed to submit rating (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in submitSessionRating: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/problem-categories
  /// أنواع المشكلة الرئيسية لقائمة الاختيار في شاشة الإبلاغ.
  Future<List<ProblemCategory>> getProblemCategories() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/problem-categories';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 ProblemCategories Response: ${response.statusCode}');
      print('📥 ProblemCategories Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractList(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => ProblemCategory.fromJson(item))
            .toList();
      } else {
        print('❌ Error getting problem categories: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception in getProblemCategories: $e');
      return [];
    }
  }

  /// POST /api/parent/consultations/doctors/{specialistId}/problem-reports
  /// إرسال بلاغ عن مشكلة تخص طبيباً (نوع المشكلة + وصف اختياري + ربط اختياري بحجز).
  Future<void> submitProblemReport({
    required String specialistId,
    required int category,
    String? description,
    String? bookingId,
  }) async {
    final token = await _authService.getToken();
    final url =
        '$_apiBaseUrl/parent/consultations/doctors/$specialistId/problem-reports';
    print('📤 POST $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: json.encode({
          'category': category,
          'description': description,
          'bookingId': bookingId,
        }),
      ).timeout(const Duration(seconds: 20));

      print('📥 Submit ProblemReport Response: ${response.statusCode}');
      print('📥 Submit ProblemReport Body: ${response.body}');

      final dynamic decoded =
          response.body.trim().isEmpty ? null : json.decode(response.body);
      if (response.statusCode == 200) {
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to submit report');
        }
        return;
      } else {
        final msg = decoded is Map ? (decoded['message']?.toString() ?? '') : '';
        throw Exception(
            msg.isNotEmpty ? msg : 'Failed to submit report (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in submitProblemReport: $e');
      rethrow;
    }
  }

  /// GET /api/parent/consultations/bookings/{bookingId}/diagnosis
  /// التشخيص الطبي الذي سجّله الطبيب لهذا الحجز (بطاقة عرض مكتفية بذاتها).
  Future<ParentDiagnosis> getDiagnosis(String bookingId) async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/bookings/$bookingId/diagnosis';
    print('📤 GET $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      print('📥 Diagnosis Response: ${response.statusCode}');
      print('📥 Diagnosis Body: ${response.body}');

      if (response.statusCode == 200) {
        return ParentDiagnosis.fromJson(_extractObject(response.body));
      } else {
        throw Exception('Failed to load diagnosis (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getDiagnosis: $e');
      rethrow;
    }
  }
}


// ===== Additional Models =====

class DoctorProfile {
  final String id;
  final String fullName;
  final String specialization;
  final String? profileImageUrl;
  final String? clinicAddress;
  final String? clinicGovernorate;

  DoctorProfile({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.profileImageUrl,
    this.clinicAddress,
    this.clinicGovernorate,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['doctorName']?.toString() ?? json['fullName']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      profileImageUrl: json['photoUrl']?.toString() ?? json['profileImageUrl']?.toString(),
      clinicAddress: json['clinicAddress']?.toString(),
      clinicGovernorate: json['clinicGovernorate']?.toString(),
    );
  }
}

class BookingInfo {
  final ClinicInfo? clinic;
  final RemoteInfo? remote;

  BookingInfo({this.clinic, this.remote});

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      clinic: json['clinic'] != null ? ClinicInfo.fromJson(json['clinic']) : null,
      remote: json['remote'] != null ? RemoteInfo.fromJson(json['remote']) : null,
    );
  }
}

class ClinicInfo {
  final String? clinicId;
  final bool isAvailable;
  final double? examinationPrice;
  final double? consultationPrice;
  /// Raw JSON string: {"type":"fixed","from":"18:00","to":"23:56"}
  final String? workingHoursJson;
  /// Human-readable fallback (older API shape)
  final String? workingHoursText;
  final String? address;
  final String? governorateName;

  ClinicInfo({
    this.clinicId,
    required this.isAvailable,
    this.examinationPrice,
    this.consultationPrice,
    this.workingHoursJson,
    this.workingHoursText,
    this.address,
    this.governorateName,
  });

  /// Full address string, e.g. "السيل ش 12 - أسوان"
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (governorateName != null && governorateName!.isNotEmpty) parts.add(governorateName!);
    return parts.join(' - ');
  }

  /// Parses workingHoursJson to readable text.
  /// {"type":"fixed","from":"18:00","to":"23:56"} → "من 18:00 الى 23:56"
  String get workingHoursFormatted {
    // Prefer pre-formatted text
    if (workingHoursText != null && workingHoursText!.isNotEmpty) {
      return workingHoursText!;
    }
    if (workingHoursJson == null || workingHoursJson!.isEmpty) return 'غير متاح';
    try {
      final map = jsonDecode(workingHoursJson!) as Map<String, dynamic>;
      final from = map['from']?.toString() ?? '';
      final to   = map['to']?.toString() ?? '';
      if (from.isNotEmpty && to.isNotEmpty) return 'من $from الى $to';
    } catch (_) {}
    return workingHoursJson!;
  }

  factory ClinicInfo.fromJson(Map<String, dynamic> json) {
    return ClinicInfo(
      clinicId: json['clinicId']?.toString(),
      isAvailable: json['isAvailable'] ?? true,
      examinationPrice: (json['examinationPrice'] as num?)?.toDouble(),
      consultationPrice: (json['consultationPrice'] as num?)?.toDouble(),
      workingHoursJson: json['workingHoursJson']?.toString(),
      workingHoursText: json['workingHoursText']?.toString(),
      address: json['address']?.toString(),
      governorateName: json['governorateName']?.toString(),
    );
  }
}

class RemoteInfo {
  final bool isAvailable;
  final double? sessionPrice;
  final int? sessionDurationMinutes;
  final int? waitingPeriodMinutes;

  RemoteInfo({
    required this.isAvailable,
    this.sessionPrice,
    this.sessionDurationMinutes,
    this.waitingPeriodMinutes,
  });

  factory RemoteInfo.fromJson(Map<String, dynamic> json) {
    return RemoteInfo(
      isAvailable: json['isAvailable'] ?? false,
      sessionPrice: (json['sessionPrice'] as num?)?.toDouble(),
      sessionDurationMinutes: json['sessionDurationMinutes'] as int?,
      waitingPeriodMinutes: json['waitingPeriodMinutes'] as int?,
    );
  }
}

class DaySlotsResponse {
  final String serviceType;
  final String date;
  final List<TimeSlot> slots;
  final bool? isAvailable;
  final String? workingHoursText;
  final List<WorkingPeriod> workingPeriods;

  DaySlotsResponse({
    required this.serviceType,
    required this.date,
    this.slots = const [],
    this.isAvailable,
    this.workingHoursText,
    this.workingPeriods = const [],
  });

  factory DaySlotsResponse.fromJson(Map<String, dynamic> json) {
    return DaySlotsResponse(
      serviceType: json['serviceType']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      slots: json['slots'] != null
          ? (json['slots'] as List).map((s) => TimeSlot.fromJson(s)).toList()
          : [],
      isAvailable: json['isAvailable'] as bool?,
      workingHoursText: json['workingHoursText']?.toString(),
      workingPeriods: json['workingPeriods'] != null
          ? (json['workingPeriods'] as List).map((w) => WorkingPeriod.fromJson(w)).toList()
          : [],
    );
  }
}

class WorkingPeriod {
  final String from;
  final String to;

  WorkingPeriod({required this.from, required this.to});

  factory WorkingPeriod.fromJson(Map<String, dynamic> json) {
    return WorkingPeriod(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
    );
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isBooked;

  TimeSlot({required this.startTime, required this.endTime, required this.isBooked});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      isBooked: json['isBooked'] ?? false,
    );
  }
}

class NearestSlot {
  final bool found;
  final String? serviceType;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? workingHoursText;

  NearestSlot({
    required this.found,
    this.serviceType,
    required this.date,
    this.startTime,
    this.endTime,
    this.workingHoursText,
  });

  factory NearestSlot.fromJson(Map<String, dynamic> json) {
    return NearestSlot(
      found: json['found'] ?? false,
      serviceType: json['serviceType']?.toString(),
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      workingHoursText: json['workingHoursText']?.toString(),
    );
  }
}

class BookingAttachment {
  final String id;
  final String imageUrl;

  BookingAttachment({
    required this.id,
    required this.imageUrl,
  });

  factory BookingAttachment.fromJson(Map<String, dynamic> json) {
    return BookingAttachment(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

class Booking {
  final String bookingId;
  final String status;
  final String statusAr;
  final String serviceType;
  final String serviceTypeAr;
  final String specialistId;
  final String doctorName;
  final String photoUrl;
  final String specialization;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double price;
  final String patientName;
  final String createdAt;
  final bool canCancel;
  final List<BookingAttachment> attachments;
  final String? rejectionReason;
  // Fields added from detailed booking response
  final String? childId;
  final String? complaintDescription;
  final bool shareMedicalFile;
  final String? medicalFileUrl;
  final String? paymentStatus;
  final String? paymentStatusAr;
  final String? paymentMethod;
  final String? receiptImageUrl;
  // تقييم الجلسة (المرحلة الثامنة)
  final bool hasRated;
  final bool canRate;
  // إلغاء الحجز (المرحلة التاسعة)
  final int cancellationFeePercent;
  final double? cancellationFeeAmount;
  final double? refundAmount;
  final String? cancelledAt;

  Booking({
    required this.bookingId,
    required this.status,
    required this.statusAr,
    required this.serviceType,
    required this.serviceTypeAr,
    required this.specialistId,
    required this.doctorName,
    required this.photoUrl,
    required this.specialization,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.price,
    required this.patientName,
    required this.createdAt,
    required this.canCancel,
    required this.attachments,
    this.rejectionReason,
    this.childId,
    this.complaintDescription,
    this.shareMedicalFile = false,
    this.medicalFileUrl,
    this.paymentStatus,
    this.paymentStatusAr,
    this.paymentMethod,
    this.receiptImageUrl,
    this.hasRated = false,
    this.canRate = false,
    this.cancellationFeePercent = 10,
    this.cancellationFeeAmount,
    this.refundAmount,
    this.cancelledAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusAr: json['statusAr']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '',
      serviceTypeAr: json['serviceTypeAr']?.toString() ?? '',
      specialistId: json['specialistId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      appointmentDate: json['appointmentDate']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      patientName: json['patientName']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      canCancel: json['canCancel'] ?? false,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => BookingAttachment.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      rejectionReason: json['rejectionReason']?.toString(),
      childId: json['childId']?.toString(),
      complaintDescription: json['complaintDescription']?.toString(),
      shareMedicalFile: json['shareMedicalFile'] ?? false,
      medicalFileUrl: json['medicalFileUrl']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentStatusAr: json['paymentStatusAr']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      receiptImageUrl: json['receiptImageUrl']?.toString(),
      hasRated: json['hasRated'] ?? false,
      canRate: json['canRate'] ?? false,
      cancellationFeePercent: (json['cancellationFeePercent'] as num?)?.toInt() ?? 10,
      cancellationFeeAmount: (json['cancellationFeeAmount'] as num?)?.toDouble(),
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      cancelledAt: json['cancelledAt']?.toString(),
    );
  }
}

/// حالة تقييم الجلسة كما يعيدها الباك إند (status + تفاصيل + رصيد النجوم).
class SessionRatingStatus {
  final String bookingId;
  final bool hasRated;
  final bool canRate;
  final int? rating;
  final bool? wouldBookAgain;
  final bool? hadIssue;
  final String? issueDescription;
  final int starsAwarded;
  final int newStarsBalance;

  SessionRatingStatus({
    required this.bookingId,
    required this.hasRated,
    required this.canRate,
    this.rating,
    this.wouldBookAgain,
    this.hadIssue,
    this.issueDescription,
    required this.starsAwarded,
    required this.newStarsBalance,
  });

  factory SessionRatingStatus.fromJson(Map<String, dynamic> json) {
    return SessionRatingStatus(
      bookingId: json['bookingId']?.toString() ?? '',
      hasRated: json['hasRated'] ?? false,
      canRate: json['canRate'] ?? false,
      rating: json['rating'] as int?,
      wouldBookAgain: json['wouldBookAgain'] as bool?,
      hadIssue: json['hadIssue'] as bool?,
      issueDescription: json['issueDescription']?.toString(),
      starsAwarded: json['starsAwarded'] ?? 250,
      newStarsBalance: json['newStarsBalance'] ?? 0,
    );
  }
}

class ProblemCategory {
  final int value;
  final String key;
  final String labelAr;

  ProblemCategory({
    required this.value,
    required this.key,
    required this.labelAr,
  });

  factory ProblemCategory.fromJson(Map<String, dynamic> json) {
    return ProblemCategory(
      value: (json['value'] as num?)?.toInt() ?? 0,
      key: json['key']?.toString() ?? '',
      labelAr: json['labelAr']?.toString() ?? '',
    );
  }
}

class Patient {
  final String? childId;
  final String name;
  final String? imageUrl;
  final bool isSelf;

  Patient({
    this.childId,
    required this.name,
    this.imageUrl,
    required this.isSelf,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      childId: json['childId']?.toString(),
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      isSelf: json['isSelf'] ?? false,
    );
  }
}

class PaymentMethods {
  final String? vodafoneCashNumber;
  final String? instaPayNumber;

  PaymentMethods({
    this.vodafoneCashNumber,
    this.instaPayNumber,
  });

  factory PaymentMethods.fromJson(Map<String, dynamic> json) {
    return PaymentMethods(
      vodafoneCashNumber: json['vodafoneCashNumber']?.toString(),
      instaPayNumber: json['instaPayNumber']?.toString(),
    );
  }
}

class PaymentTransaction {
  final String paymentId;
  final String bookingId;
  final String doctorName;
  final String serviceTypeAr;
  final double amount;
  final String method;
  final String methodAr;
  final String status;
  final String statusAr;
  final String receiptImageUrl;
  final String appointmentDate;
  final String createdAt;
  final String? rejectionReason;

  PaymentTransaction({
    required this.paymentId,
    required this.bookingId,
    required this.doctorName,
    required this.serviceTypeAr,
    required this.amount,
    required this.method,
    required this.methodAr,
    required this.status,
    required this.statusAr,
    required this.receiptImageUrl,
    required this.appointmentDate,
    required this.createdAt,
    this.rejectionReason,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      paymentId: json['paymentId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      serviceTypeAr: json['serviceTypeAr']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method']?.toString() ?? '',
      methodAr: json['methodAr']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusAr: json['statusAr']?.toString() ?? '',
      receiptImageUrl: json['receiptImageUrl']?.toString() ?? '',
      appointmentDate: json['appointmentDate']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

// ── Session Status ─────────────────────────────────────────────────────────

class SessionStatus {
  final String bookingId;
  final bool canJoin;
  final String? joinUrl;
  final bool doctorStarted;
  final int secondsUntilStart;

  SessionStatus({
    required this.bookingId,
    required this.canJoin,
    this.joinUrl,
    required this.doctorStarted,
    required this.secondsUntilStart,
  });

  factory SessionStatus.fromJson(Map<String, dynamic> json) {
    return SessionStatus(
      bookingId: json['bookingId']?.toString() ?? '',
      canJoin: json['canJoin'] ?? false,
      joinUrl: json['joinUrl']?.toString(),
      doctorStarted: json['doctorStarted'] ?? false,
      secondsUntilStart: (json['secondsUntilStart'] as num?)?.toInt() ?? 0,
    );
  }
}

// ===== Clinical Record (parent read-only view) =====

/// دواء واحد ضمن الروشتة الطبية.
class PrescriptionMedicine {
  final String id;
  final String medicineName;
  final String quantity;
  final String timing;

  PrescriptionMedicine({
    required this.id,
    required this.medicineName,
    required this.quantity,
    required this.timing,
  });

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicine(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicineName']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
    );
  }
}

/// الترويسة المشتركة لبطاقات السجل الإكلينيكي (الطبيب + المريض + التاريخ).
class _ClinicalCardHeader {
  final String bookingId;
  final String doctorName;
  final String specialization;
  final String? doctorPhotoUrl;
  final String patientName;
  final int? patientAge;
  final String appointmentDate;
  final bool isCompleted;

  _ClinicalCardHeader({
    required this.bookingId,
    required this.doctorName,
    required this.specialization,
    required this.doctorPhotoUrl,
    required this.patientName,
    required this.patientAge,
    required this.appointmentDate,
    required this.isCompleted,
  });
}

/// الروشتة الطبية كما يراها ولي الأمر.
class ParentPrescription extends _ClinicalCardHeader {
  final List<PrescriptionMedicine> medicines;

  ParentPrescription({
    required super.bookingId,
    required super.doctorName,
    required super.specialization,
    required super.doctorPhotoUrl,
    required super.patientName,
    required super.patientAge,
    required super.appointmentDate,
    required super.isCompleted,
    required this.medicines,
  });

  bool get hasPrescription => medicines.isNotEmpty;

  factory ParentPrescription.fromJson(Map<String, dynamic> json) {
    return ParentPrescription(
      bookingId: json['bookingId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      doctorPhotoUrl: json['doctorPhotoUrl']?.toString(),
      patientName: json['patientName']?.toString() ?? '',
      patientAge: json['patientAge'] as int?,
      appointmentDate: json['appointmentDate']?.toString() ?? '',
      isCompleted: json['isCompleted'] ?? false,
      medicines: json['medicines'] != null
          ? (json['medicines'] as List)
              .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

/// التشخيص الطبي كما يراه ولي الأمر.
class ParentDiagnosis extends _ClinicalCardHeader {
  final bool hasDiagnosis;
  final String? description;

  ParentDiagnosis({
    required super.bookingId,
    required super.doctorName,
    required super.specialization,
    required super.doctorPhotoUrl,
    required super.patientName,
    required super.patientAge,
    required super.appointmentDate,
    required super.isCompleted,
    required this.hasDiagnosis,
    required this.description,
  });

  factory ParentDiagnosis.fromJson(Map<String, dynamic> json) {
    final diag = json['diagnosis'];
    return ParentDiagnosis(
      bookingId: json['bookingId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      doctorPhotoUrl: json['doctorPhotoUrl']?.toString(),
      patientName: json['patientName']?.toString() ?? '',
      patientAge: json['patientAge'] as int?,
      appointmentDate: json['appointmentDate']?.toString() ?? '',
      isCompleted: json['isCompleted'] ?? false,
      hasDiagnosis: json['hasDiagnosis'] ?? false,
      description: diag is Map<String, dynamic> ? diag['description']?.toString() : null,
    );
  }
}
