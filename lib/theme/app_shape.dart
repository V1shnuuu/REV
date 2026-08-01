import 'package:flutter/material.dart';

/// Rounded, soft-edged shape system — generous radii in the spirit of One UI
/// without imitating it. Radius scales with element size: bigger surfaces get
/// proportionally rounder corners.
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double pill = 999;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderPill = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Elevation as shadow recipes rather than Material's numeric elevation, so
/// dark mode can use glow/ambient depth (where drop shadows are invisible)
/// while light mode uses conventional shadows.
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = <BoxShadow>[];

  static List<BoxShadow> level1({required bool isDark}) => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0B0E11).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  static List<BoxShadow> level2({required bool isDark}) => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.50),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0B0E11).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];

  static List<BoxShadow> level3({required bool isDark}) => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.60),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0B0E11).withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ];

  /// Colored ambient glow used to reinforce state on the live CPR screen.
  /// Always paired with icon + label — never the sole state signal.
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28 * intensity),
      blurRadius: 28 * intensity,
      spreadRadius: 2 * intensity,
    ),
  ];
}
