import 'package:flutter/material.dart';

import '../constants/emergency_protocols.dart';
import '../services/ollama_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/revive_button.dart';
import '../widgets/components/revive_card.dart';
import '../widgets/components/revive_state_view.dart';
import '../widgets/components/voice_activity_indicator.dart';

/// Optional AI triage gate shown before Live CPR Mode. This is the one place
/// in the app where the LLM does something a keyword match can't: telling
/// choking, drowning, and cardiac arrest apart from a bystander's own words,
/// and switching the protocol accordingly.
///
/// "Skip — Start CPR Now" is always on screen and never depends on the AI or
/// network — the life-saving path never waits on a classification.
class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final OllamaService _ollama = OllamaService();
  final SttService _stt = SttService();
  final TtsService _tts = TtsService();

  bool _isListening = false;
  bool _isThinking = false;
  bool _micDenied = false;
  String? _recognizedText;
  EmergencyProtocol? _activeProtocol;

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    _ollama.checkAvailability();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _tts.speak(
          "Quick check — what's happening? Or say start, to begin CPR right away.",
        );
      }
    });
  }

  @override
  void dispose() {
    _stt.stopListening();
    _tts.stop();
    super.dispose();
  }

  void _goToCpr() {
    Navigator.pushReplacementNamed(context, '/live');
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stopListening();
      setState(() => _isListening = false);
      return;
    }

    final ready = await _stt.initialize();
    if (!ready) {
      if (mounted) setState(() => _micDenied = true);
      return;
    }

    setState(() {
      _isListening = true;
      _micDenied = false;
      _recognizedText = null;
      _activeProtocol = null;
    });

    await _stt.startListening(
      onResult: (text) async {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _recognizedText = text;
        });

        final lower = text.toLowerCase();
        if (lower.contains('start') ||
            lower.contains('cpr') ||
            lower.contains('skip')) {
          _goToCpr();
          return;
        }

        if (!_ollama.isAvailable) {
          // No AI available to triage — the safe default is standard CPR,
          // never a dead end.
          _goToCpr();
          return;
        }

        setState(() => _isThinking = true);
        final result = await _ollama.classifyEmergency(text);
        if (!mounted) return;
        setState(() => _isThinking = false);

        switch (result) {
          case EmergencyType.choking:
            _showProtocol(chokingProtocol);
            break;
          case EmergencyType.drowning:
            _showProtocol(drowningProtocol);
            break;
          case EmergencyType.cardiacArrest:
          case EmergencyType.unknown:
            _goToCpr();
            break;
        }
      },
    );
  }

  void _showProtocol(EmergencyProtocol protocol) {
    setState(() => _activeProtocol = protocol);
    _tts.speak(protocol.voiceIntro);
  }

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------

  VoiceActivityState get _voiceState {
    if (_isThinking) return VoiceActivityState.thinking;
    if (_isListening) return VoiceActivityState.listening;
    return VoiceActivityState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: _activeProtocol == null
                    ? _buildAskState()
                    : _buildProtocolState(_activeProtocol!),
              ),
            ),
            Padding(
              padding: AppSpacing.pagePadding,
              // Always present, never gated on AI or network. This is the
              // escape hatch to the life-saving path.
              child: ReviveButton(
                label: 'SKIP — START CPR NOW',
                icon: Icons.arrow_forward,
                size: ReviveButtonSize.critical,
                variant: _activeProtocol == null
                    ? ReviveButtonVariant.primary
                    : ReviveButtonVariant.secondary,
                onPressed: _goToCpr,
              ),
            ),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: AppTouchTarget.minimum,
                height: AppTouchTarget.minimum,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(Icons.close, color: c.textSecondary, size: 20),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'QUICK CHECK',
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(color: c.textTertiary),
            ),
          ),
          const SizedBox(width: AppTouchTarget.minimum),
        ],
      ),
    );
  }

  Widget _buildAskState() {
    final c = context.colors;

    return Column(
      children: [
        AppSpacing.gapXl,
        Icon(
          Icons.record_voice_over_outlined,
          color: c.urgentAction.withValues(alpha: 0.45),
          size: 64,
        ),
        AppSpacing.gapLg,
        Text(
          "What's happening?",
          textAlign: TextAlign.center,
          style: context.text.headlineMedium?.copyWith(color: c.textPrimary),
        ),
        AppSpacing.gapSm,
        Text(
          'Optional — describe the situation in a few words so guidance can '
          'adapt. Or skip straight to CPR below.',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
        ),
        AppSpacing.gapXl,
        if (_micDenied)
          ReviveStateView.micPermissionDenied()
        else ...[
          _buildMicButton(),
          AppSpacing.gapLg,
          VoiceActivityIndicator(
            state: _voiceState,
            transcript: _recognizedText,
          ),
        ],
        if (!_ollama.isAvailable) ...[
          AppSpacing.gapLg,
          ReviveCard(
            tone: ReviveCardTone.caution,
            compact: true,
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: c.belowRangeWarning, size: 18),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    'AI triage is offline — describing the situation will just '
                    'start standard CPR.',
                    style: context.text.bodySmall?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        AppSpacing.gapLg,
      ],
    );
  }

  Widget _buildMicButton() {
    final c = context.colors;
    final motion = ResolvedMotion.of(context);

    return Semantics(
      button: true,
      label: _isListening
          ? 'Stop listening'
          : 'Describe the situation out loud',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedContainer(
          duration: motion.duration(AppMotion.fast),
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isListening ? c.urgentAction : c.surfaceRaised,
            border: Border.all(color: c.urgentAction, width: 2),
            boxShadow: _isListening && motion.shouldAnimate
                ? AppElevation.glow(c.urgentAction)
                : AppElevation.none,
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? c.onUrgentAction : c.urgentAction,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolState(EmergencyProtocol protocol) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapLg,
        ReviveCard(
          tone: ReviveCardTone.info,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: c.infoCalm, size: 24),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  protocol.voiceIntro,
                  style: context.text.titleMedium?.copyWith(
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapXl,
        Text(
          '${protocol.label.toUpperCase()} PROTOCOL',
          style: context.text.labelMedium?.copyWith(color: c.urgentAction),
        ),
        AppSpacing.gapMd,
        ...protocol.steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceOverlay,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: context.text.labelSmall?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    entry.value,
                    style: context.text.bodyLarge?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapSm,
        ReviveButton(
          label: 'PERSON IS UNRESPONSIVE — START CPR',
          onPressed: _goToCpr,
        ),
        AppSpacing.gapLg,
      ],
    );
  }
}
