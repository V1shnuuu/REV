import 'package:flutter/material.dart';

import '../constants/app_config.dart';
import '../services/ollama_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/revive_button.dart';
import '../widgets/components/revive_card.dart';
import '../widgets/disclaimer_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late AnimationController _fadeInController;
  final OllamaService _ollama = OllamaService();
  bool _disclaimerShown = false;
  bool _aiReachable = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _fadeInController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );

    _checkOllama();
  }

  /// Warms the shared OllamaService availability flag so downstream screens
  /// (triage, live CPR) can branch immediately instead of blocking on a
  /// first-use network check, and surfaces reachability here so the rescuer
  /// knows before starting whether adaptive guidance will be available.
  Future<void> _checkOllama() async {
    final available = await _ollama.checkAvailability();
    if (mounted) setState(() => _aiReachable = available);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Looping ambient animation is decorative, so it is skipped entirely under
    // reduce-motion rather than merely shortened. The fade-in still runs (at
    // zero duration) so the screen never stays invisible.
    final motion = ResolvedMotion.of(context);
    if (motion.shouldAnimate) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_breatheController.isAnimating) {
        _breatheController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _breatheController.stop();
    }
    _fadeInController.duration = motion.duration(AppMotion.slow);
    _fadeInController.forward();

    if (!_disclaimerShown) {
      _disclaimerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) DisclaimerDialog.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.surfacePrimary,
      body: Stack(
        children: [
          _buildAmbientBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInController,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // IntrinsicHeight gives the Column a determinate height so
                    // the Spacers below resolve. Without it the scroll view
                    // hands down an unbounded height and any flex child throws.
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: AppSpacing.pagePadding,
                        child: Column(
                          children: [
                            AppSpacing.gapXxl,
                            _buildBrand(),
                            const Spacer(),
                            _buildPrimaryAction(),
                            AppSpacing.gapXxl,
                            _buildSecondaryActions(),
                            const Spacer(),
                            _buildDisclaimerStrip(),
                            AppSpacing.gapXl,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2 + (_breatheController.value * 0.3),
            colors: [c.urgentAction.withValues(alpha: 0.10), c.surfacePrimary],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildBrand() {
    final c = context.colors;
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            'REVIVE',
            style: context.text.headlineLarge?.copyWith(
              color: c.textPrimary,
              letterSpacing: 8,
            ),
          ),
        ),
        AppSpacing.gapSm,
        Text(
          'EVERY SECOND COUNTS',
          style: context.text.labelSmall?.copyWith(color: c.urgentAction),
        ),
      ],
    );
  }

  /// The one unmistakable action on this screen. Everything else is visually
  /// subordinate so "what do I tap" is answerable in under a second.
  Widget _buildPrimaryAction() {
    final c = context.colors;

    return Semantics(
      button: true,
      label: 'Start CPR. Begins a guided compression session.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/triage'),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.04);
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 216,
            height: 216,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.urgentAction,
              boxShadow: AppElevation.glow(c.urgentAction, intensity: 1.6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: c.onUrgentAction, size: 52),
                AppSpacing.gapSm,
                Text(
                  'START',
                  style: context.text.headlineMedium?.copyWith(
                    color: c.onUrgentAction,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'CPR',
                  style: context.text.titleMedium?.copyWith(
                    color: c.onUrgentAction.withValues(alpha: 0.85),
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      children: [
        ReviveButton(
          label: 'TRAINING MODE',
          icon: Icons.school_outlined,
          variant: ReviveButtonVariant.secondary,
          onPressed: () => Navigator.pushNamed(context, '/guide'),
        ),
        AppSpacing.gapMd,
        ReviveButton(
          label: 'ASK THE ASSISTANT',
          icon: Icons.forum_outlined,
          variant: ReviveButtonVariant.secondary,
          onPressed: () => Navigator.pushNamed(context, '/chat'),
        ),
        AppSpacing.gapMd,
        // Reachability shown up front: the rescuer learns whether adaptive
        // guidance is available before they need it, not mid-compression.
        Align(
          alignment: Alignment.center,
          child: ReviveStatusPill(
            label: _aiReachable ? 'AI GUIDANCE READY' : 'AI OFFLINE',
            icon: _aiReachable ? Icons.cloud_done : Icons.cloud_off,
            tone: _aiReachable
                ? ReviveCardTone.success
                : ReviveCardTone.caution,
            semanticLabel: _aiReachable
                ? 'AI guidance is available'
                : 'AI guidance offline. CPR coaching works without it.',
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerStrip() {
    final c = context.colors;
    return ReviveCard(
      compact: true,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: c.textTertiary, size: 18),
          AppSpacing.hGapMd,
          Expanded(
            child: Text(
              'Guidance only — not a substitute for professional training. '
              'Always call ${AppConfig.emergencyNumber} first.',
              style: context.text.bodySmall?.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
