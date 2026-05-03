class CurrentVaccinationModel {
  final String id;
  final String title;
  final String description;
  final String? childId;
  final String? childName;
  final String? childPhotoUrl;
  final bool isCompleted;
  final DateTime? dueDate;

  const CurrentVaccinationModel({
    required this.id,
    required this.title,
    required this.description,
    this.childId,
    this.childName,
    this.childPhotoUrl,
    this.isCompleted = false,
    this.dueDate,
  });

  factory CurrentVaccinationModel.fromJson(Map<String, dynamic> json) {
    final child = _asMap(json['child']) ??
        _asMap(json['childDto']) ??
        _asMap(json['childInfo']);

    return CurrentVaccinationModel(
      id: _readString(json, const [
        'id',
        'vaccinationId',
        'milestoneId',
        'scheduleId',
      ]),
      title: _readString(json, const [
        'title',
        'name',
        'vaccinationTitle',
        'milestoneTitle',
        'ageLabel',
      ], fallback: 'تطعيم'),
      description: _readString(json, const [
        'description',
        'vaccines',
        'vaccineNames',
        'details',
        'subtitle',
      ]),
      childId: _readStringOrNull(json, const ['childId']) ??
          _readStringOrNull(child, const ['id', 'childId']),
      childName: _readStringOrNull(json, const ['childName', 'fullName']) ??
          _readStringOrNull(child, const ['fullName', 'name']),
      childPhotoUrl: _readStringOrNull(json, const [
            'childPhotoUrl',
            'childProfileImageUrl',
            'profileImageUrl',
            'photoUrl',
          ]) ??
          _readStringOrNull(child, const [
            'profileImageUrl',
            'photoUrl',
            'imageUrl',
          ]),
      isCompleted: json['isCompleted'] == true ||
          json['completed'] == true ||
          json['isTaken'] == true,
      dueDate: _readDate(json, const [
        'dueDate',
        'appointmentDate',
        'scheduledDate',
        'date',
      ]),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _readString(
    Map<String, dynamic>? json,
    List<String> keys, {
    String fallback = '',
  }) {
    return _readStringOrNull(json, keys) ?? fallback;
  }

  static String? _readStringOrNull(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {}
    }
    return null;
  }
}
