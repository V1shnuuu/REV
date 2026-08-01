import 'package:flutter/material.dart';

/// Type scale, built on locally bundled variable fonts (Outfit for display /
/// headings, Inter for body / labels). Fonts are bundled rather than fetched
/// via google_fonts at runtime: this app's core promise is that it works with
/// no connectivity, and a runtime font fetch fails silently to system default
/// in exactly that scenario.
///
/// Weight is set through [FontVariation] on the `wght` axis because both
/// families ship as single variable files. [FontWeight] is also supplied so
/// that platform fallback fonts still render at a sensible weight.
class AppTypography {
  AppTypography._();

  static const String displayFamily = 'Outfit';
  static const String bodyFamily = 'Inter';

  /// Tabular figures keep rapidly-changing numerals (BPM, compression count,
  /// elapsed timer) from jittering in width as digits change.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static List<FontVariation> _wght(double weight) => [
    FontVariation('wght', weight),
  ];

  static TextStyle _display({
    required double size,
    required double height,
    required double weight,
    double letterSpacing = -0.5,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: _wght(weight),
      fontFeatures: _tabular,
    );
  }

  static TextStyle _body({
    required double size,
    required double height,
    required double weight,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: _wght(weight),
    );
  }

  // --- Display: large glanceable numerals, readable at arm's length ---

  /// Hero metric on the live CPR screen (BPM). Must remain the largest
  /// element on that screen.
  static final TextStyle displayLarge = _display(
    size: 72,
    height: 1.0,
    weight: 800,
    letterSpacing: -2,
  );

  /// Secondary hero metric (compression count).
  static final TextStyle displayMedium = _display(
    size: 56,
    height: 1.05,
    weight: 800,
    letterSpacing: -1.5,
  );

  /// Tertiary metric (elapsed timer, cycle progress).
  static final TextStyle displaySmall = _display(
    size: 40,
    height: 1.1,
    weight: 700,
    letterSpacing: -1,
  );

  // --- Headline: screen and section titles ---

  static final TextStyle headlineLarge = _display(
    size: 28,
    height: 1.2,
    weight: 700,
  );
  static final TextStyle headlineMedium = _display(
    size: 24,
    height: 1.25,
    weight: 700,
  );
  static final TextStyle headlineSmall = _display(
    size: 20,
    height: 1.3,
    weight: 600,
  );

  // --- Title: emphasised body, card headers ---

  static final TextStyle titleLarge = _body(
    size: 18,
    height: 1.35,
    weight: 600,
  );
  static final TextStyle titleMedium = _body(
    size: 16,
    height: 1.4,
    weight: 600,
  );
  static final TextStyle titleSmall = _body(size: 14, height: 1.4, weight: 600);

  // --- Body: instructions and prose ---

  /// Default for CPR instruction text — generous line height, this gets read
  /// under stress.
  static final TextStyle bodyLarge = _body(size: 16, height: 1.55, weight: 400);
  static final TextStyle bodyMedium = _body(size: 14, height: 1.5, weight: 400);
  static final TextStyle bodySmall = _body(size: 12, height: 1.5, weight: 400);

  // --- Label: all-caps metadata, status pills, button text ---

  static final TextStyle labelLarge = _body(
    size: 14,
    height: 1.2,
    weight: 700,
    letterSpacing: 1.5,
  );
  static final TextStyle labelMedium = _body(
    size: 12,
    height: 1.2,
    weight: 700,
    letterSpacing: 1.5,
  );
  static final TextStyle labelSmall = _body(
    size: 10,
    height: 1.2,
    weight: 700,
    letterSpacing: 1.2,
  );

  static final TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
