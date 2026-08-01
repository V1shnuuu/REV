import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shape.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_motion.dart';
export 'app_shape.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Assembles [ThemeData] for both brightnesses and registers [ReviveColors]
/// as a theme extension. Widgets should read semantic tokens through
/// `context.colors` and text styles through `context.text`.
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(ReviveColors.dark, Brightness.dark);
  static ThemeData light() => _build(ReviveColors.light, Brightness.light);

  static ThemeData _build(ReviveColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final textTheme = AppTypography.textTheme.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.surfacePrimary,
      canvasColor: c.surfacePrimary,
      fontFamily: AppTypography.bodyFamily,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.urgentAction,
        onPrimary: c.onUrgentAction,
        secondary: c.inRangeSuccess,
        onSecondary: c.onInRangeSuccess,
        error: c.urgentAction,
        onError: c.onUrgentAction,
        surface: c.surfaceRaised,
        onSurface: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: c.textSecondary),
      ),
      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceOverlay,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      ),
      iconTheme: IconThemeData(color: c.textSecondary),
      splashColor: c.urgentAction.withValues(alpha: 0.10),
      highlightColor: c.urgentAction.withValues(alpha: 0.06),
      shadowColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFF0B0E11).withValues(alpha: 0.2),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.urgentAction,
          foregroundColor: c.onUrgentAction,
          disabledBackgroundColor: c.noDataNeutral.withValues(alpha: 0.24),
          disabledForegroundColor: c.textTertiary,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppTouchTarget.comfortable),
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          disabledForegroundColor: c.textTertiary,
          side: BorderSide(color: c.borderStrong),
          minimumSize: const Size.fromHeight(AppTouchTarget.comfortable),
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.urgentAction,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(AppTouchTarget.minimum, AppTouchTarget.minimum),
        ),
      ),
    );
  }
}

/// Shorthand accessors so widgets read as `context.colors.urgentAction`
/// rather than a chain of `Theme.of(context).extension<...>()!` calls.
extension ReviveThemeContext on BuildContext {
  ReviveColors get colors =>
      Theme.of(this).extension<ReviveColors>() ?? ReviveColors.dark;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
