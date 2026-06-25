import '../tracking_config.dart';

class TrackerDevice {
  final String id;
  final String label;
  final String sim;
  final String imei;
  final String devicePassword;
  final List<String> controlNumbers; // up to 3 parent phone numbers
  // Always bound to the one real flespi device for the defense prototype
  final String flespiDeviceId;
  final bool gpsEnabled;
  final int reportIntervalMinutes;
  final bool liveFollow;
  final int locationUpdateSeconds;
  final bool isActive;

  const TrackerDevice({
    required this.id,
    required this.label,
    this.sim = '',
    this.imei = '',
    this.devicePassword = '',
    this.controlNumbers = const [],
    this.flespiDeviceId = TrackingConfig.flespiDeviceId,
    this.gpsEnabled = true,
    this.reportIntervalMinutes = 1,
    this.liveFollow = true,
    this.locationUpdateSeconds = 5,
    this.isActive = true,
  });

  factory TrackerDevice.fromJson(Map<String, dynamic> json) {
    final rawNumbers = json['controlNumbers'];
    final numbers = rawNumbers is List
        ? rawNumbers.map((e) => e?.toString() ?? '').toList()
        : <String>[];
    return TrackerDevice(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      sim: json['sim']?.toString() ?? '',
      imei: json['imei']?.toString() ?? '',
      devicePassword: json['devicePassword']?.toString() ?? '',
      controlNumbers: numbers,
      flespiDeviceId: json['flespiDeviceId']?.toString() ??
          TrackingConfig.flespiDeviceId,
      gpsEnabled: json['gpsEnabled'] as bool? ?? true,
      reportIntervalMinutes:
          (json['reportIntervalMinutes'] as num?)?.toInt() ?? 1,
      liveFollow: json['liveFollow'] as bool? ?? true,
      locationUpdateSeconds:
          (json['locationUpdateSeconds'] as num?)?.toInt() ?? 5,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'sim': sim,
        'imei': imei,
        'devicePassword': devicePassword,
        'controlNumbers': controlNumbers,
        'flespiDeviceId': flespiDeviceId,
        'gpsEnabled': gpsEnabled,
        'reportIntervalMinutes': reportIntervalMinutes,
        'liveFollow': liveFollow,
        'locationUpdateSeconds': locationUpdateSeconds,
        'isActive': isActive,
      };

  TrackerDevice copyWith({
    String? id,
    String? label,
    String? sim,
    String? imei,
    String? devicePassword,
    List<String>? controlNumbers,
    String? flespiDeviceId,
    bool? gpsEnabled,
    int? reportIntervalMinutes,
    bool? liveFollow,
    int? locationUpdateSeconds,
    bool? isActive,
  }) =>
      TrackerDevice(
        id: id ?? this.id,
        label: label ?? this.label,
        sim: sim ?? this.sim,
        imei: imei ?? this.imei,
        devicePassword: devicePassword ?? this.devicePassword,
        controlNumbers: controlNumbers ?? this.controlNumbers,
        flespiDeviceId: flespiDeviceId ?? this.flespiDeviceId,
        gpsEnabled: gpsEnabled ?? this.gpsEnabled,
        reportIntervalMinutes:
            reportIntervalMinutes ?? this.reportIntervalMinutes,
        liveFollow: liveFollow ?? this.liveFollow,
        locationUpdateSeconds:
            locationUpdateSeconds ?? this.locationUpdateSeconds,
        isActive: isActive ?? this.isActive,
      );
}
