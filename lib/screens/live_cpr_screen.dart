import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../services/motion_service.dart';
import '../services/tts_service.dart';
import '../services/ollama_service.dart';
import '../services/stt_service.dart';
import '../services/health_connect_service.dart';
import '../constants/app_config.dart';
import '../widgets/cpr_body_animation.dart';
import '../widgets/bpm_gauge.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

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

  BpmReading _currentReading = BpmReading.initial;
  bool _isActive = false;
  bool _showBreathPrompt = false;
  int _lastBreathPromptAt = 0;
  StreamSubscription<BpmReading>? _bpmSubscription;
  Timer? _elapsedTimer;
  Timer? _availabilityTimer;
  int _elapsedSeconds = 0;
  int _fallbackTipIndex = 0;

  // Voice assistant state
  bool _isListening = false;
  bool _isAiThinking = false;
  String? _aiResponse;
  String? _recognizedText;
  late AnimationController _micPulseController;

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
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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
    _micPulseController.dispose();
    _stt.stopListening();
    _tts.setOnComplete(null);
    _tts.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
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

    _tts.speak('Follow the rhythm. Push hard and fast. Voice assistant is active. Just speak your question anytime.');
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
  Future<void> _logIncidentToHealthConnect(int compressionCount, Duration duration) async {
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
    _tts.speak('Give 2 rescue breaths now. Then continue compressions.');
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showBreathPrompt = false);
    });
  }

  /// Auto-start continuous hands-free voice listening
  Future<void> _startContinuousVoice() async {
    final initialized = await _stt.initialize();
    if (!initialized) return;

    setState(() => _isListening = true);
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
            ? (await _ollama.emergencyChatAnswer(recognizedText)) ?? _offlineFallbackTip()
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

  Color _getFeedbackColor(BpmStatus status) {
    switch (status) {
      case BpmStatus.good: return const Color(0xFF2ECC71);
      case BpmStatus.tooSlow: return const Color(0xFFF39C12);
      case BpmStatus.tooFast: return const Color(0xFFE74C3C);
      case BpmStatus.waiting: return const Color(0xFFE63946);
    }
  }

  String _getFeedbackText(BpmStatus status) {
    switch (status) {
      case BpmStatus.good: return 'PERFECT RHYTHM';
      case BpmStatus.tooSlow: return 'PUSH FASTER';
      case BpmStatus.tooFast: return 'SLOW DOWN';
      case BpmStatus.waiting: return 'FOLLOW THE RHYTHM';
    }
  }

  String get _elapsedFormatted {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                _buildHeader(),
                if (!_isActive) const Spacer(),
                if (_showBreathPrompt) _buildBreathPrompt(),
                if (_isActive) ...[
                  Expanded(
                    child: StreamBuilder<BpmReading>(
                      stream: _motion.bpmStream,
                      initialData: BpmReading.initial,
                      builder: (context, snapshot) {
                        final reading = snapshot.data ?? BpmReading.initial;
                        final statusColor = _getFeedbackColor(reading.status);
                        final statusText = _getFeedbackText(reading.status);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isSmall = constraints.maxHeight < 400;
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      _motion.simulateCompression();
                                    },
                                    child: SizedBox(
                                      height: isSmall ? 150 : constraints.maxHeight * 0.45,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: CprBodyAnimation(
                                          feedbackColor: statusColor,
                                          feedbackText: statusText,
                                          compressionCount: reading.compressionCount,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE63946).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'CYCLE PROGRESS: ',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFE63946).withValues(alpha: 0.7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          '${reading.compressionCount > 0 && reading.compressionCount % 30 == 0 ? 30 : reading.compressionCount % 30} / 30',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFE63946),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: BpmGauge(reading: reading),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  _buildStartPrompt(),
                  const Spacer(),
                ],
                if (_isActive) ...[
                  if (_isAiThinking || _aiResponse != null || _recognizedText != null)
                    _buildSubtleVoiceInfo(),
                ],
                _buildBottomControls(),
                const SizedBox(height: 8),
              ],
            ),

            // Subtle indicator for active listening is now moved to the header for better visibility
          ],
        ),
      ),
    );
  }

  /// Always-on mic indicator showing voice assistant is active
  Widget _buildMicIndicator() {
    _micPulseController.repeat(reverse: true);
    return AnimatedBuilder(
      animation: _micPulseController,
      builder: (context, child) {
        final glow = _micPulseController.value * 0.5;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2ECC71).withValues(alpha: glow),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'MIC ON',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2ECC71),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shown whenever the AI tunnel is unreachable, so it's visually obvious
  /// that core CPR coaching (compressions, rhythm, breath prompts) is still
  /// running fine on-device — only the adaptive voice assistant is degraded.
  Widget _buildAiOfflinePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white54, size: 12),
          const SizedBox(width: 5),
          Text(
            'AI OFFLINE',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle voice assistant info displayed at the bottom
  Widget _buildSubtleVoiceInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE63946).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_recognizedText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'YOU: "$_recognizedText"',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            children: [
              if (_isAiThinking)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: Color(0xFFE63946),
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.smart_toy, color: Color(0xFFE63946), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isAiThinking
                      ? 'Gemma 4 is thinking...'
                      : _aiResponse ?? 'Listening...',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isActive) _stopSession();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
          const Spacer(),
          if (_isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE', style: GoogleFonts.inter(color: const Color(0xFFE63946), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ]),
            ),
            const SizedBox(width: 8),
            // Integrated Mic Indicator in header to avoid overlapping with AI response
            if (_isListening) _buildMicIndicator(),
            if (!_ollama.isAvailable) ...[
              const SizedBox(width: 8),
              _buildAiOfflinePill(),
            ],
            const Spacer(),
            Text(_elapsedFormatted, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
          ] else ...[
            Text('LIVE CPR MODE', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2)),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _buildBreathPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3498DB).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3498DB).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.air, color: Color(0xFF3498DB), size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RESCUE BREATHS', style: GoogleFonts.inter(color: const Color(0xFF3498DB), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('Give 2 breaths now, then continue', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        ])),
      ]),
    );
  }

  Widget _buildStartPrompt() {
    return Column(children: [
      Icon(Icons.fitness_center, color: const Color(0xFFE63946).withValues(alpha: 0.3), size: 80),
      const SizedBox(height: 24),
      Text('READY TO START', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Place phone on a flat surface\nor hold it while doing CPR',
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isActive ? _stopSession : _startSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isActive ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE63946),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_isActive ? Icons.stop : Icons.play_arrow, size: 24),
            const SizedBox(width: 8),
            Text(_isActive ? 'STOP SESSION' : 'BEGIN COMPRESSIONS',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ]),
        ),
      ),
    );
  }
}
