enum GeofenceState { unknown, inside, outside }

class Geofence {
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final bool isEnabled;
  final GeofenceState lastState;

  const Geofence({
    required this.centerLat,
    required this.centerLng,
    this.radiusMeters = 200,
    this.isEnabled = false,
    this.lastState = GeofenceState.unknown,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      centerLat: (json['centerLat'] as num?)?.toDouble() ?? 0.0,
      centerLng: (json['centerLng'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200.0,
      isEnabled: json['isEnabled'] as bool? ?? false,
      lastState: GeofenceState.values.firstWhere(
        (s) => s.name == (json['lastState']?.toString() ?? ''),
        orElse: () => GeofenceState.unknown,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'centerLat': centerLat,
        'centerLng': centerLng,
        'radiusMeters': radiusMeters,
        'isEnabled': isEnabled,
        'lastState': lastState.name,
      };

  Geofence copyWith({
    double? centerLat,
    double? centerLng,
    double? radiusMeters,
    bool? isEnabled,
    GeofenceState? lastState,
  }) =>
      Geofence(
        centerLat: centerLat ?? this.centerLat,
        centerLng: centerLng ?? this.centerLng,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        isEnabled: isEnabled ?? this.isEnabled,
        lastState: lastState ?? this.lastState,
      );
}
