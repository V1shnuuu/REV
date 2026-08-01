import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Throwaway development screen that renders every design token so the system
/// can be reviewed before it touches real screens. Not reachable from app
/// navigation — push it explicitly via [routeName], or temporarily set it as
/// `initialRoute` in main.dart.
///
/// Delete this file (and its route) before submission if you'd rather it not
/// ship. It is intentionally self-contained so removal is a clean deletion.
class DesignPreviewScreen extends StatefulWidget {
  static const String routeName = '/dev/design';

  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  Brightness _brightness = Brightness.dark;

  void _toggle() {
    setState(() {
      _brightness =
          _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _brightness == Brightness.dark;
    return Theme(
      data: isDark ? AppTheme.dark() : AppTheme.light(),
      child: Builder(
        builder: (context) {
          final c = context.colors;
          return Scaffold(
            backgroundColor: c.surfacePrimary,
            appBar: AppBar(
              title: Text('Design Tokens', style: context.text.titleLarge),
              backgroundColor: c.surfacePrimary,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: TextButton.icon(
                    onPressed: _toggle,
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                        size: 18),
                    label: Text(isDark ? 'LIGHT' : 'DARK'),
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.giant),
              children: [
                _SectionHeader('Surfaces'),
                _SwatchRow('surfacePrimary', c.surfacePrimary, c),
                _SwatchRow('surfaceSunken', c.surfaceSunken, c),
                _SwatchRow('surfaceRaised', c.surfaceRaised, c),
                _SwatchRow('surfaceOverlay', c.surfaceOverlay, c),
                _SwatchRow('borderSubtle', c.borderSubtle, c),
                _SwatchRow('borderStrong', c.borderStrong, c),

                _SectionHeader('Action'),
                _SwatchRow('urgentAction', c.urgentAction, c),
                _SwatchRow('urgentActionPressed', c.urgentActionPressed, c),
                _SwatchRow('urgentActionSubtle', c.urgentActionSubtle, c),
                _SwatchRow('onUrgentAction', c.onUrgentAction, c),

                _SectionHeader('Rhythm feedback'),
                _SwatchRow('inRangeSuccess', c.inRangeSuccess, c),
                _SwatchRow('inRangeSuccessSubtle', c.inRangeSuccessSubtle, c),
                _SwatchRow('belowRangeWarning', c.belowRangeWarning, c),
                _SwatchRow('aboveRangeWarning', c.aboveRangeWarning, c),
                _SwatchRow('noDataNeutral', c.noDataNeutral, c),

                _SectionHeader('Informational'),
                _SwatchRow('infoCalm', c.infoCalm, c),
                _SwatchRow('infoCalmSubtle', c.infoCalmSubtle, c),

                _SectionHeader('Text hierarchy'),
                _SwatchRow('textPrimary', c.textPrimary, c),
                _SwatchRow('textSecondary', c.textSecondary, c),
                _SwatchRow('textTertiary', c.textTertiary, c),

                _SectionHeader('Type scale'),
                _TypeSample('displayLarge  72/800', context.text.displayLarge, '128'),
                _TypeSample('displayMedium 56/800', context.text.displayMedium, '30'),
                _TypeSample('displaySmall  40/700', context.text.displaySmall, '02:14'),
                _TypeSample('headlineLarge 28/700', context.text.headlineLarge),
                _TypeSample('headlineMedium 24/700', context.text.headlineMedium),
                _TypeSample('headlineSmall 20/600', context.text.headlineSmall),
                _TypeSample('titleLarge 18/600', context.text.titleLarge),
                _TypeSample('titleMedium 16/600', context.text.titleMedium),
                _TypeSample('titleSmall 14/600', context.text.titleSmall),
                _TypeSample('bodyLarge 16/400', context.text.bodyLarge),
                _TypeSample('bodyMedium 14/400', context.text.bodyMedium),
                _TypeSample('bodySmall 12/400', context.text.bodySmall),
                _TypeSample('labelLarge 14/700', context.text.labelLarge, 'PUSH FASTER'),
                _TypeSample('labelMedium 12/700', context.text.labelMedium, 'CYCLE PROGRESS'),
                _TypeSample('labelSmall 10/700', context.text.labelSmall, 'AI OFFLINE'),

                _SectionHeader('Spacing (4pt base)'),
                _SpacingBar('xs', AppSpacing.xs, c),
                _SpacingBar('sm', AppSpacing.sm, c),
                _SpacingBar('md', AppSpacing.md, c),
                _SpacingBar('lg', AppSpacing.lg, c),
                _SpacingBar('xl', AppSpacing.xl, c),
                _SpacingBar('xxl', AppSpacing.xxl, c),
                _SpacingBar('xxxl', AppSpacing.xxxl, c),
                _SpacingBar('huge', AppSpacing.huge, c),
                _SpacingBar('massive', AppSpacing.massive, c),

                _SectionHeader('Radius'),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _RadiusChip('xs', AppRadius.xs, c),
                    _RadiusChip('sm', AppRadius.sm, c),
                    _RadiusChip('md', AppRadius.md, c),
                    _RadiusChip('lg', AppRadius.lg, c),
                    _RadiusChip('xl', AppRadius.xl, c),
                    _RadiusChip('xxl', AppRadius.xxl, c),
                  ],
                ),

                _SectionHeader('Elevation'),
                Row(
                  children: [
                    _ElevationBox('1', AppElevation.level1(isDark: isDark), c),
                    AppSpacing.hGapLg,
                    _ElevationBox('2', AppElevation.level2(isDark: isDark), c),
                    AppSpacing.hGapLg,
                    _ElevationBox('3', AppElevation.level3(isDark: isDark), c),
                  ],
                ),
                AppSpacing.gapXl,
                Row(
                  children: [
                    _ElevationBox(
                        'glow/urgent', AppElevation.glow(c.urgentAction), c),
                    AppSpacing.hGapLg,
                    _ElevationBox(
                        'glow/inRange', AppElevation.glow(c.inRangeSuccess), c),
                  ],
                ),

                _SectionHeader('Touch targets'),
                _TouchTargetBar('minimum 48', AppTouchTarget.minimum, c),
                _TouchTargetBar('comfortable 56', AppTouchTarget.comfortable, c),
                _TouchTargetBar('critical 64', AppTouchTarget.critical, c),

                _SectionHeader('Motion'),
                Text(
                  'instant 100ms  ·  fast 150ms  ·  normal 220ms  ·  slow 320ms\n'
                  'deliberate 500ms  ·  compressionCycle 545ms (110 BPM)\n\n'
                  'Reduce motion is currently: '
                  '${ResolvedMotion.of(context).reduceMotion ? "ON" : "OFF"}',
                  style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl, bottom: AppSpacing.md),
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium?.copyWith(color: context.colors.urgentAction),
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  final String name;
  final Color color;
  final ReviveColors c;
  const _SwatchRow(this.name, this.color, this.c);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: c.borderSubtle),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Text(name,
                style: context.text.bodyMedium?.copyWith(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _TypeSample extends StatelessWidget {
  final String label;
  final TextStyle? style;
  final String? sample;
  const _TypeSample(this.label, this.style, [this.sample]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.textTertiary)),
          AppSpacing.gapXs,
          Text(sample ?? 'Push hard and fast', style: style),
        ],
      ),
    );
  }
}

class _SpacingBar extends StatelessWidget {
  final String name;
  final double value;
  final ReviveColors c;
  const _SpacingBar(this.name, this.value, this.c);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text('$name  ${value.toInt()}',
                style: context.text.bodySmall?.copyWith(color: c.textSecondary)),
          ),
          Container(
            width: value,
            height: 16,
            decoration: BoxDecoration(
              color: c.urgentAction,
              borderRadius: AppRadius.borderXs,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  final String name;
  final double radius;
  final ReviveColors c;
  const _RadiusChip(this.name, this.radius, this.c);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.borderStrong),
      ),
      child: Text('$name\n${radius.toInt()}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: c.textSecondary)),
    );
  }
}

class _ElevationBox extends StatelessWidget {
  final String name;
  final List<BoxShadow> shadow;
  final ReviveColors c;
  const _ElevationBox(this.name, this.shadow, this.c);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: AppRadius.borderMd,
          boxShadow: shadow,
        ),
        child: Text(name,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textSecondary)),
      ),
    );
  }
}

class _TouchTargetBar extends StatelessWidget {
  final String name;
  final double size;
  final ReviveColors c;
  const _TouchTargetBar(this.name, this.size, this.c);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c.urgentActionSubtle,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: c.urgentAction),
            ),
          ),
          AppSpacing.hGapMd,
          Text(name,
              style: context.text.bodyMedium?.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
