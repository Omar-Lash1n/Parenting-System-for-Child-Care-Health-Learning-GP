import '../tracking_config.dart';

class LiveLocation {
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final bool positionValid;
  final int? batteryLevel;
  final int timestamp;
  final int serverTimestamp;
  final bool isOnline;

  const LiveLocation({
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    required this.positionValid,
    this.batteryLevel,
    required this.timestamp,
    required this.serverTimestamp,
    required this.isOnline,
  });

  // Flespi telemetry shadow: {"position.latitude":{"value":..,"ts":..}, ...}
  factory LiveLocation.fromTelemetry(Map<String, dynamic> telemetry) {
    num? tval(String key) {
      final entry = telemetry[key];
      if (entry is Map) return entry['value'] as num?;
      return null;
    }

    final lat = tval('position.latitude')?.toDouble();
    final lng = tval('position.longitude')?.toDouble();
    final speed = tval('position.speed')?.toDouble();
    final battery = tval('battery.level')?.toInt();

    // Prefer server.timestamp; fall back to max ts across all telemetry params.
    int serverTs = tval('server.timestamp')?.toInt() ?? 0;
    if (serverTs == 0) {
      for (final entry in telemetry.values) {
        if (entry is Map) {
          final ts = (entry['ts'] as num?)?.toInt() ?? 0;
          if (ts > serverTs) serverTs = ts;
        }
      }
    }

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final online =
        serverTs > 0 && (nowSec - serverTs) < TrackingConfig.offlineThresholdSeconds;

    return LiveLocation(
      latitude: lat ?? 0.0,
      longitude: lng ?? 0.0,
      speedKmh: speed,
      positionValid: lat != null && lng != null && !(lat == 0.0 && lng == 0.0),
      batteryLevel: battery,
      timestamp: serverTs,
      serverTimestamp: serverTs,
      isOnline: online,
    );
  }

  // Legacy factory kept for any existing test callers.
  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    final serverTs = (json['server.timestamp'] as num?)?.toInt() ?? 0;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final online =
        serverTs > 0 && (nowSec - serverTs) < TrackingConfig.offlineThresholdSeconds;
    final lat = (json['position.latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['position.longitude'] as num?)?.toDouble() ?? 0.0;

    return LiveLocation(
      latitude: lat,
      longitude: lng,
      speedKmh: (json['position.speed'] as num?)?.toDouble(),
      positionValid: lat != 0.0 || lng != 0.0,
      batteryLevel: (json['battery.level'] as num?)?.toInt(),
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      serverTimestamp: serverTs,
      isOnline: online,
    );
  }
}
