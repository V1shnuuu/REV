import 'package:flutter/material.dart';
import '../../services/motion_service.dart';
import '../../theme/app_theme.dart';

/// Theme-aware compression-rate gauge with four explicit visual states.
///
/// This is the single most important element on the live CPR screen, so it is
/// built to survive bad conditions: the numerals are the largest thing on
/// screen, state is signalled by colour *and* icon *and* text *and* motion,
/// and every one of those channels works on its own. A rescuer who is
/// colour-blind, glancing sideways, or has reduce-motion enabled still gets
/// the same instruction.
///
/// Reads [BpmReading] from MotionService but owns no logic of its own — the
/// thresholds live in the service and are not duplicated here.
class ReviveBpmGauge extends StatelessWidget {
  final BpmReading reading;

  /// Compact layout for secondary placements (the step-guide practice screen)
  /// where the gauge is not the primary focus.
  final bool compact;

  const ReviveBpmGauge({
    super.key,
    required this.reading,
    this.compact = false,
  });

  /// Lowest and highest BPM the track represents.
  static const double _trackMin = 60;
  static const double _trackMax = 200;
  static const double _markerWidth = 4;

  /// Clinical target band.
  static const double _targetLow = 100;
  static const double _targetHigh = 120;

  /// Status -> accent colour. Exposed statically so other widgets that must
  /// agree with the gauge (the chest animation on the live screen) resolve the
  /// same colour instead of duplicating the switch and drifting out of sync.
  static Color accentFor(BuildContext context, BpmStatus status) {
    final c = context.colors;
    return switch (status) {
      BpmStatus.good => c.inRangeSuccess,
      BpmStatus.tooSlow => c.belowRangeWarning,
      BpmStatus.tooFast => c.aboveRangeWarning,
      BpmStatus.waiting => c.noDataNeutral,
    };
  }

  /// Status -> icon. Direction is meaningful: up means push faster, down means
  /// slow down, so the icon carries the instruction without colour or text.
  static IconData iconFor(BpmStatus status) => switch (status) {
    BpmStatus.good => Icons.check_circle,
    BpmStatus.tooSlow => Icons.keyboard_double_arrow_up,
    BpmStatus.tooFast => Icons.keyboard_double_arrow_down,
    BpmStatus.waiting => Icons.touch_app,
  };

  /// Status -> imperative label. Phrased as the action to take, not the state
  /// observed: "PUSH FASTER" beats "TOO SLOW" when read at a glance mid-CPR.
  static String labelFor(BpmStatus status) => switch (status) {
    BpmStatus.good => 'GOOD RHYTHM',
    BpmStatus.tooSlow => 'PUSH FASTER',
    BpmStatus.tooFast => 'SLOW DOWN',
    BpmStatus.waiting => 'START PUSHING',
  };

  Color _accent(BuildContext context) => accentFor(context, reading.status);
  IconData get _icon => iconFor(reading.status);
  String get _label => labelFor(reading.status);

  /// Spoken/screen-reader description. Deliberately fuller than the visual
  /// label, because a screen-reader user gets no colour or position cue.
  String get _semanticLabel {
    final count = '${reading.compressionCount} compressions';
    return switch (reading.status) {
      BpmStatus.waiting =>
        'Waiting for compressions. Target 100 to 120 per minute. $count.',
      _ =>
        '${reading.bpm.toStringAsFixed(0)} beats per minute. '
            '${_label.toLowerCase()}. Target 100 to 120. $count.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = ResolvedMotion.of(context);
    final accent = _accent(context);
    final hasReading = reading.bpm > 0;

    return Semantics(
      container: true,
      liveRegion: true,
      label: _semanticLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: motion.duration(AppMotion.normal),
        curve: motion.curve(AppMotion.standard),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.md : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: accent.withValues(alpha: 0.40), width: 2),
          // Glow reinforces state but is never the only signal, and it is
          // dropped entirely under reduce-motion where it would otherwise
          // pulse with the compression animation.
          boxShadow: motion.shouldAnimate && reading.status != BpmStatus.waiting
              ? AppElevation.glow(accent, intensity: 0.7)
              : AppElevation.none,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusRow(
              icon: _icon,
              label: _label,
              accent: accent,
              compact: compact,
            ),
            AppSpacing.gapSm,
            _MetricsRow(
              bpm: hasReading ? reading.bpm.toStringAsFixed(0) : '--',
              count: reading.compressionCount.toString(),
              accent: accent,
              compact: compact,
            ),
            AppSpacing.gapMd,
            _RangeTrack(
              bpm: reading.bpm,
              accent: accent,
              showMarker: hasReading,
            ),
            AppSpacing.gapXs,
            _TrackLegend(),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool compact;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: accent, size: compact ? 20 : 26),
        AppSpacing.hGapSm,
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style:
                (compact ? context.text.labelMedium : context.text.labelLarge)
                    ?.copyWith(color: accent),
          ),
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final String bpm;
  final String count;
  final Color accent;
  final bool compact;

  const _MetricsRow({
    required this.bpm,
    required this.count,
    required this.accent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _Metric(
            // FittedBox keeps the hero numeral from overflowing on small
            // devices or at large system text scales, rather than clipping.
            value: bpm,
            unit: 'BPM',
            color: accent,
            valueStyle: compact
                ? context.text.displaySmall
                : context.text.displayLarge,
          ),
        ),
        Container(width: 1, height: compact ? 36 : 56, color: c.borderSubtle),
        Expanded(
          child: _Metric(
            value: count,
            unit: 'COMPRESSIONS',
            color: c.textPrimary,
            valueStyle: compact
                ? context.text.headlineMedium
                : context.text.displaySmall,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  final TextStyle? valueStyle;

  const _Metric({
    required this.value,
    required this.unit,
    required this.color,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: valueStyle?.copyWith(color: color)),
        ),
        Text(
          unit,
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _RangeTrack extends StatelessWidget {
  final double bpm;
  final Color accent;
  final bool showMarker;

  const _RangeTrack({
    required this.bpm,
    required this.accent,
    required this.showMarker,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = ResolvedMotion.of(context);

    // Flex weights derived from the actual BPM range so the target band lines
    // up with the numbers in the legend, instead of being eyeballed.
    const belowSpan = ReviveBpmGauge._targetLow - ReviveBpmGauge._trackMin;
    const targetSpan = ReviveBpmGauge._targetHigh - ReviveBpmGauge._targetLow;
    const aboveSpan = ReviveBpmGauge._trackMax - ReviveBpmGauge._targetHigh;

    return ClipRRect(
      borderRadius: AppRadius.borderXs,
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: belowSpan.toInt(),
                    child: ColoredBox(
                      color: c.belowRangeWarning.withValues(alpha: 0.28),
                    ),
                  ),
                  Expanded(
                    flex: targetSpan.toInt(),
                    child: ColoredBox(
                      color: c.inRangeSuccess.withValues(alpha: 0.55),
                    ),
                  ),
                  Expanded(
                    flex: aboveSpan.toInt(),
                    child: ColoredBox(
                      color: c.aboveRangeWarning.withValues(alpha: 0.28),
                    ),
                  ),
                ],
              ),
              if (showMarker)
                AnimatedPositioned(
                  duration: motion.duration(AppMotion.normal),
                  curve: motion.curve(AppMotion.standard),
                  left: _markerOffset(constraints.maxWidth),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: ReviveBpmGauge._markerWidth,
                    decoration: BoxDecoration(
                      color: c.textPrimary,
                      borderRadius: AppRadius.borderXs,
                      boxShadow: AppElevation.glow(accent, intensity: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pixel offset of the marker. Takes the measured track width — passing a
  /// normalised 1.0 here is the bug that previously pinned the marker to the
  /// left edge at every BPM.
  double _markerOffset(double trackWidth) {
    const min = ReviveBpmGauge._trackMin;
    const max = ReviveBpmGauge._trackMax;
    final fraction = ((bpm - min) / (max - min)).clamp(0.0, 1.0);
    final usable = (trackWidth - ReviveBpmGauge._markerWidth).clamp(
      0.0,
      double.infinity,
    );
    return fraction * usable;
  }
}

class _TrackLegend extends StatelessWidget {
  const _TrackLegend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = context.text.labelSmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${ReviveBpmGauge._trackMin.toInt()}',
          style: meta?.copyWith(color: c.textTertiary),
        ),
        Text(
          'TARGET ${ReviveBpmGauge._targetLow.toInt()}'
          '-${ReviveBpmGauge._targetHigh.toInt()}',
          style: meta?.copyWith(color: c.inRangeSuccess),
        ),
        Text(
          '${ReviveBpmGauge._trackMax.toInt()}',
          style: meta?.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}
