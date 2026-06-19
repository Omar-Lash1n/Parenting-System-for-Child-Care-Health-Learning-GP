import 'dart:convert';

Map<String, dynamic> _extractObject(String responseBody) {
  final dynamic decoded = json.decode(responseBody);
  if (decoded is Map<String, dynamic>) {
    if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
      return decoded['data'];
    }
    return decoded;
  }
  return {};
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

void main() {
  final jsonStr = '''{
  "success": true,
  "message": "تم العثور على أقرب موعد",
  "data": {
    "found": true,
    "serviceType": "remote",
    "date": "2026-06-19",
    "startTime": "16:43",
    "endTime": "17:13",
    "workingHoursText": null
  },
  "errors": []
}''';
  final obj = _extractObject(jsonStr);
  final nearest = NearestSlot.fromJson(obj);
  print('found: \${nearest.found}, date: \${nearest.date}, start: \${nearest.startTime}');
}
