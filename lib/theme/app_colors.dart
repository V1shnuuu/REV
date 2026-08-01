import 'package:flutter/material.dart';

/// Raw palette values. NOTHING outside this file should reference these
/// directly — widgets consume semantic tokens via [ReviveColors], which is
/// registered as a [ThemeExtension] so it resolves correctly in both light
/// and dark mode.
///
/// Deliberate design decision on the out-of-range states: coral-red is
/// reserved exclusively for urgent action / primary CTA ("do this now").
/// Rhythm feedback therefore uses amber tones for out-of-range rather than
/// red, so red never means two different things on the same screen. The
/// too-slow / too-fast distinction is carried by icon, label, and motion
/// direction as well as hue — never by color alone.
class _Palette {
  _Palette._();

  // --- Dark (primary design target) ---
  static const darkBase = Color(0xFF0B0E11);
  static const darkSunken = Color(0xFF070909);
  static const darkRaised = Color(0xFF14181C);
  static const darkOverlay = Color(0xFF1C2229);

  static const darkUrgent = Color(0xFFFF5A45);
  static const darkUrgentPressed = Color(0xFFE64A36);
  static const darkInRange = Color(0xFF3DDC97);
  static const darkBelowRange = Color(0xFFFFC24B);
  static const darkAboveRange = Color(0xFFFF9A3D);
  static const darkInfo = Color(0xFF4FB0F5);
  static const darkNeutral = Color(0xFF8A94A0);

  static const darkTextPrimary = Color(0xFFF2F5F7);
  static const darkTextSecondary = Color(0xFFA8B2BD);
  static const darkTextTertiary = Color(0xFF6B7480);

  // --- Light (accents darkened to hold contrast on pale surfaces) ---
  static const lightBase = Color(0xFFF5F7F9);
  static const lightSunken = Color(0xFFE8ECEF);
  static const lightRaised = Color(0xFFFFFFFF);
  static const lightOverlay = Color(0xFFFFFFFF);

  static const lightUrgent = Color(0xFFC7371F);
  static const lightUrgentPressed = Color(0xFFA82C17);
  static const lightInRange = Color(0xFF0B7A57);
  static const lightBelowRange = Color(0xFF8A5A00);
  static const lightAboveRange = Color(0xFF9C4600);
  static const lightInfo = Color(0xFF0B5FA8);
  static const lightNeutral = Color(0xFF5C6570);

  static const lightTextPrimary = Color(0xFF0B0E11);
  static const lightTextSecondary = Color(0xFF454F5A);
  static const lightTextTertiary = Color(0xFF6B7480);

  static const white = Color(0xFFFFFFFF);
}

/// Semantic color tokens. Access via `Theme.of(context).extension<ReviveColors>()!`
/// or the `context.colors` shorthand in `app_theme.dart`.
@immutable
class ReviveColors extends ThemeExtension<ReviveColors> {
  // Surfaces
  final Color surfacePrimary;
  final Color surfaceSunken;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color borderSubtle;
  final Color borderStrong;

  // Action
  final Color urgentAction;
  final Color urgentActionPressed;
  final Color onUrgentAction;
  final Color urgentActionSubtle;

  // Rhythm / technique feedback
  final Color inRangeSuccess;
  final Color onInRangeSuccess;
  final Color inRangeSuccessSubtle;
  final Color belowRangeWarning;
  final Color aboveRangeWarning;
  final Color noDataNeutral;

  // Informational (rescue-breath prompts, non-urgent notices)
  final Color infoCalm;
  final Color infoCalmSubtle;

  // Text hierarchy
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const ReviveColors({
    required this.surfacePrimary,
    required this.surfaceSunken,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.borderSubtle,
    required this.borderStrong,
    required this.urgentAction,
    required this.urgentActionPressed,
    required this.onUrgentAction,
    required this.urgentActionSubtle,
    required this.inRangeSuccess,
    required this.onInRangeSuccess,
    required this.inRangeSuccessSubtle,
    required this.belowRangeWarning,
    required this.aboveRangeWarning,
    required this.noDataNeutral,
    required this.infoCalm,
    required this.infoCalmSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  static final dark = ReviveColors(
    surfacePrimary: _Palette.darkBase,
    surfaceSunken: _Palette.darkSunken,
    surfaceRaised: _Palette.darkRaised,
    surfaceOverlay: _Palette.darkOverlay,
    borderSubtle: _Palette.white.withValues(alpha: 0.08),
    borderStrong: _Palette.white.withValues(alpha: 0.18),
    urgentAction: _Palette.darkUrgent,
    urgentActionPressed: _Palette.darkUrgentPressed,
    // Near-black, not white. White on this coral measures 3.09:1 — below the
    // 4.5:1 AA floor for button labels. Darkening the coral enough to carry
    // white would cost the accent its contrast as standalone text (currently
    // 6.27:1), so the label inverts instead. Verified by tool/contrast_check.py.
    onUrgentAction: _Palette.darkBase,
    urgentActionSubtle: _Palette.darkUrgent.withValues(alpha: 0.14),
    inRangeSuccess: _Palette.darkInRange,
    onInRangeSuccess: _Palette.darkBase,
    inRangeSuccessSubtle: _Palette.darkInRange.withValues(alpha: 0.14),
    belowRangeWarning: _Palette.darkBelowRange,
    aboveRangeWarning: _Palette.darkAboveRange,
    noDataNeutral: _Palette.darkNeutral,
    infoCalm: _Palette.darkInfo,
    infoCalmSubtle: _Palette.darkInfo.withValues(alpha: 0.14),
    textPrimary: _Palette.darkTextPrimary,
    textSecondary: _Palette.darkTextSecondary,
    textTertiary: _Palette.darkTextTertiary,
  );

  static final light = ReviveColors(
    surfacePrimary: _Palette.lightBase,
    surfaceSunken: _Palette.lightSunken,
    surfaceRaised: _Palette.lightRaised,
    surfaceOverlay: _Palette.lightOverlay,
    borderSubtle: _Palette.lightTextPrimary.withValues(alpha: 0.10),
    borderStrong: _Palette.lightTextPrimary.withValues(alpha: 0.22),
    urgentAction: _Palette.lightUrgent,
    urgentActionPressed: _Palette.lightUrgentPressed,
    onUrgentAction: _Palette.white,
    urgentActionSubtle: _Palette.lightUrgent.withValues(alpha: 0.10),
    inRangeSuccess: _Palette.lightInRange,
    onInRangeSuccess: _Palette.white,
    inRangeSuccessSubtle: _Palette.lightInRange.withValues(alpha: 0.12),
    belowRangeWarning: _Palette.lightBelowRange,
    aboveRangeWarning: _Palette.lightAboveRange,
    noDataNeutral: _Palette.lightNeutral,
    infoCalm: _Palette.lightInfo,
    infoCalmSubtle: _Palette.lightInfo.withValues(alpha: 0.10),
    textPrimary: _Palette.lightTextPrimary,
    textSecondary: _Palette.lightTextSecondary,
    textTertiary: _Palette.lightTextTertiary,
  );

  @override
  ReviveColors copyWith({
    Color? surfacePrimary,
    Color? surfaceSunken,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? borderSubtle,
    Color? borderStrong,
    Color? urgentAction,
    Color? urgentActionPressed,
    Color? onUrgentAction,
    Color? urgentActionSubtle,
    Color? inRangeSuccess,
    Color? onInRangeSuccess,
    Color? inRangeSuccessSubtle,
    Color? belowRangeWarning,
    Color? aboveRangeWarning,
    Color? noDataNeutral,
    Color? infoCalm,
    Color? infoCalmSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return ReviveColors(
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      urgentAction: urgentAction ?? this.urgentAction,
      urgentActionPressed: urgentActionPressed ?? this.urgentActionPressed,
      onUrgentAction: onUrgentAction ?? this.onUrgentAction,
      urgentActionSubtle: urgentActionSubtle ?? this.urgentActionSubtle,
      inRangeSuccess: inRangeSuccess ?? this.inRangeSuccess,
      onInRangeSuccess: onInRangeSuccess ?? this.onInRangeSuccess,
      inRangeSuccessSubtle: inRangeSuccessSubtle ?? this.inRangeSuccessSubtle,
      belowRangeWarning: belowRangeWarning ?? this.belowRangeWarning,
      aboveRangeWarning: aboveRangeWarning ?? this.aboveRangeWarning,
      noDataNeutral: noDataNeutral ?? this.noDataNeutral,
      infoCalm: infoCalm ?? this.infoCalm,
      infoCalmSubtle: infoCalmSubtle ?? this.infoCalmSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  ReviveColors lerp(ThemeExtension<ReviveColors>? other, double t) {
    if (other is! ReviveColors) return this;
    return ReviveColors(
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      urgentAction: Color.lerp(urgentAction, other.urgentAction, t)!,
      urgentActionPressed: Color.lerp(urgentActionPressed, other.urgentActionPressed, t)!,
      onUrgentAction: Color.lerp(onUrgentAction, other.onUrgentAction, t)!,
      urgentActionSubtle: Color.lerp(urgentActionSubtle, other.urgentActionSubtle, t)!,
      inRangeSuccess: Color.lerp(inRangeSuccess, other.inRangeSuccess, t)!,
      onInRangeSuccess: Color.lerp(onInRangeSuccess, other.onInRangeSuccess, t)!,
      inRangeSuccessSubtle: Color.lerp(inRangeSuccessSubtle, other.inRangeSuccessSubtle, t)!,
      belowRangeWarning: Color.lerp(belowRangeWarning, other.belowRangeWarning, t)!,
      aboveRangeWarning: Color.lerp(aboveRangeWarning, other.aboveRangeWarning, t)!,
      noDataNeutral: Color.lerp(noDataNeutral, other.noDataNeutral, t)!,
      infoCalm: Color.lerp(infoCalm, other.infoCalm, t)!,
      infoCalmSubtle: Color.lerp(infoCalmSubtle, other.infoCalmSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}
