import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Semantic emphasis for a [ReviveCard]. Follows the three-tier alerting
/// hierarchy used across the app: neutral for ordinary content, [info] for
/// non-urgent notices, [caution] for "degraded but working", and [critical]
/// reserved for "stop and call for help".
enum ReviveCardTone { neutral, info, caution, critical, success }

/// Standard surface container. Every card in the app should be this, so
/// padding, radius, border and elevation stay consistent instead of being
/// re-invented per screen.
class ReviveCard extends StatelessWidget {
  final Widget child;
  final ReviveCardTone tone;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool compact;
  final bool elevated;

  const ReviveCard({
    super.key,
    required this.child,
    this.tone = ReviveCardTone.neutral,
    this.padding,
    this.onTap,
    this.compact = false,
    this.elevated = false,
  });

  /// Resolves the accent for a tone, or null for [ReviveCardTone.neutral].
  static Color? accentFor(BuildContext context, ReviveCardTone tone) {
    final c = context.colors;
    return switch (tone) {
      ReviveCardTone.neutral => null,
      ReviveCardTone.info => c.infoCalm,
      ReviveCardTone.caution => c.belowRangeWarning,
      ReviveCardTone.critical => c.urgentAction,
      ReviveCardTone.success => c.inRangeSuccess,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = accentFor(context, tone);

    final content = Container(
      width: double.infinity,
      padding:
          padding ??
          (compact ? AppSpacing.cardPaddingCompact : AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: accent == null
            ? c.surfaceRaised
            : accent.withValues(alpha: 0.10),
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: accent == null
              ? c.borderSubtle
              : accent.withValues(alpha: 0.35),
        ),
        boxShadow: elevated
            ? AppElevation.level1(isDark: context.isDarkMode)
            : AppElevation.none,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: content,
      ),
    );
  }
}

/// Compact status chip — used for "AI OFFLINE", "MIC ON", "LIVE" and similar
/// at-a-glance state. Always renders an icon alongside the label so the state
/// is never carried by colour alone.
class ReviveStatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final ReviveCardTone tone;

  /// Screen-reader text. Defaults to [label], which is often an abbreviation;
  /// pass something fuller where that reads badly aloud.
  final String? semanticLabel;

  const ReviveStatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.tone = ReviveCardTone.neutral,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = ReviveCard.accentFor(context, tone) ?? c.noDataNeutral;

    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: AppRadius.borderPill,
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: accent),
            AppSpacing.hGapXs,
            Text(
              label,
              style: context.text.labelSmall?.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
