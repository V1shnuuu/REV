import 'package:flutter/material.dart';
import '../../services/motion_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/components/revive_bpm_gauge.dart';
import '../../widgets/components/revive_button.dart';
import '../../widgets/components/revive_card.dart';
import '../../widgets/components/revive_dialog.dart';
import '../../widgets/components/revive_state_view.dart';
import '../../widgets/components/voice_activity_indicator.dart';

/// Development screen rendering every Phase 2 component in every state, with a
/// light/dark toggle. Exists so the component set can be reviewed in isolation
/// before it is wired into real screens.
///
/// Route-gated at [routeName]; not reachable from app navigation. Self
/// contained, so deleting this file and its route removes it cleanly.
class ComponentShowcaseScreen extends StatefulWidget {
  static const String routeName = '/dev/components';

  const ComponentShowcaseScreen({super.key});

  @override
  State<ComponentShowcaseScreen> createState() =>
      _ComponentShowcaseScreenState();
}

class _ComponentShowcaseScreenState extends State<ComponentShowcaseScreen> {
  Brightness _brightness = Brightness.dark;
  bool _loadingDemo = false;

  void _toggleBrightness() {
    setState(() {
      _brightness = _brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
    });
  }

  void _demoLoading() {
    setState(() => _loadingDemo = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loadingDemo = false);
    });
  }

  static BpmReading _reading(BpmStatus status, double bpm, int count) =>
      BpmReading(bpm: bpm, status: status, compressionCount: count);

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
              title: Text('Components', style: context.text.titleLarge),
              backgroundColor: c.surfacePrimary,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: TextButton.icon(
                    onPressed: _toggleBrightness,
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      size: 18,
                    ),
                    label: Text(isDark ? 'LIGHT' : 'DARK'),
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.giant,
              ),
              children: [
                const _Section('BPM gauge — all four states'),
                ReviveBpmGauge(reading: _reading(BpmStatus.waiting, 0, 0)),
                AppSpacing.gapLg,
                ReviveBpmGauge(reading: _reading(BpmStatus.good, 110, 24)),
                AppSpacing.gapLg,
                ReviveBpmGauge(reading: _reading(BpmStatus.tooSlow, 82, 47)),
                AppSpacing.gapLg,
                ReviveBpmGauge(reading: _reading(BpmStatus.tooFast, 148, 63)),
                AppSpacing.gapLg,
                Text(
                  'Compact variant (step-guide practice)',
                  style: context.text.bodySmall?.copyWith(
                    color: c.textTertiary,
                  ),
                ),
                AppSpacing.gapSm,
                ReviveBpmGauge(
                  reading: _reading(BpmStatus.good, 112, 30),
                  compact: true,
                ),

                const _Section('Buttons'),
                const ReviveButton(
                  label: 'BEGIN COMPRESSIONS',
                  onPressed: _noop,
                  icon: Icons.play_arrow,
                ),
                AppSpacing.gapMd,
                const ReviveButton(
                  label: 'SECONDARY ACTION',
                  onPressed: _noop,
                  variant: ReviveButtonVariant.secondary,
                ),
                AppSpacing.gapMd,
                const ReviveButton(
                  label: 'TERTIARY ACTION',
                  onPressed: _noop,
                  variant: ReviveButtonVariant.tertiary,
                ),
                AppSpacing.gapMd,
                const ReviveButton(label: 'DISABLED', onPressed: null),
                AppSpacing.gapMd,
                const ReviveButton(
                  label: 'DISABLED SECONDARY',
                  onPressed: null,
                  variant: ReviveButtonVariant.secondary,
                ),
                AppSpacing.gapMd,
                ReviveButton(
                  label: _loadingDemo ? 'LOADING' : 'TAP TO SEE LOADING',
                  onPressed: _demoLoading,
                  isLoading: _loadingDemo,
                ),
                AppSpacing.gapMd,
                Text(
                  'Critical size (64dp) — live CPR controls',
                  style: context.text.bodySmall?.copyWith(
                    color: c.textTertiary,
                  ),
                ),
                AppSpacing.gapSm,
                const ReviveButton(
                  label: 'STOP SESSION',
                  onPressed: _noop,
                  size: ReviveButtonSize.critical,
                  icon: Icons.stop,
                ),

                const _Section('Status pills'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    ReviveStatusPill(
                      label: 'LIVE',
                      icon: Icons.circle,
                      tone: ReviveCardTone.critical,
                    ),
                    ReviveStatusPill(
                      label: 'MIC ON',
                      icon: Icons.mic,
                      tone: ReviveCardTone.success,
                    ),
                    ReviveStatusPill(
                      label: 'AI OFFLINE',
                      icon: Icons.cloud_off,
                      tone: ReviveCardTone.caution,
                      semanticLabel: 'AI guidance offline',
                    ),
                    ReviveStatusPill(
                      label: 'LOGGED',
                      icon: Icons.check,
                      tone: ReviveCardTone.info,
                    ),
                  ],
                ),

                const _Section('Cards'),
                const ReviveCard(child: Text('Neutral card')),
                AppSpacing.gapMd,
                const ReviveCard(
                  tone: ReviveCardTone.info,
                  child: Text('Info — rescue breath prompt'),
                ),
                AppSpacing.gapMd,
                const ReviveCard(
                  tone: ReviveCardTone.caution,
                  child: Text('Caution — degraded but working'),
                ),
                AppSpacing.gapMd,
                const ReviveCard(
                  tone: ReviveCardTone.critical,
                  child: Text('Critical — stop and call for help'),
                ),
                AppSpacing.gapMd,
                const ReviveCard(
                  tone: ReviveCardTone.success,
                  child: Text('Success — correct technique'),
                ),

                const _Section('Voice activity'),
                const VoiceActivityIndicator(
                  state: VoiceActivityState.listening,
                ),
                AppSpacing.gapMd,
                const VoiceActivityIndicator(
                  state: VoiceActivityState.thinking,
                  transcript: 'He collapsed and is not breathing',
                ),
                AppSpacing.gapMd,
                const VoiceActivityIndicator(
                  state: VoiceActivityState.speaking,
                  transcript: 'Push hard and fast, centre of the chest.',
                ),
                AppSpacing.gapMd,
                const VoiceActivityIndicator(state: VoiceActivityState.idle),

                const _Section('Loading'),
                const Center(
                  child: ReviveLoadingView(message: 'Checking protocol...'),
                ),

                const _Section('Degraded states (amber)'),
                ReviveStateView.aiUnavailable(onRetry: _noop),
                AppSpacing.gapMd,
                ReviveStateView.micPermissionDenied(onOpenSettings: _noop),
                AppSpacing.gapMd,
                ReviveStateView.healthConnectUnavailable(),

                const _Section('Blocking state (red)'),
                ReviveStateView.sensorUnavailable(onUseTapMode: _noop),

                const _Section('Dialog'),
                ReviveButton(
                  label: 'SHOW DISCLAIMER DIALOG',
                  variant: ReviveButtonVariant.secondary,
                  onPressed: () => ReviveDialog.show(
                    context,
                    dialog: const ReviveDialog(
                      icon: Icons.warning_amber_rounded,
                      title: 'IMPORTANT NOTICE',
                      emphasis:
                          'Call emergency services first. This app augments a '
                          'rescue — it never replaces one.',
                      body:
                          'Revive provides CPR guidance only. It is not a '
                          'substitute for professional medical training. The '
                          'developers are not liable for any outcomes from '
                          'using this app.',
                      confirmLabel: 'I UNDERSTAND',
                    ),
                  ),
                ),
                AppSpacing.gapXxxl,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder callback so showcase buttons render in their enabled state.
void _noop() {}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxxl,
        bottom: AppSpacing.md,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium?.copyWith(
          color: context.colors.urgentAction,
        ),
      ),
    );
  }
}
