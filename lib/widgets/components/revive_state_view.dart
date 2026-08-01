import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'revive_button.dart';
import 'revive_card.dart';

/// Severity of a non-content state. Deliberately three-tier, matching the
/// rhythm-feedback hierarchy:
///
/// * [degraded] — amber. Something is unavailable but the app still does its
///   job. AI unreachable, Health Connect missing, permission not yet granted.
///   The rescuer can keep going.
/// * [blocking] — red. The core function cannot run. Reserved, like the
///   emergency CTA, so red always means "this needs action now".
///
/// Using red for a dropped AI connection would be alarm inflation: it trains
/// the rescuer to ignore red at the moment red matters most.
enum ReviveStateSeverity { neutral, degraded, blocking }

/// Shared empty / error / unavailable presentation. Screens should render this
/// rather than inventing one-off failure text, so every failure mode in the
/// app looks and reads the same.
class ReviveStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final ReviveStateSeverity severity;

  /// Optional recovery action. Omit when there is genuinely nothing the user
  /// can do — a dead button is worse than no button.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shown under the action as a reminder that the core CPR path still works.
  /// Almost always worth setting on [ReviveStateSeverity.degraded].
  final String? reassurance;

  const ReviveStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.severity = ReviveStateSeverity.neutral,
    this.actionLabel,
    this.onAction,
    this.reassurance,
  });

  ReviveCardTone get _tone => switch (severity) {
    ReviveStateSeverity.neutral => ReviveCardTone.neutral,
    ReviveStateSeverity.degraded => ReviveCardTone.caution,
    ReviveStateSeverity.blocking => ReviveCardTone.critical,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = ReviveCard.accentFor(context, _tone) ?? c.noDataNeutral;

    return Semantics(
      container: true,
      label: '$title. $message',
      child: ReviveCard(
        tone: _tone,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: accent),
            AppSpacing.gapMd,
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleLarge?.copyWith(color: c.textPrimary),
            ),
            AppSpacing.gapSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.gapLg,
              ReviveButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: severity == ReviveStateSeverity.blocking
                    ? ReviveButtonVariant.primary
                    : ReviveButtonVariant.secondary,
                fullWidth: false,
              ),
            ],
            if (reassurance != null) ...[
              AppSpacing.gapMd,
              Text(
                reassurance!,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: c.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Named constructors for the failure modes this app actually has. ---
  // Centralised so the wording stays consistent and, critically, so every
  // degraded state repeats that core CPR coaching is unaffected.

  /// The Ollama/Gemma tunnel is unreachable.
  factory ReviveStateView.aiUnavailable({
    VoidCallback? onRetry,
  }) => ReviveStateView(
    icon: Icons.cloud_off,
    title: 'AI guidance offline',
    message:
        'Adaptive voice guidance needs a connection and cannot reach it right now.',
    severity: ReviveStateSeverity.degraded,
    actionLabel: onRetry != null ? 'Retry' : null,
    onAction: onRetry,
    reassurance:
        'Compression counting, rhythm coaching and the full CPR protocol '
        'all keep working without it.',
  );

  /// Accelerometer missing or not reporting — this one IS blocking, because
  /// compression tracking is the app's core function.
  factory ReviveStateView.sensorUnavailable({VoidCallback? onUseTapMode}) =>
      ReviveStateView(
        icon: Icons.sensors_off,
        title: 'Motion sensor unavailable',
        message:
            'This device is not reporting accelerometer data, so compressions '
            'cannot be counted automatically.',
        severity: ReviveStateSeverity.blocking,
        actionLabel: onUseTapMode != null ? 'Tap to count instead' : null,
        onAction: onUseTapMode,
        reassurance:
            'The metronome still sets the 110 BPM pace. Follow the beat and '
            'tap the screen with each push.',
      );

  /// Microphone permission denied — degrades hands-free voice, nothing else.
  factory ReviveStateView.micPermissionDenied({VoidCallback? onOpenSettings}) =>
      ReviveStateView(
        icon: Icons.mic_off,
        title: 'Microphone access needed',
        message:
            'Hands-free voice questions and spoken emergency dialing need '
            'microphone permission.',
        severity: ReviveStateSeverity.degraded,
        actionLabel: onOpenSettings != null ? 'Open settings' : null,
        onAction: onOpenSettings,
        reassurance:
            'You can still use every on-screen control, and dial emergency '
            'services directly from your phone.',
      );

  /// Health Connect absent or permission refused — purely a logging feature.
  factory ReviveStateView.healthConnectUnavailable() => const ReviveStateView(
    icon: Icons.privacy_tip_outlined,
    title: 'Incident logging unavailable',
    message:
        'Health Connect is not set up on this device, so this session will '
        'not be saved for EMS handoff.',
    severity: ReviveStateSeverity.degraded,
    reassurance: 'This does not affect CPR coaching in any way.',
  );
}

/// Loading placeholder. Sized to the content it replaces where possible, so
/// the layout does not jump when real content arrives.
class ReviveLoadingView extends StatelessWidget {
  final String? message;
  final double size;

  const ReviveLoadingView({super.key, this.message, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      label: message ?? 'Loading',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(c.urgentAction),
            ),
          ),
          if (message != null) ...[
            AppSpacing.gapMd,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
