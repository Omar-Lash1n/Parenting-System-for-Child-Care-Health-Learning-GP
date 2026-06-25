# Ajial — Child GPS Tracking Feature (Spec, client-direct edition)

> Supersedes the earlier .NET-backend version. Constraints: no .NET SDK available, no access to the
> shared database. So for the defense prototype there is **no backend server** — the Flutter app talks to
> flespi directly and persists locally. The UI/flow is unchanged; only the data layer differs, and it sits
> behind a `TrackingDataSource` interface so it can be ported to the .NET backend later with the UI untouched.
> Read alongside `CLAUDE_CODE_PLAYBOOK.md`.

---

## 0. Scope and intent

Parent-side child GPS tracking for the Ajial app, as a **graduation-defense prototype**. It must look
exactly like the Figma and demo as a working, real-data flow against **one real Qbit device already online
in flespi**. No multi-tenant provisioning.

**Hard rules**
- **No server.** Flutter calls flespi REST directly for live data and commands; persists device/geofence/
  settings locally via `shared_preferences`.
- New code lives in `lib/tracking/`, feature-first like `lib/tasks/` and `lib/consultations/`.
- RTL Arabic; reuse the existing theme/colors/widgets (the red/white system the designer used).
- Live reads (location, speed, battery, online) are **real** via flespi. Config commands are **real where
  the device supports them, otherwise simulated** (state still persists locally so the UI is correct).
- Keep the data layer behind a `TrackingDataSource` interface (flespi + local now; .NET later).

## 1. The hardcoded-prototype contract

Whatever IMEI / SIM / control numbers the parent types, the app **binds the chosen child to the one real
flespi device** from config. Multiple saved devices may all carry the same flespi device id — fine.

Config in a single Dart file `lib/tracking/tracking_config.dart` (do not commit a real token to a public
repo; use a restricted token — see playbook §1):
```dart
class TrackingConfig {
  static const flespiBaseUrl = 'https://flespi.io';
  static const flespiToken   = '<restricted-flespi-token>';
  static const flespiDeviceId = '<your-real-qbit-flespi-device-id>';
  static const offlineThresholdSeconds = 120; // no telemetry newer than this => offline ("--")
  static const breachPollSeconds = 10;         // client-side geofence check cadence while app is open
}
```

## 2. flespi integration (verified; called directly from Flutter)

Base `https://flespi.io`. Every request header: `Authorization: FlespiToken <token>`. No CORS on mobile.

**Live location + telemetry (primary read), latest message in one call:**
```
GET /gw/devices/{deviceId}/messages?data={"count":1,"reverse":true}
```
Returns `{ "result": [ { ...unified params... } ] }`. Parameters used: `position.latitude`,
`position.longitude`, `position.speed` (km/h), `position.valid`, `battery.level` (percent),
`timestamp` (device RTC s), `server.timestamp` (reception s).
**Online** = `now − server.timestamp < offlineThresholdSeconds`.

Alternative current-state read: `GET /gw/devices/{deviceId}/telemetry/position,battery.level`.

> Confirm the exact JSON envelope against the live device's flespi **APIbox / Logs&Messages** before
> parsing; map defensively with null fallbacks like the app's existing `fromJson` factories.

**Movement history (optional):** `GET /gw/devices/{deviceId}/messages?data={"count":100,"reverse":true}`.

**Config commands.** Discover support via the device `commands` field
(`GET /gw/devices/{deviceId}?fields=commands`). Send to the queue (works even if device offline):
`POST /gw/devices/{deviceId}/commands-queue`. SMS path `POST /gw/devices/{deviceId}/sms` only when the
device type defines SMS commands. If a command isn't supported, persist the new state locally and treat as
success.

## 3. Flutter data layer (replaces the backend)

`lib/tracking/` :

- **`tracking_config.dart`** — constants above.
- **`services/flespi_client.dart`** — direct flespi REST: `getLatest()` → `LiveLocation`,
  `getHistory(count)`, `sendCommand(name, args)` → bool, `getAvailableCommands()`. Uses `http` + the token
  header. Try/catch with graceful fallbacks.
- **`data/tracking_store.dart`** — local persistence via `shared_preferences` (JSON), the same package the
  app already uses for the auth token. Stores: saved device(s) (`label, sim, imei, devicePasswordHash,
  flespiDeviceId, controlNumbers, gpsEnabled, reportIntervalMinutes, liveFollow, locationUpdateSeconds,
  isActive`) and geofence (`centerLat, centerLng, radiusMeters, isEnabled, lastState`).
- **`data/tracking_data_source.dart`** — an interface both the above implement behind, so the provider
  depends on the interface, not on flespi/local directly. A future `RemoteTrackingDataSource` (the .NET
  API) drops in here with zero UI change.
- **`models/`** — `tracker_device.dart`, `live_location.dart`, `geofence.dart` with defensive `fromJson`.
- **`providers/tracking_provider.dart`** — `ChangeNotifier`. Polls `flespi_client.getLatest()` on a
  `Timer.periodic`; holds live location + geofence; computes breach client-side (haversine); on an
  Inside→Outside transition raises the in-app banner/dialog and fires a local notification
  (`flutter_local_notifications`, already a dep). Start/stop polling tied to screen lifecycle.

**Geofence breach (haversine, meters):**
```
inside = haversine(live.lat, live.lng, gf.centerLat, gf.centerLng) <= gf.radiusMeters
// alert only on (Inside|Unknown) -> Outside, then persist lastState
```
Center is a **fixed point the parent sets** (long-press the map), not the child's position.

## 4. Realtime strategy
Polling. Map open / live-follow on: poll every ~5 s and re-center. Card visible: ~10 s for speed/battery/
online. Geofence checked every `breachPollSeconds` while the app is open; alert via in-app banner/dialog +
local notification. (Background/closed push would need a server or Firebase Cloud Function — out of scope
for the defense.)

## 5. Real vs simulated

| Feature | Source | Real? |
|---|---|---|
| Live position, speed, battery, online/offline (`--`) | flespi messages | ✅ real |
| Movement history | flespi messages count=100 | ✅ real |
| Geofence circle + breach (green/red, banner, dialog, local notification) | local store + haversine | ✅ real |
| Call child (اتصل الان) | `url_launcher` `tel:${sim}` | ✅ real |
| GPS interval / update-rate / on-off / control numbers | flespi `commands-queue` if supported, else persist+simulate | ⚠️ real-or-sim |
| Power off / factory reset | command if supported, else simulate | ⚠️ likely sim |

## 6. Frontend (Flutter, feature-first)

Reuse `provider`, `google_maps_flutter`, `url_launcher`, `shared_preferences`,
`flutter_local_notifications` — all already in `pubspec.yaml`. No new packages.

**Map:** child marker at live position; geofence as a `Circle` (green inside, red outside); long-press to
set the fixed center; layers FAB toggles map type; call via `tel:`.

## 7. Screen ↔ Figma frame map

Entry banner already on the parent home (red "قطعة لتتبع الطفل / اطلب الان") → routes to `flow_138`.

| Figma frame(s) | Screen / state | Data + actions |
|---|---|---|
| `138` | Entry decision | buy → `139`; have it → add (`143`) or empty (`141`) |
| `139` | Buy QBIT page | static; CTA deep-links to add flow |
| `141` | Empty state | "Add device" → `143` |
| `143` | Add — device data | label, SIM, IMEI, device password → next |
| `145` | Add — control numbers | phone1 (req) + 2 opt → save device (hardcoded bind) |
| `147` / `151` / `154` | Device card (online / tracking-on / offline `--`) | live speed+battery+online; gps toggle; interval; start; turn off |
| `144` | Card context menu | settings / edit / delete |
| `148`–`150` | GPS interval sheet | slider → store + flespi command |
| `152` | "Turn off device?" confirm | command (or simulate) |
| `160` | "Please power on the device" | shown when offline and user starts tracking |
| `158` | In-app breach banner | from provider geofence state |
| `163` | "Delete device?" confirm | remove from store |
| `161` / `162` | Edit data / control numbers | pre-filled → update store |
| `164` / `166` | Settings page (+ factory-reset confirm) | update-rate, gps toggle+interval, geofence toggle+radius, live-follow; delete / factory reset / power off |
| `map_0` | Live map + marker + layers FAB | poll flespi, render marker |
| `map_1`–`3` | "وحدة التحكم" sheet | call child; live-follow toggle; geofence toggle+radius |
| `map_4`–`6` | Geofence radius slider sheet | 100 m … 1 km → store |
| `map_7` | Geofence green circle (inside) | safe |
| `map_8` | Geofence red circle (outside) | breach |
| `map_9` | Breach dialog on map | acknowledge / call child |

Assets to export into `assets/tracking/` and register in `pubspec.yaml`: QBIT image (`139`), child marker,
and any missing battery/speed/layers/power icons (most icons likely already exist in the app).

## 8. Build order (each runs and demos)
1. **Scaffold + live map.** `tracking_config`, `flespi_client`, `tracking_data_source`, models,
   `tracking_provider` (polling), and `live_map_screen` (`map_0`) showing the real position. *De-risks the
   data pipe first.*
2. **Device card + telemetry.** `147/151/154` live speed/battery/online; interval sheet `148–150`; gps toggle.
3. **Geofence.** long-press center + radius sheet `map_4–6`; green/red circle `map_7/8`; client-side breach
   + local notification + dialog `map_9` + banner `158`; control sheet `map_1–3`.
4. **Add / edit / delete + onboarding.** `138/139/141/143/145/161/162/163`; wire the home banner.
5. **Settings + commands + polish.** `164/166`; power-off `152`; power-on prompt `160`; factory reset;
   call button (`tel:`); commands real-or-simulated; full pass.

## 9. Acceptance per slice
- **S1:** real lat/lng from the Qbit appears as a moving marker; offline shows `--`.
- **S2:** card shows live speed/battery; interval change persists and reflects in UI.
- **S3:** parent sets a fixed center; leaving the radius turns the circle red, raises banner/dialog, and
  fires a local notification.
- **S4:** add binds a device to the child (persisted); edit updates; delete removes; banner entry works.
- **S5:** call opens the dialer to the SIM; power/reset/toggle behave (real or simulated) without errors.
