import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// What the voice pipeline is currently doing. Each state gets its own colour,
/// icon, label AND waveform behaviour, so it is distinguishable without colour
/// vision and without motion.
enum VoiceActivityState {
  /// Mic is open, waiting for the rescuer to speak.
  listening,

  /// Request in flight to the AI.
  thinking,

  /// TTS is speaking a response.
  speaking,

  /// Mic closed / pipeline inactive.
  idle,
}

/// Voice-pipeline indicator with an animated waveform. Deliberately not a chat
/// bubble: during CPR the rescuer is not reading a transcript, they need to
/// know at a glance whether the app is hearing them, thinking, or talking.
///
/// Under the platform reduce-motion setting the waveform renders as a static
/// bar pattern at fixed heights rather than animating — the state is still
/// fully legible from icon, label and colour.
class VoiceActivityIndicator extends StatefulWidget {
  final VoiceActivityState state;

  /// Optional transcript of what was just heard, or the response being spoken.
  final String? transcript;

  const VoiceActivityIndicator({
    super.key,
    required this.state,
    this.transcript,
  });

  @override
  State<VoiceActivityIndicator> createState() => _VoiceActivityIndicatorState();
}

class _VoiceActivityIndicatorState extends State<VoiceActivityIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const int _barCount = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation(bool shouldAnimate) {
    final active = shouldAnimate && widget.state != VoiceActivityState.idle;
    if (active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  ({Color color, IconData icon, String label}) _presentation(BuildContext ctx) {
    final c = ctx.colors;
    return switch (widget.state) {
      VoiceActivityState.listening => (
        color: c.inRangeSuccess,
        icon: Icons.mic,
        label: 'LISTENING',
      ),
      VoiceActivityState.thinking => (
        color: c.infoCalm,
        icon: Icons.auto_awesome,
        label: 'THINKING',
      ),
      VoiceActivityState.speaking => (
        color: c.urgentAction,
        icon: Icons.volume_up,
        label: 'SPEAKING',
      ),
      VoiceActivityState.idle => (
        color: c.noDataNeutral,
        icon: Icons.mic_off,
        label: 'MIC OFF',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = ResolvedMotion.of(context);
    final p = _presentation(context);

    // Driven here rather than in initState because reduce-motion is a
    // MediaQuery value and can change while this widget is mounted.
    _syncAnimation(motion.shouldAnimate);

    return Semantics(
      liveRegion: true,
      label: widget.transcript == null
          ? 'Voice assistant ${p.label.toLowerCase()}'
          : 'Voice assistant ${p.label.toLowerCase()}. ${widget.transcript}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: p.color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(p.icon, size: 16, color: p.color),
                AppSpacing.hGapSm,
                Text(
                  p.label,
                  style: context.text.labelSmall?.copyWith(color: p.color),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: SizedBox(
                    height: 20,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        painter: _WaveformPainter(
                          progress: _controller.value,
                          color: p.color,
                          barCount: _barCount,
                          animated: motion.shouldAnimate,
                          state: widget.state,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.transcript != null) ...[
              AppSpacing.gapSm,
              Text(
                widget.transcript!,
                style: context.text.bodyMedium?.copyWith(color: c.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int barCount;
  final bool animated;
  final VoiceActivityState state;

  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.barCount,
    required this.animated,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barWidth = 3.0;
    final gap = (size.width - barCount * barWidth) / (barCount - 1);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final double factor;
      if (!animated || state == VoiceActivityState.idle) {
        // Static fallback: a fixed, obviously-inert pattern. Still reads as a
        // waveform, carries no motion.
        factor = state == VoiceActivityState.idle ? 0.18 : 0.45;
      } else if (state == VoiceActivityState.thinking) {
        // Travelling pulse — distinct from listening's symmetric bounce.
        final phase = (progress * barCount - i) % barCount;
        factor = 0.2 + 0.8 * math.exp(-math.pow(phase, 2) / 0.6);
      } else {
        // Listening / speaking: staggered sine bounce.
        final phase = progress * 2 * math.pi + i * 0.7;
        factor = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase));
      }

      final barHeight = (size.height * factor).clamp(3.0, size.height);
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - barHeight / 2, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.animated != animated ||
      old.state != state;
}
