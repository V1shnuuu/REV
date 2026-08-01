import 'package:flutter/material.dart';

/// Shared motion spec. Every animation in the app pulls its duration and
/// curve from here so timing reads as one system rather than per-widget
/// guesswork.
class AppMotion {
  AppMotion._();

  // --- Durations ---
  /// Immediate affordance feedback (press states, ripples).
  static const Duration instant = Duration(milliseconds: 100);

  /// Micro-interactions: toggles, small fades, icon swaps.
  static const Duration fast = Duration(milliseconds: 150);

  /// Default for state transitions — color/size changes, gauge updates.
  static const Duration normal = Duration(milliseconds: 220);

  /// Entrances, sheet reveals, page-level content changes.
  static const Duration slow = Duration(milliseconds: 320);

  /// Deliberate, attention-drawing transitions (breath prompt appearing).
  static const Duration deliberate = Duration(milliseconds: 500);

  /// One compression cycle at the 110 BPM clinical target.
  ///
  /// MUST stay in sync with `AudioService.compressionIntervalMs` — the
  /// metronome beep and the visual pulse have to land on the same beat or
  /// the rescuer gets conflicting rhythm cues. Kept as a separate constant
  /// rather than imported to avoid the theme layer depending on services.
  static const Duration compressionCycle = Duration(milliseconds: 545);

  // --- Curves ---
  /// Default easing for most transitions — decelerates into rest.
  static const Curve standard = Curves.easeOutCubic;

  /// Entering elements.
  static const Curve entrance = Curves.easeOutQuart;

  /// Exiting elements.
  static const Curve exit = Curves.easeInCubic;

  /// Springy overshoot for the compression pulse — mimics chest recoil.
  static const Curve compressionPulse = Curves.easeOutBack;

  /// Symmetric, continuous — for looping ambient animations (breathing glow).
  static const Curve ambient = Curves.easeInOut;
}

/// Resolves motion against the platform "reduce motion" accessibility
/// setting. Call [of] and use the returned instance instead of [AppMotion]
/// directly anywhere an animation could be disorienting or is purely
/// decorative.
///
/// Reduced-motion behaviour is to collapse duration to near-zero rather than
/// to remove the widget's animated code path, so state still changes — it
/// just arrives without travel. Looping/decorative animations should check
/// [shouldAnimate] and skip entirely.
@immutable
class ResolvedMotion {
  final bool reduceMotion;

  const ResolvedMotion({required this.reduceMotion});

  factory ResolvedMotion.of(BuildContext context) {
    return ResolvedMotion(
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
    );
  }

  /// True when decorative/looping animation is permitted.
  bool get shouldAnimate => !reduceMotion;

  /// Collapses any duration to a single frame when reduce-motion is on.
  Duration duration(Duration value) =>
      reduceMotion ? Duration.zero : value;

  /// Linear curve under reduce-motion — no overshoot or bounce, which is the
  /// part that actually causes discomfort.
  Curve curve(Curve value) => reduceMotion ? Curves.linear : value;
}
