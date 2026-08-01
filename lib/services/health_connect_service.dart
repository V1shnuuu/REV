import 'package:health/health.dart';

/// Logs a completed CPR incident to Android Health Connect (the on-device
/// store Samsung Health itself reads from/writes to on modern One UI
/// devices), so compression count/duration/guidance survive past the app and
/// can be handed to EMS or a hospital on arrival.
///
/// This is entirely additive: every call is wrapped so a missing Health
/// Connect install, a denied permission, or an unsupported device degrades to
/// "logging unavailable" and never touches the CPR coaching flow above it.
class HealthConnectService {
  static final HealthConnectService _instance = HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  final Health _health = Health();
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Returns true if the incident was written to Health Connect, false if
  /// unavailable/denied/unsupported for any reason (never throws).
  Future<bool> logCprIncident({
    required int compressionCount,
    required Duration duration,
    required String guidanceSummary,
  }) async {
    try {
      await _ensureConfigured();

      const types = [HealthDataType.WORKOUT];
      const permissions = [HealthDataAccess.READ_WRITE];

      final authorized = await _health.requestAuthorization(types, permissions: permissions);
      if (!authorized) return false;

      final end = DateTime.now();
      final start = end.subtract(duration);
      final title =
          'REVIVE CPR incident: $compressionCount compressions over ${duration.inMinutes}m ${duration.inSeconds % 60}s. $guidanceSummary';

      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.OTHER,
        title: title.length > 250 ? title.substring(0, 250) : title,
        start: start,
        end: end,
      );
    } catch (_) {
      // Health Connect not installed, permission denied, unsupported OS
      // version, etc. — the CPR session itself already completed fine.
      return false;
    }
  }
}
