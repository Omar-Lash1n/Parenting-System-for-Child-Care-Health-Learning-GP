import '../models/live_location.dart';

// Interface that both FlespiClient (now) and a future RemoteTrackingDataSource
// (.NET backend later) implement. The provider depends only on this contract.
abstract class TrackingDataSource {
  /// Returns the single most recent telemetry message for the bound device,
  /// or null if the request fails or no messages exist yet.
  Future<LiveLocation?> getLatest();
}
