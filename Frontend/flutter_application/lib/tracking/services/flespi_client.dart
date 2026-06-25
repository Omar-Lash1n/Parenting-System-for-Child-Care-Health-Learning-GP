import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/tracking_data_source.dart';
import '../models/live_location.dart';
import '../tracking_config.dart';

class FlespiClient implements TrackingDataSource {
  static const _timeout = Duration(seconds: 10);

  Map<String, String> get _headers => {
        'Authorization': 'FlespiToken ${TrackingConfig.flespiToken}',
        'accept': 'application/json',
      };

  @override
  Future<LiveLocation?> getLatest() async {
    final uri = Uri.https(
      'flespi.io',
      '/gw/devices/${TrackingConfig.flespiDeviceId}/telemetry/all',
    );

    try {
      debugPrint('📤 Flespi GET $uri');
      final response =
          await http.get(uri, headers: _headers).timeout(_timeout);
      debugPrint('📥 Flespi ${response.statusCode}: ${response.body}');

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final result = decoded['result'];
      if (result is! List || result.isEmpty) return null;

      final telemetry = (result.first as Map<String, dynamic>)['telemetry']
          as Map<String, dynamic>?;
      if (telemetry == null) return null;

      return LiveLocation.fromTelemetry(telemetry);
    } catch (e) {
      debugPrint('❌ FlespiClient.getLatest error: $e');
      return null;
    }
  }
}
