import 'package:flutter/foundation.dart';

/// Debug-only logging.
///
/// Replaces bare `print()` calls in the service layer. Two reasons this matters
/// beyond silencing a lint:
///
/// * `print()` runs in release builds too. The Ollama service was logging full
///   request and response bodies — everything the bystander said out loud, and
///   everything the model replied — to the device log where any app with log
///   access could read it. For a medical-emergency app that is a privacy leak,
///   not just noise.
/// * `print()` output is truncated by the Android log buffer under load;
///   [debugPrint] throttles instead of dropping lines.
///
/// Guarded by [kDebugMode], so these calls compile out of release builds
/// entirely.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
