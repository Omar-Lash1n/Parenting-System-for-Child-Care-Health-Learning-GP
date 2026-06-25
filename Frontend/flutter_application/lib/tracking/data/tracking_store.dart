import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracker_device.dart';

/// Local persistence for the prototype device config.
/// All live data comes from flespi; only UI prefs and device list live here.
class TrackingStore {
  static const _kDevices = 'tk_devices';
  static const _kGpsEnabled = 'tk_gps_enabled';
  static const _kIntervalSec = 'tk_interval_sec';
  static const _kIsActive = 'tk_is_active';
  static const _kLiveFollow = 'tk_live_follow';
  static const _kGeoLat = 'tk_geo_lat';
  static const _kGeoLng = 'tk_geo_lng';
  static const _kGeoRadius = 'tk_geo_radius';
  static const _kGeoEnabled = 'tk_geo_enabled';
  static const _kGeoHasCenter = 'tk_geo_has_center';
  static const _kLocationUpdateSec = 'tk_location_update_sec';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Per-user device key ───────────────────────────────────────────────────

  Future<String> get _devicesKey async {
    final uid = (await _prefs).getString('ajial_parent_id') ?? 'guest';
    return '${_kDevices}_$uid';
  }

  // ── Device list ───────────────────────────────────────────────────────────

  Future<List<TrackerDevice>> getDevices() async {
    final key = await _devicesKey;
    final raw = (await _prefs).getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TrackerDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDevices(List<TrackerDevice> devices) async {
    final key = await _devicesKey;
    await (await _prefs).setString(
      key,
      jsonEncode(devices.map((d) => d.toJson()).toList()),
    );
  }

  // ── GPS enabled ──────────────────────────────────────────────────────────

  Future<bool> getGpsEnabled() async => (await _prefs).getBool(_kGpsEnabled) ?? false;

  Future<void> setGpsEnabled(bool value) async =>
      (await _prefs).setBool(_kGpsEnabled, value);

  // ── GPS report interval (seconds) ────────────────────────────────────────

  Future<int> getIntervalSeconds() async =>
      (await _prefs).getInt(_kIntervalSec) ?? 900;

  Future<void> setIntervalSeconds(int value) async =>
      (await _prefs).setInt(_kIntervalSec, value);

  // ── Tracking active ───────────────────────────────────────────────────────

  Future<bool> getIsActive() async => (await _prefs).getBool(_kIsActive) ?? false;

  Future<void> setIsActive(bool value) async =>
      (await _prefs).setBool(_kIsActive, value);

  // ── Live follow ───────────────────────────────────────────────────────────

  Future<bool> getLiveFollow() async =>
      (await _prefs).getBool(_kLiveFollow) ?? true;

  Future<void> setLiveFollow(bool value) async =>
      (await _prefs).setBool(_kLiveFollow, value);

  // ── Geofence center ───────────────────────────────────────────────────────

  Future<bool> getGeofenceHasCenter() async =>
      (await _prefs).getBool(_kGeoHasCenter) ?? false;

  Future<double> getGeofenceLat() async =>
      (await _prefs).getDouble(_kGeoLat) ?? 0.0;

  Future<double> getGeofenceLng() async =>
      (await _prefs).getDouble(_kGeoLng) ?? 0.0;

  Future<void> setGeofenceCenter(double lat, double lng) async {
    final p = await _prefs;
    await p.setDouble(_kGeoLat, lat);
    await p.setDouble(_kGeoLng, lng);
    await p.setBool(_kGeoHasCenter, true);
  }

  // ── Geofence radius (meters) ──────────────────────────────────────────────

  Future<double> getGeofenceRadius() async =>
      (await _prefs).getDouble(_kGeoRadius) ?? 100.0;

  Future<void> setGeofenceRadius(double meters) async =>
      (await _prefs).setDouble(_kGeoRadius, meters);

  // ── Geofence enabled ──────────────────────────────────────────────────────

  Future<bool> getGeofenceEnabled() async =>
      (await _prefs).getBool(_kGeoEnabled) ?? false;

  Future<void> setGeofenceEnabled(bool value) async =>
      (await _prefs).setBool(_kGeoEnabled, value);

  // ── Location update rate (seconds between device GPS fixes) ───────────────

  Future<int> getLocationUpdateSeconds() async =>
      (await _prefs).getInt(_kLocationUpdateSec) ?? 10;

  Future<void> setLocationUpdateSeconds(int value) async =>
      (await _prefs).setInt(_kLocationUpdateSec, value);
}
