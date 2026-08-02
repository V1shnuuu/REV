import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../constants/app_config.dart';
import '../services/audio_service.dart';
import '../services/health_connect_service.dart';
import '../services/motion_service.dart';
import '../services/ollama_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/revive_bpm_gauge.dart';
import '../widgets/components/revive_button.dart';
import '../widgets/components/revive_card.dart';
import '../widgets/components/revive_state_view.dart';
import '../widgets/components/voice_activity_indicator.dart';
import '../widgets/cpr_body_animation.dart';

class LiveCprScreen extends StatefulWidget {
  const LiveCprScreen({super.key});

  @override
  State<LiveCprScreen> createState() => _LiveCprScreenState();
}

class _LiveCprScreenState extends State<LiveCprScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioService _audio = AudioService();
  final MotionService _motion = MotionService();
  final TtsService _tts = TtsService();
  final OllamaService _ollama = OllamaService();
  final SttService _stt = SttService();
  final HealthConnectService _healthConnect = HealthConnectService();

  bool _isActive = false;
  bool _showBreathPrompt = false;
  int _lastBreathPromptAt = 0;
  StreamSubscription<BpmReading>? _bpmSubscription;
  Timer? _elapsedTimer;
  Timer? _availabilityTimer;
  int _elapsedSeconds = 0;
  int _fallbackTipIndex = 0;
  BpmStatus _lastHapticStatus = BpmStatus.waiting;

  // Voice assistant state
  bool _isListening = false;
  bool _isAiThinking = false;
  bool _micDenied = false;
  String? _aiResponse;
  String? _recognizedText;

  @override
  void initState() {
    super.initState();
    _tts.initialize();
    _tts.setOnComplete(() {
      if (mounted) {
        setState(() {
          _aiResponse = null;
          _recognizedText = null;
        });
        _audio.setVolume(1.0); // Restore metronome volume
        if (_isActive) _stt.resumeListening();
      }
    });
    _ollama.checkAvailability();
    _stt.initialize();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.stopMetronome();
    _motion.stopListening();
    _motion.dispose();
    _bpmSubscription?.cancel();
    _elapsedTimer?.cancel();
    _availabilityTimer?.cancel();
    _stt.stopListening();
    _tts.setOnComplete(null);
    _tts.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _audio.stopMetronome();
      _stt.stopListening();
      _tts.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_isActive) {
        _audio.startMetronome();
        _startContinuousVoice(); // Restart hands-free assistant
      }
    }
  }

  Future<void> _startSession() async {
    // Request phone call permission safely in background so it doesn't block the critical CPR timer
    _requestPhonePermissionSafely();

    setState(() {
      _isActive = true;
      _showBreathPrompt = false;
      _lastBreathPromptAt = 0;
      _elapsedSeconds = 0;
      _lastHapticStatus = BpmStatus.waiting;
    });

    _audio.startMetronome();
    _motion.reset();
    _motion.startListening();
    _setupBpmSubscription();

    // Keep the availability flag fresh through the session: the AI can drop
    // off (or come back) mid-CPR since it always depends on the ngrok tunnel.
    // Core compression coaching above never depends on this timer.
    _availabilityTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final wasAvailable = _ollama.isAvailable;
      final nowAvailable = await _ollama.checkAvailability();
      if (mounted && wasAvailable != nowAvailable) setState(() {});
    });
  }

  Future<void> _requestPhonePermissionSafely() async {
    try {
      await Permission.phone.request();
    } catch (e) {
      // Ignore safely
    }
  }

  Future<void> _handleEmergencyCall() async {
    await FlutterPhoneDirectCaller.callNumber(AppConfig.emergencyNumber);
  }

  bool _isEmergencyPhrase(String text) {
    final lower = text.toLowerCase();
    return lower.contains(AppConfig.emergencyNumber) ||
        lower.contains('emergency') ||
        lower.contains('ambulance');
  }

  void _setupBpmSubscription() {
    _bpmSubscription = _motion.bpmStream.listen((reading) {
      if (mounted) {
        // Distinct haptic when the rate crosses into or out of the target
        // band, so the rescuer feels the correction with the phone against
        // the chest and their eyes on the patient rather than the screen.
        if (reading.status != _lastHapticStatus &&
            reading.status != BpmStatus.waiting) {
          _lastHapticStatus = reading.status;
          AppHaptics.rangeTransition();
        }

        // Only update local state if we need to trigger heavy logic like breath prompts
        if (reading.compressionCount > 0 &&
            reading.compressionCount % 30 == 0 &&
            reading.compressionCount != _lastBreathPromptAt) {
          _lastBreathPromptAt = reading.compressionCount;
          _promptRescueBreaths();
        }
      }
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    _tts.speak(
      'Follow the rhythm. Push hard and fast. Voice assistant is active. Just speak your question anytime.',
    );
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted && _isActive) {
        _startContinuousVoice();
      }
    });
  }

  void _stopSession() {
    final int finalCompressionCount = _motion.compressionCount;
    final Duration finalDuration = Duration(seconds: _elapsedSeconds);

    _audio.stopMetronome();
    _motion.stopListening();
    _bpmSubscription?.cancel();
    _elapsedTimer?.cancel();
    _availabilityTimer?.cancel();
    _stt.stopListening();

    setState(() {
      _isActive = false;
      _isListening = false;
    });
    _tts.speak('CPR session ended. Good job.');

    // Only log real sessions, not an accidental tap on Begin/Stop.
    if (finalCompressionCount >= 5) {
      _logIncidentToHealthConnect(finalCompressionCount, finalDuration);
    }
  }

  /// Fire-and-forget: never blocks or interrupts the CPR flow above. Shows a
  /// brief confirmation if it succeeds; stays silent if Health Connect isn't
  /// available on this device (Play Store install of the Health Connect app
  /// is required on Android 13 and below).
  Future<void> _logIncidentToHealthConnect(
    int compressionCount,
    Duration duration,
  ) async {
    final guidanceSummary = _ollama.isAvailable
        ? 'AI-adaptive voice guidance was used during this session.'
        : 'AI guidance was offline; static protocol coaching was used.';

    final logged = await _healthConnect.logCprIncident(
      compressionCount: compressionCount,
      duration: duration,
      guidanceSummary: guidanceSummary,
    );

    if (mounted && logged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident logged to Health Connect for EMS handoff.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _promptRescueBreaths() {
    setState(() => _showBreathPrompt = true);
    // Heavier cue: this interrupts the compression rhythm, so it has to be
    // felt through the ongoing beat.
    AppHaptics.prompt();
    _tts.speak('Give 2 rescue breaths now. Then continue compressions.');
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showBreathPrompt = false);
    });
  }

  /// Auto-start continuous hands-free voice listening
  Future<void> _startContinuousVoice() async {
    final initialized = await _stt.initialize();
    if (!initialized) {
      // Previously this returned silently, leaving the rescuer with a dead
      // mic and no explanation. Surface it as a degraded state instead —
      // everything else on this screen keeps working.
      if (mounted) setState(() => _micDenied = true);
      return;
    }

    setState(() {
      _isListening = true;
      _micDenied = false;
    });
    _audio.setVolume(0.3); // Lower volume to help mic hear clearly

    await _stt.startContinuousListening(
      onResult: (recognizedText) async {
        if (!mounted || _isAiThinking) return;

        // CHECK FOR EMERGENCY PHRASES FIRST
        if (_isEmergencyPhrase(recognizedText)) {
          await _handleEmergencyCall();
          return;
        }

        setState(() {
          _isAiThinking = true;
          _aiResponse = null;
          _recognizedText = recognizedText; // Show what we heard
        });

        // Mute metronome while AI processes & speaks
        _audio.setVolume(0.1);
        await _stt.pauseListening();

        // Skip the network round-trip entirely when we already know the AI
        // tunnel is down — an emergency is the worst possible moment for a
        // rescuer to wait out a 30s timeout for silence. Core CPR coaching
        // above (metronome, compression count, breath prompts) never depends
        // on this and keeps running regardless.
        final String response = _ollama.isAvailable
            ? (await _ollama.emergencyChatAnswer(recognizedText)) ??
                  _offlineFallbackTip()
            : _offlineFallbackTip();

        if (mounted) {
          setState(() {
            _isAiThinking = false;
            _aiResponse = response;
          });

          // Speak the response - resumption is handled by the TTS completion handler
          await _tts.speak(_aiResponse!);

          // Safety Fallback: Ensure mic resumes even if TTS handler fails to fire
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted && _isActive && !_stt.isListening && !_tts.isSpeaking) {
              _stt.resumeListening();
              _audio.setVolume(1.0);
            }
          });
        }
      },
    );
  }

  /// Canned, zero-network reassurance used whenever the AI tunnel is down,
  /// so a dropped connection still gives the rescuer something useful to
  /// hear instead of dead air or an apology.
  String _offlineFallbackTip() {
    const tips = [
      "AI guidance is offline. Keep pushing hard and fast, 100 to 120 per minute.",
      "No connection right now — you're doing it right. Let the chest fully recoil between pushes.",
      "AI assistant unavailable. Push at least 2 inches deep, center of the chest.",
      "Connection lost, but core coaching keeps running. After 30 compressions, give 2 rescue breaths.",
    ];
    final tip = tips[_fallbackTipIndex % tips.length];
    _fallbackTipIndex++;
    return tip;
  }

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------

  String get _elapsedFormatted {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _closeScreen() {
    if (_isActive) _stopSession();
    Navigator.pop(context);
  }

  /// Maps the screen's individual voice flags onto a single indicator state.
  VoiceActivityState get _voiceState {
    if (_isAiThinking) return VoiceActivityState.thinking;
    if (_aiResponse != null) return VoiceActivityState.speaking;
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
            if (_isActive)
              Expanded(child: _buildActiveSession())
            else
              Expanded(child: _buildIdleState()),
            _buildBottomControls(),
            AppSpacing.gapSm,
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession() {
    return StreamBuilder<BpmReading>(
      stream: _motion.bpmStream,
      initialData: BpmReading.initial,
      builder: (context, snapshot) {
        final reading = snapshot.data ?? BpmReading.initial;

        return LayoutBuilder(
          builder: (context, constraints) {
            // The chest animation is the first thing sacrificed on short
            // screens — the gauge is what the rescuer actually needs, so it
            // keeps its full size while the illustration shrinks.
            final bool isShort = constraints.maxHeight < 560;

            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  if (_showBreathPrompt) ...[
                    _buildBreathPrompt(),
                    AppSpacing.gapMd,
                  ],
                  Semantics(
                    label:
                        'Chest compression animation. '
                        'Tap to register a compression manually.',
                    button: true,
                    onTap: _motion.simulateCompression,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _motion.simulateCompression,
                      child: SizedBox(
                        height: isShort ? 140 : constraints.maxHeight * 0.34,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: CprBodyAnimation(
                            feedbackColor: ReviveBpmGauge.accentFor(
                              context,
                              reading.status,
                            ),
                            feedbackText: ReviveBpmGauge.labelFor(
                              reading.status,
                            ),
                            compressionCount: reading.compressionCount,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,
                  _buildCycleProgress(reading),
                  AppSpacing.gapMd,
                  ReviveBpmGauge(reading: reading),
                  AppSpacing.gapMd,
                  if (_micDenied)
                    ReviveStateView.micPermissionDenied(
                      onOpenSettings: openAppSettings,
                    )
                  else
                    VoiceActivityIndicator(
                      state: _voiceState,
                      transcript: _aiResponse ?? _recognizedText,
                    ),
                  AppSpacing.gapMd,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCycleProgress(BpmReading reading) {
    final c = context.colors;
    final int inCycle = reading.compressionCount > 0
        ? (reading.compressionCount % 30 == 0
              ? 30
              : reading.compressionCount % 30)
        : 0;

    return Semantics(
      label: '$inCycle of 30 compressions in this cycle',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CYCLE PROGRESS  ',
                style: context.text.labelSmall?.copyWith(color: c.textTertiary),
              ),
              Text(
                '$inCycle / 30',
                style: context.text.titleMedium?.copyWith(color: c.textPrimary),
              ),
            ],
          ),
          AppSpacing.gapXs,
          ClipRRect(
            borderRadius: AppRadius.borderXs,
            child: LinearProgressIndicator(
              value: inCycle / 30,
              minHeight: 4,
              backgroundColor: c.surfaceOverlay,
              valueColor: AlwaysStoppedAnimation<Color>(c.urgentAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              color: c.urgentAction.withValues(alpha: 0.35),
              size: 72,
            ),
            AppSpacing.gapXl,
            Text(
              'READY TO START',
              style: context.text.headlineLarge?.copyWith(color: c.textPrimary),
            ),
            AppSpacing.gapSm,
            Text(
              'Place the phone on a flat surface, or hold it against the chest '
              'while you push.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            AppSpacing.gapXl,
            ReviveCard(
              tone: ReviveCardTone.critical,
              child: Row(
                children: [
                  Icon(Icons.phone_in_talk, color: c.urgentAction, size: 22),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      'Call ${AppConfig.emergencyNumber} first if you have not '
                      'already. Say "emergency" any time to dial hands-free.',
                      style: context.text.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathPrompt() {
    final c = context.colors;
    return ReviveCard(
      tone: ReviveCardTone.info,
      child: Row(
        children: [
          Icon(Icons.air, color: c.infoCalm, size: 28),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESCUE BREATHS',
                  style: context.text.labelSmall?.copyWith(color: c.infoCalm),
                ),
                AppSpacing.gapXs,
                Text(
                  'Give 2 breaths now, then continue compressions',
                  style: context.text.bodyMedium?.copyWith(
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            label: 'Close CPR mode',
            button: true,
            onTap: _closeScreen,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _closeScreen,
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
          AppSpacing.hGapSm,
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_isActive)
                  const ReviveStatusPill(
                    label: 'LIVE',
                    icon: Icons.fiber_manual_record,
                    tone: ReviveCardTone.critical,
                    semanticLabel: 'Session is live',
                  ),
                if (_isActive && _isListening && !_micDenied)
                  const ReviveStatusPill(
                    label: 'MIC ON',
                    icon: Icons.mic,
                    tone: ReviveCardTone.success,
                    semanticLabel: 'Microphone is listening',
                  ),
                if (!_ollama.isAvailable)
                  const ReviveStatusPill(
                    label: 'AI OFFLINE',
                    icon: Icons.cloud_off,
                    tone: ReviveCardTone.caution,
                    semanticLabel:
                        'AI guidance offline. Core CPR coaching still active.',
                  ),
                if (!_isActive)
                  Text(
                    'LIVE CPR MODE',
                    style: context.text.labelMedium?.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          SizedBox(
            width: 56,
            child: _isActive
                ? Semantics(
                    label: 'Elapsed time $_elapsedFormatted',
                    excludeSemantics: true,
                    child: Text(
                      _elapsedFormatted,
                      textAlign: TextAlign.end,
                      style: context.text.titleMedium?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: ReviveButton(
        label: _isActive ? 'STOP SESSION' : 'BEGIN COMPRESSIONS',
        icon: _isActive ? Icons.stop : Icons.play_arrow,
        // Critical size: this is hit one-handed, under stress, often without
        // looking directly at it.
        size: ReviveButtonSize.critical,
        variant: _isActive
            ? ReviveButtonVariant.secondary
            : ReviveButtonVariant.primary,
        onPressed: _isActive ? _stopSession : _startSession,
      ),
    );
  }
}
