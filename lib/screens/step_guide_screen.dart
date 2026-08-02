import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../constants/cpr_steps.dart';
import '../services/motion_service.dart';
import '../services/ollama_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/revive_bpm_gauge.dart';
import '../widgets/components/revive_button.dart';
import '../widgets/components/revive_card.dart';
import '../widgets/components/revive_state_view.dart';
import '../widgets/cpr_instruction_animation.dart';

class StepGuideScreen extends StatefulWidget {
  const StepGuideScreen({super.key});

  @override
  State<StepGuideScreen> createState() => _StepGuideScreenState();
}

class _StepGuideScreenState extends State<StepGuideScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
    );
    _tts.initialize().then((_) => _speakCurrentStep());
    _loadAiTip(0);
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);

    // Listen to motion service for completion
    _motionService.bpmStream.listen((reading) {
      if (mounted && _isSimulating && reading.compressionCount >= 30) {
        _motionService.stopListening();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted &&
              cprSteps[_currentStep].visualType ==
                  StepVisualType.compressionPractice) {
            _goToNextStep();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Decorative pulse: skipped outright under reduce-motion.
    if (ResolvedMotion.of(context).shouldAnimate) {
      if (!_iconPulseController.isAnimating) {
        _iconPulseController.repeat(reverse: true);
      }
    } else {
      _iconPulseController.stop();
    }

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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
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

    setState(() {
      _loadingTip = true;
      _aiTip = null;
    });
    final tip = await _ollama.generateTip(
      cprSteps[stepIndex].title,
      cprSteps[stepIndex].instruction,
    );

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
      _loadingTip = false;
      _isSimulating = false;
      _motionService.stopListening();
      _motionService.reset();
    });
    _tts.stop(); // Stop previous voice immediately
    _speakCurrentStep();
    _loadAiTip(index);
  }

  void _startSimulation() {
    setState(() => _isSimulating = true);
    _motionService.startListening();
  }

  void _goToNextStep() {
    if (_currentStep < cprSteps.length - 1) {
      _pageController.nextPage(
        duration: AppMotion.slow,
        curve: AppMotion.standard,
      );
    } else {
      _tts.stop();
      Navigator.pushReplacementNamed(context, '/live');
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: AppMotion.slow,
        curve: AppMotion.standard,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            AppSpacing.gapLg,
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: cprSteps.length,
                itemBuilder: (context, index) =>
                    _buildStepPage(cprSteps[index]),
              ),
            ),
            _buildNavButtons(),
            AppSpacing.gapSm,
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
                child: Icon(Icons.arrow_back, color: c.textSecondary, size: 20),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'STEP ${_currentStep + 1} OF ${cprSteps.length}',
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(color: c.textTertiary),
            ),
          ),
          Semantics(
            label: 'Repeat voice instruction',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _speakCurrentStep,
              child: Container(
                width: AppTouchTarget.minimum,
                height: AppTouchTarget.minimum,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.urgentActionSubtle,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(Icons.volume_up, color: c.urgentAction, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final c = context.colors;
    return Semantics(
      label: 'Progress: step ${_currentStep + 1} of ${cprSteps.length}',
      excludeSemantics: true,
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Row(
          children: List.generate(
            cprSteps.length,
            (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderXs,
                  color: i <= _currentStep ? c.urgentAction : c.surfaceOverlay,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    final bool isLastStep = _currentStep == cprSteps.length - 1;

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: ReviveButton(
                label: 'BACK',
                variant: ReviveButtonVariant.secondary,
                onPressed: _goToPreviousStep,
              ),
            ),
            AppSpacing.hGapMd,
          ],
          Expanded(
            flex: 2,
            child: ReviveButton(
              label: isLastStep ? 'ENTER LIVE MODE' : 'NEXT STEP',
              icon: isLastStep
                  ? Icons.warning_amber_rounded
                  : Icons.arrow_forward,
              onPressed: _goToNextStep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(CprStep step) {
    final c = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        final bool isSmall = maxHeight < 600;

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              AppSpacing.gapMd,
              _buildStepIcon(step, isSmall),
              AppSpacing.gapLg,
              Text(
                'STEP ${step.stepNumber}',
                style: context.text.labelSmall?.copyWith(color: c.urgentAction),
              ),
              AppSpacing.gapXs,
              Semantics(
                header: true,
                child: Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style:
                      (isSmall
                              ? context.text.headlineSmall
                              : context.text.headlineMedium)
                          ?.copyWith(color: c.textPrimary),
                ),
              ),
              AppSpacing.gapMd,
              ReviveCard(
                child: Text(
                  step.instruction,
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge?.copyWith(color: c.textPrimary),
                ),
              ),
              AppSpacing.gapLg,
              _buildStepVisual(step, maxHeight),
              if (step.detail != null) ...[
                AppSpacing.gapLg,
                ReviveCard(
                  compact: true,
                  child: Text(
                    step.detail!,
                    style: context.text.bodySmall?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
              _buildAiTip(),
              AppSpacing.gapLg,
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepIcon(CprStep step, bool isSmall) {
    final c = context.colors;
    final double size = isSmall ? 64 : 84;

    return AnimatedBuilder(
      animation: _iconPulseController,
      builder: (context, child) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.urgentActionSubtle,
          boxShadow: AppElevation.glow(
            c.urgentAction,
            intensity: 0.4 + _iconPulseController.value * 0.5,
          ),
        ),
        child: Icon(step.icon, color: c.urgentAction, size: isSmall ? 30 : 38),
      ),
    );
  }

  Widget _buildStepVisual(CprStep step, double maxHeight) {
    switch (step.visualType) {
      case StepVisualType.chinPosition:
        return _buildImage(
          'assets/CHIN_POSITION.jpeg',
          'Correct chin and head position to open the airway',
          maxHeight,
        );
      case StepVisualType.handPlacement:
        return _buildImage(
          'assets/CPR_HAND PLACEMENT.png',
          'Correct hand placement for chest compressions',
          maxHeight,
        );
      case StepVisualType.rescueBreath:
        return _buildImage(
          'assets/CPR_RESCUE_BREATH.PNG',
          'Head tilt and chin lift for rescue breaths',
          maxHeight,
        );
      case StepVisualType.compressionPractice:
        return _buildCompressionPractice();
      case StepVisualType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImage(String asset, String semanticLabel, double maxHeight) {
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight * 0.32),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildCompressionPractice() {
    final c = context.colors;

    if (!_isSimulating) {
      return Column(
        children: [
          Icon(Icons.touch_app_outlined, color: c.textTertiary, size: 40),
          AppSpacing.gapMd,
          ReviveButton(
            label: 'START INTERACTIVE PRACTICE',
            variant: ReviveButtonVariant.secondary,
            onPressed: _startSimulation,
          ),
          AppSpacing.gapSm,
          Text(
            'Place the phone on the chest, or tap the screen to practise',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textTertiary),
          ),
        ],
      );
    }

    return Column(
      children: [
        Semantics(
          label: 'Tap to register a practice compression',
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _motionService.simulateCompression,
            child: const CprInstructionAnimation(
              initialStep: InstructionStep.compression,
            ),
          ),
        ),
        AppSpacing.gapLg,
        StreamBuilder<BpmReading>(
          stream: _motionService.bpmStream,
          initialData: BpmReading.initial,
          builder: (context, snapshot) => ReviveBpmGauge(
            reading: snapshot.data ?? BpmReading.initial,
            compact: true,
          ),
        ),
      ],
    );
  }

  /// Reinstates the pending state the old screen never had: _loadingTip was
  /// previously set but never read, so the AI tip popped in with no indication
  /// it had ever been fetching.
  Widget _buildAiTip() {
    if (!_loadingTip && _aiTip == null) return const SizedBox.shrink();

    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: _loadingTip
          ? const Align(
              alignment: Alignment.centerLeft,
              child: ReviveLoadingView(size: 18, message: 'Fetching a tip...'),
            )
          : ReviveCard(
              tone: ReviveCardTone.success,
              compact: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, color: c.inRangeSuccess, size: 16),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      _aiTip!,
                      style: context.text.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
