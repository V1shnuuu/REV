import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Semantic haptic vocabulary.
///
/// Flutter's [HapticFeedback] already routes to the right native API on each
/// platform — `lightImpact` maps to `UIImpactFeedbackGenerator(style: .light)`
/// on iOS and to `HapticFeedbackConstants` on Android — so the platform work
/// here is not calling different APIs, it is choosing different *intensities*,
/// because the same constant feels quite different on the two platforms.
///
/// iOS Taptic Engine pulses read as crisper and stronger than the typical
/// Android vibration motor at the equivalent level, so Android is nudged one
/// step up for the cues that must be felt through a phone pressed against a
/// chest.
class AppHaptics {
  AppHaptics._();

  static bool get _isIOS => !kIsWeb && Platform.isIOS;
  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Fired on every metronome beat at the 110 BPM compression target.
  ///
  /// This is the one haptic that matters most: it lets a rescuer keep rhythm
  /// with the phone against the chest and their eyes on the patient rather
  /// than the screen. Deliberately the lightest cue that is still reliably
  /// perceptible — it repeats roughly twice a second for minutes at a time,
  /// and anything heavier becomes both numbing and battery-expensive.
  static Future<void> compressionBeat() async {
    if (!_supported) return;
    if (_isIOS) {
      await HapticFeedback.lightImpact();
    } else {
      // Android motors under-report light impacts; selectionClick is the
      // closest reliable equivalent of a crisp iOS light tap.
      await HapticFeedback.selectionClick();
    }
  }

  /// Fired when compression rate crosses into or out of the 100-120 target
  /// band. Distinct from [compressionBeat] so it is felt *through* the ongoing
  /// rhythm rather than lost in it.
  static Future<void> rangeTransition() async {
    if (!_supported) return;
    await HapticFeedback.mediumImpact();
  }

  /// Fired when the rescue-breath prompt appears — an interruption the
  /// rescuer must notice even with the screen out of view.
  static Future<void> prompt() async {
    if (!_supported) return;
    await HapticFeedback.heavyImpact();
  }

  /// Ordinary control confirmation.
  static Future<void> tap() async {
    if (!_supported) return;
    await HapticFeedback.selectionClick();
  }
}
