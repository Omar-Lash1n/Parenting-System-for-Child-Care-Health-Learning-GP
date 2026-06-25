import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../data/tracking_data_source.dart';
import '../data/tracking_store.dart';
import '../models/geofence.dart';
import '../models/live_location.dart';
import '../models/tracker_device.dart';
import '../services/flespi_client.dart';
import '../services/geofence_notification.dart';
import '../tracking_config.dart';

class TrackingProvider extends ChangeNotifier {
  TrackingProvider({TrackingDataSource? dataSource, TrackingStore? store})
      : _source = dataSource ?? FlespiClient(),
        _store = store ?? TrackingStore() {
    _loadDeviceState();
  }

  final TrackingDataSource _source;
  final TrackingStore _store;

  // ── Live telemetry ────────────────────────────────────────────────────────

  LiveLocation? _location;
  LiveLocation? get location => _location;

  int _lastSeenServerTs = 0;

  bool get isOnline {
    if (_lastSeenServerTs == 0) return false;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (nowSec - _lastSeenServerTs) < TrackingConfig.offlineThresholdSeconds;
  }

  bool _isPolling = false;
  bool get isPolling => _isPolling;

  Timer? _timer;

  // ── Saved device list ────────────────────────────────────────────────────

  List<TrackerDevice> _devices = [];
  List<TrackerDevice> get devices => _devices;

  /// The prototype uses a single active device (first in list).
  TrackerDevice? get activeDevice => _devices.isEmpty ? null : _devices.first;

  /// Re-reads the device list from storage for the current user.
  /// Call this when the logged-in user may have changed since app start.
  Future<void> reloadDevices() async {
    _devices = await _store.getDevices();
    notifyListeners();
  }

  Future<void> addDevice(TrackerDevice device) async {
    _devices = [..._devices, device];
    await _store.saveDevices(_devices);
    notifyListeners();
  }

  Future<void> updateDevice(TrackerDevice device) async {
    _devices = _devices.map((d) => d.id == device.id ? device : d).toList();
    await _store.saveDevices(_devices);
    notifyListeners();
  }

  Future<void> deleteDevice(String id) async {
    _devices = _devices.where((d) => d.id != id).toList();
    await _store.saveDevices(_devices);
    notifyListeners();
  }

  // ── Persisted device config ───────────────────────────────────────────────

  bool _gpsEnabled = false;
  bool get gpsEnabled => _gpsEnabled;

  int _intervalSeconds = 900;
  int get intervalSeconds => _intervalSeconds;

  int _locationUpdateSeconds = 10;
  int get locationUpdateSeconds => _locationUpdateSeconds;

  bool _isActive = false;
  bool get isActive => _isActive;

  bool _liveFollow = true;
  bool get liveFollow => _liveFollow;

  // ── Geofence ──────────────────────────────────────────────────────────────

  Geofence _geofence = const Geofence(centerLat: 0, centerLng: 0);
  Geofence get geofence => _geofence;

  bool _geofenceCenterSet = false;
  bool get geofenceCenterSet => _geofenceCenterSet;

  bool _showBreachBanner = false;
  bool get showBreachBanner => _showBreachBanner;

  // Consumed (set false) by LiveMapScreen before showing the dialog,
  // so it fires once per breach event.
  bool _pendingBreachDialog = false;
  bool get pendingBreachDialog => _pendingBreachDialog;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> _loadDeviceState() async {
    _devices = await _store.getDevices();
    _gpsEnabled = await _store.getGpsEnabled();
    _intervalSeconds = await _store.getIntervalSeconds();
    _locationUpdateSeconds = await _store.getLocationUpdateSeconds();
    _isActive = await _store.getIsActive();
    _liveFollow = await _store.getLiveFollow();

    _geofenceCenterSet = await _store.getGeofenceHasCenter();
    _geofence = Geofence(
      centerLat: await _store.getGeofenceLat(),
      centerLng: await _store.getGeofenceLng(),
      radiusMeters: await _store.getGeofenceRadius(),
      isEnabled: await _store.getGeofenceEnabled(),
    );
    notifyListeners();
  }

  // ── Poll ─────────────────────────────────────────────────────────────────

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _fetchOnce();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchOnce());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  Future<void> _fetchOnce() async {
    final loc = await _source.getLatest();
    if (loc == null) return;

    // Every message updates the last-seen timestamp to drive isOnline.
    if (loc.serverTimestamp > 0) {
      _lastSeenServerTs = loc.serverTimestamp;
    }

    // Only update lat/lng and run geofence check when position is valid.
    final posGood = loc.positionValid &&
        !(loc.latitude == 0 && loc.longitude == 0);
    if (posGood) {
      _location = loc;
      _checkGeofence();
    }

    notifyListeners();
  }

  Future<void> refreshOnce() => _fetchOnce();

  // ── Geofence breach detection ─────────────────────────────────────────────

  void _checkGeofence() {
    final loc = _location;
    if (loc == null || !_geofence.isEnabled || !_geofenceCenterSet) return;

    final dist = _haversineMeters(
      loc.latitude, loc.longitude,
      _geofence.centerLat, _geofence.centerLng,
    );
    final nowInside = dist <= _geofence.radiusMeters;
    final newState = nowInside ? GeofenceState.inside : GeofenceState.outside;
    final prevState = _geofence.lastState;

    _geofence = _geofence.copyWith(lastState: newState);

    // Fire only on inside→outside transition
    if (prevState != GeofenceState.outside && newState == GeofenceState.outside) {
      _showBreachBanner = true;
      _pendingBreachDialog = true;
      GeofenceNotification.showBreach();
    }
  }

  static double _haversineMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lng2 - lng1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ── GPS toggle ────────────────────────────────────────────────────────────

  Future<void> toggleGps() async {
    _gpsEnabled = !_gpsEnabled;
    await _store.setGpsEnabled(_gpsEnabled);
    notifyListeners();
  }

  Future<void> setIntervalSeconds(int seconds) async {
    _intervalSeconds = seconds;
    await _store.setIntervalSeconds(seconds);
    notifyListeners();
  }

  Future<void> setLocationUpdateSeconds(int seconds) async {
    _locationUpdateSeconds = seconds;
    await _store.setLocationUpdateSeconds(seconds);
    notifyListeners();
  }

  Future<void> setActive(bool value) async {
    _isActive = value;
    await _store.setIsActive(value);
    notifyListeners();
  }

  Future<void> powerOff() async {
    _gpsEnabled = false;
    _isActive = false;
    _location = null;
    await _store.setGpsEnabled(false);
    await _store.setIsActive(false);
    notifyListeners();
  }

  Future<void> factoryReset() async {
    _gpsEnabled = false;
    _isActive = false;
    _intervalSeconds = 900;
    _locationUpdateSeconds = 10;
    _liveFollow = true;
    _location = null;
    _geofence = const Geofence(centerLat: 0, centerLng: 0);
    _geofenceCenterSet = false;
    await _store.setGpsEnabled(false);
    await _store.setIsActive(false);
    await _store.setIntervalSeconds(900);
    await _store.setLocationUpdateSeconds(10);
    await _store.setLiveFollow(true);
    await _store.setGeofenceEnabled(false);
    notifyListeners();
  }

  // ── Live follow ───────────────────────────────────────────────────────────

  Future<void> setLiveFollow(bool value) async {
    _liveFollow = value;
    await _store.setLiveFollow(value);
    notifyListeners();
  }

  // ── Geofence setters ─────────────────────────────────────────────────────

  Future<void> setGeofenceCenter(double lat, double lng) async {
    _geofenceCenterSet = true;
    _geofence = _geofence.copyWith(
      centerLat: lat,
      centerLng: lng,
      lastState: GeofenceState.unknown,
    );
    await _store.setGeofenceCenter(lat, lng);
    notifyListeners();
  }

  Future<void> setGeofenceRadius(double meters) async {
    _geofence = _geofence.copyWith(
      radiusMeters: meters,
      lastState: GeofenceState.unknown,
    );
    await _store.setGeofenceRadius(meters);
    notifyListeners();
  }

  Future<void> setGeofenceEnabled(bool value) async {
    _geofence = _geofence.copyWith(
      isEnabled: value,
      lastState: GeofenceState.unknown,
    );
    await _store.setGeofenceEnabled(value);
    notifyListeners();
  }

  // ── Breach UI state ───────────────────────────────────────────────────────

  void dismissBreachBanner() {
    _showBreachBanner = false;
    notifyListeners();
  }

  /// Called by LiveMapScreen before showing the dialog so it only fires once.
  void consumeBreachDialog() {
    _pendingBreachDialog = false;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
