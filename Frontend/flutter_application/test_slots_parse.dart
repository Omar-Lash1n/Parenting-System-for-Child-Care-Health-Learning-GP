import 'dart:convert';

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

class DaySlotsResponse {
  final String serviceType;
  final String date;
  final List<TimeSlot> slots;
  final bool? isAvailable;
  final String? workingHoursText;

  DaySlotsResponse({
    required this.serviceType,
    required this.date,
    this.slots = const [],
    this.isAvailable,
    this.workingHoursText,
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
    );
  }
}

void main() {
  final jsonString = '''{
  "success": true,
  "message": "تم جلب المواعيد بنجاح",
  "data": {
    "date": "2026-06-19",
    "serviceType": "remote",
    "isAvailable": true,
    "slots": [
      {
        "startTime": "16:43",
        "endTime": "17:13",
        "isBooked": false
      }
    ],
    "workingPeriods": [],
    "workingHoursText": ""
  },
  "errors": []
}''';

  try {
    final decoded = json.decode(jsonString);
    final data = decoded['data'];
    final resp = DaySlotsResponse.fromJson(data);
    print('✅ Parsed! Slots length: ${resp.slots.length}');
    if (resp.slots.isNotEmpty) {
      print('First slot: ${resp.slots[0].startTime}');
    }
  } catch (e, st) {
    print('❌ Error: $e');
    print(st);
  }
}
