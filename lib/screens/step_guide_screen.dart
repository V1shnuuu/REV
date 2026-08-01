import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/cpr_steps.dart';
import '../services/tts_service.dart';
import '../services/ollama_service.dart';
import '../services/motion_service.dart';
import '../widgets/cpr_instruction_animation.dart';
import '../widgets/bpm_gauge.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class StepGuideScreen extends StatefulWidget {
  const StepGuideScreen({super.key});

  @override
  State<StepGuideScreen> createState() => _StepGuideScreenState();
}

class _StepGuideScreenState extends State<StepGuideScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color primaryRed = Color(0xFFE63946);
  static const Color bgColor = Color(0xFF0A0A0F);
  static const Color cardColor = Color(0xFF1A1A2E);
  static const Color successColor = Color(0xFF2ECC71);
  
  final PageController _pageController = PageController();
  final TtsService _tts = TtsService();
  final OllamaService _ollama = OllamaService();
  final MotionService _motionService = MotionService();
  
  int _currentStep = 0;
  String? _aiTip;
  bool _loadingTip = false;
  final Map<int, String> _aiTipsCache = {};
  
  late AnimationController _iconPulseController;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _tts.initialize().then((_) => _speakCurrentStep());
    _loadAiTip(0);
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to motion service for completion
    _motionService.bpmStream.listen((reading) {
      if (mounted && _isSimulating && reading.compressionCount >= 30) {
        _motionService.stopListening();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && cprSteps[_currentStep].visualType == StepVisualType.compressionPractice) {
            _goToNextStep();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache images for faster load
    precacheImage(const AssetImage('assets/CPR_HAND PLACEMENT.png'), context);
    precacheImage(const AssetImage('assets/CPR_RESCUE_BREATH.PNG'), context);
    precacheImage(const AssetImage('assets/CHIN_POSITION.jpeg'), context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionService.dispose();
    _pageController.dispose();
    _iconPulseController.dispose();
    _tts.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _tts.stop();
      _motionService.stopListening();
    }
  }

  void _speakCurrentStep() {
    if (_currentStep < cprSteps.length) {
      _tts.speak(cprSteps[_currentStep].voiceScript);
    }
  }

  Future<void> _loadAiTip(int stepIndex) async {
    if (_aiTipsCache.containsKey(stepIndex)) {
      setState(() {
        _aiTip = _aiTipsCache[stepIndex];
        _loadingTip = false;
      });
      return;
    }

    if (!_ollama.isAvailable) await _ollama.checkAvailability();
    if (!_ollama.isAvailable) return;
    
    setState(() { _loadingTip = true; _aiTip = null; });
    final tip = await _ollama.generateTip(cprSteps[stepIndex].title, cprSteps[stepIndex].instruction);
    
    if (mounted) {
      setState(() { 
        _aiTip = tip; 
        _loadingTip = false; 
        if (tip != null) {
          _aiTipsCache[stepIndex] = tip;
        }
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStep = index;
      _aiTip = null;
      _isSimulating = false;
      _motionService.stopListening();
      _motionService.reset();
    });
    _tts.stop(); // Stop previous voice immediately
    _speakCurrentStep();
    _loadAiTip(index);
  }

  void _startSimulation() {
    setState(() {
      _isSimulating = true;
    });
    _motionService.startListening();
  }

  void _goToNextStep() {
    if (_currentStep < cprSteps.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _tts.stop();
      Navigator.pushReplacementNamed(context, '/live');
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: cprSteps.length,
                itemBuilder: (context, index) => _buildStepPage(cprSteps[index]),
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Semantics(
            label: 'Go Back',
            button: true,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            label: 'Step ${_currentStep + 1} of ${cprSteps.length}',
            child: Text('STEP ${_currentStep + 1} OF ${cprSteps.length}',
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2)),
          ),
          const Spacer(),
          Semantics(
            label: 'Repeat Voice Instruction',
            button: true,
            child: GestureDetector(
              onTap: _speakCurrentStep,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primaryRed.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.volume_up, color: primaryRed, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Semantics(
      hidden: true, // Decorative element
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(cprSteps.length, (i) => Expanded(
            child: Container(
              height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                color: i <= _currentStep ? primaryRed : Colors.white.withOpacity(0.1)),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    final bool isLastStep = _currentStep == cprSteps.length - 1;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(child: SizedBox(height: 48, child: OutlinedButton(
              onPressed: _goToPreviousStep,
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('BACK', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ))),
            const SizedBox(width: 12),
          ],
          Expanded(flex: 2, child: SizedBox(height: 48, child: ElevatedButton(
            onPressed: _goToNextStep,
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(
                  isLastStep ? 'ENTER LIVE MODE' : 'NEXT STEP',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(isLastStep ? Icons.warning_amber_rounded : Icons.arrow_forward, size: 20),
            ]),
          ))),
        ],
      ),
    );
  }

  Widget _buildStepPage(CprStep step) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        final bool isSmallScreen = maxHeight < 600;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  AnimatedBuilder(animation: _iconPulseController, builder: (context, child) {
                    return Container(
                      width: isSmallScreen ? 60 : 80,
                      height: isSmallScreen ? 60 : 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryRed.withOpacity(0.12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.1 + _iconPulseController.value * 0.15),
                            blurRadius: isSmallScreen ? 20 : 30,
                            spreadRadius: 5
                          )
                        ]
                      ),
                      child: Icon(step.icon, color: primaryRed, size: isSmallScreen ? 30 : 36)
                    );
                  }),
                  SizedBox(height: isSmallScreen ? 12 : 20),
                  Text('STEP ${step.stepNumber}', style: GoogleFonts.outfit(color: primaryRed, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(step.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06))
                    ),
                    child: Text(
                      step.instruction,
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w500, height: 1.4),
                      textAlign: TextAlign.center
                    )
                  ),
                  const SizedBox(height: 16),
                  if (step.visualType == StepVisualType.chinPosition) ...[
                    Semantics(
                      label: 'Image showing correct chin and head position',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight * 0.3),
                          child: Image.asset('assets/CHIN_POSITION.jpeg', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                  if (step.visualType == StepVisualType.handPlacement) ...[
                    Semantics(
                      label: 'Image showing correct hand placement for CPR',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight * 0.3),
                          child: Image.asset('assets/CPR_HAND PLACEMENT.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                  if (step.visualType == StepVisualType.compressionPractice) ...[
                    if (!_isSimulating) ...[
                      SizedBox(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.touch_app, color: Colors.white24, size: 40),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _startSimulation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryRed.withOpacity(0.2),
                                foregroundColor: primaryRed,
                                side: const BorderSide(color: primaryRed),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('START INTERACTIVE PRACTICE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Place phone on chest or tap screen to practice',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            )
                          ],
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () => _motionService.simulateCompression(),
                        child: const CprInstructionAnimation(initialStep: InstructionStep.compression),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<BpmReading>(
                        stream: _motionService.bpmStream,
                        initialData: BpmReading.initial,
                        builder: (context, snapshot) {
                          return BpmGauge(reading: snapshot.data ?? BpmReading.initial);
                        }
                      ),
                    ],
                  ],
                  if (step.visualType == StepVisualType.rescueBreath) ...[
                    Semantics(
                      label: 'Image showing head tilt and chin lift for rescue breaths',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight * 0.3),
                          child: Image.asset('assets/CPR_RESCUE_BREATH.PNG', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (step.detail != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                      child: Text(step.detail!, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4))
                    ),
                  ],
                  if (_aiTip != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: successColor.withOpacity(0.2))
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.auto_awesome, color: successColor, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_aiTip!, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.3))),
                      ])),
                  ],
                  SizedBox(height: isSmallScreen ? 8 : 16),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
