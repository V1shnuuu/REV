import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

enum InstructionStep {
  locate,
  handPlacement,
  posture,
  compression,
  rhythm,
  airwayBreathing,
}

class CprInstructionAnimation extends StatefulWidget {
  final Color accentColor;
  final InstructionStep? initialStep;

  const CprInstructionAnimation({
    super.key,
    this.accentColor = const Color(0xFFE63946),
    this.initialStep,
  });

  @override
  State<CprInstructionAnimation> createState() =>
      _CprInstructionAnimationState();
}

class _CprInstructionAnimationState extends State<CprInstructionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late AnimationController _rhythmController;
  late AnimationController _breathController;

  late Animation<double> _compressionAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _chestRiseAnim;
  late Animation<double> _headTiltAnim;

  late InstructionStep _currentStep;
  Timer? _stepTimer;

  double get t => _transitionController.value;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep ?? InstructionStep.locate;
    _transitionController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        )..addListener(() {
          setState(() {});
        });

    _rhythmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545), // 110 BPM
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _chestRiseAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
    ]).animate(_breathController);

    _headTiltAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_breathController);

    _compressionAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
    ]).animate(_rhythmController);

    _rippleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 55),
    ]).animate(_rhythmController);

    _startSequence();
  }

  void _startSequence() {
    _transitionController.forward(from: 0.0);
    _scheduleNextStep();
  }

  void _scheduleNextStep() {
    _stepTimer?.cancel();

    int durationMs = 3500;

    if (_currentStep == InstructionStep.locate) {
      durationMs = 3500;
    } else if (_currentStep == InstructionStep.handPlacement) {
      durationMs = 4000;
    } else if (_currentStep == InstructionStep.posture) {
      durationMs = 3500;
    } else if (_currentStep == InstructionStep.compression) {
      durationMs = 4500;
    } else if (_currentStep == InstructionStep.airwayBreathing) {
      _breathController.repeat();
      return;
    } else {
      return; // Rhythm step runs indefinitely
    }

    _stepTimer = Timer(Duration(milliseconds: durationMs), () {
      if (!mounted) return;
      _advanceStep();
    });
  }

  void _advanceStep() {
    setState(() {
      if (_currentStep == InstructionStep.locate) {
        _currentStep = InstructionStep.handPlacement;
      } else if (_currentStep == InstructionStep.handPlacement) {
        _currentStep = InstructionStep.posture;
      } else if (_currentStep == InstructionStep.posture) {
        _currentStep = InstructionStep.compression;
        _rhythmController.repeat();
      } else if (_currentStep == InstructionStep.compression) {
        _currentStep = InstructionStep.rhythm;
      }
    });

    _transitionController.forward(from: 0.0);
    _scheduleNextStep();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _transitionController.dispose();
    _rhythmController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showGif =
        _currentStep == InstructionStep.compression ||
        _currentStep == InstructionStep.rhythm;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: showGif
                ? Image.asset(
                    'assets/Chest_compressions.gif',
                    height: 250,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Error loading GIF: $error',
                        style: const TextStyle(color: Colors.red),
                      );
                    },
                  )
                : AnimatedBuilder(
                    animation: Listenable.merge([
                      _rhythmController,
                      _breathController,
                      _transitionController,
                    ]),
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 300),
                        painter: _InstructionPainter(
                          step: _currentStep,
                          transitionProgress: t,
                          compressionValue: _compressionAnim.value,
                          rippleValue: _rippleAnim.value,
                          chestRiseValue: _chestRiseAnim.value ?? 0.0,
                          headTiltValue: _headTiltAnim.value ?? 0.0,
                          accentColor: widget.accentColor,
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStepLabels(),
      ],
    );
  }

  Widget _buildStepLabels() {
    final labels = {
      InstructionStep.locate: "1. LOCATE CENTER OF CHEST",
      InstructionStep.handPlacement: "2. PLACE HANDS INTERLOCKED",
      InstructionStep.posture: "3. LOCK ELBOWS STRAIGHT",
      InstructionStep.compression: "4. PRESS DOWN HARD (~5CM)",
      InstructionStep.rhythm: "5. PUSH TO THE RHYTHM",
      InstructionStep.airwayBreathing: "TILT HEAD, LIFT CHIN & BREATHE",
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        labels[_currentStep]!,
        key: ValueKey(_currentStep),
        style: TextStyle(
          color: widget.accentColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InstructionPainter extends CustomPainter {
  final InstructionStep step;
  final double transitionProgress;
  final double compressionValue;
  final double rippleValue;
  final double chestRiseValue;
  final double headTiltValue;
  final Color accentColor;

  _InstructionPainter({
    required this.step,
    required this.transitionProgress,
    required this.compressionValue,
    required this.rippleValue,
    required this.chestRiseValue,
    required this.headTiltValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    double zoom = 1.0;
    double panY = 0.0;
    double chestExpansion = 0.0;
    double headTilt = 0.0;

    double locateOpacity = 0.0;
    double handPlacementProgress = 0.0;
    double handsOpacity = 0.0;
    double postureOpacity = 0.0;
    double motionOpacity = 0.0;

    final t = transitionProgress;

    if (step == InstructionStep.locate) {
      zoom = 1.2;
      panY = -30;
      locateOpacity = t < 0.5 ? t * 2 : 1.0;
    } else if (step == InstructionStep.handPlacement) {
      zoom = 1.2 + 0.3 * t;
      panY = -30 - 20 * t;
      locateOpacity = (1.0 - t * 2).clamp(0.0, 1.0);
      handPlacementProgress = t;
      handsOpacity = 1.0;
    } else if (step == InstructionStep.posture) {
      zoom = 1.5 - 0.5 * t;
      panY = -50 + 50 * t;
      handPlacementProgress = 1.0;
      handsOpacity = 1.0;
      postureOpacity = t;
    } else if (step == InstructionStep.compression) {
      zoom = 1.0;
      panY = 0.0;
      handPlacementProgress = 1.0;
      handsOpacity = 1.0;
      postureOpacity = 1.0;
      motionOpacity = t;
    } else if (step == InstructionStep.rhythm) {
      zoom = 1.0;
      panY = 0.0;
      handPlacementProgress = 1.0;
      handsOpacity = 1.0;
      postureOpacity = 1.0;
      motionOpacity = 1.0;
    } else if (step == InstructionStep.airwayBreathing) {
      zoom = 1.2;
      panY = -10;
      chestExpansion = chestRiseValue;
      headTilt = headTiltValue;
    }

    final compressionDepth =
        (step == InstructionStep.compression || step == InstructionStep.rhythm)
        ? compressionValue * 12.0
        : 0.0;

    canvas.save();

    canvas.translate(cx, cy);
    canvas.scale(zoom);
    canvas.translate(0, panY);
    canvas.translate(-cx, -cy);

    final torsoTop = cy - 60;

    _drawTorso(
      canvas,
      cx,
      torsoTop,
      compressionDepth,
      chestExpansion,
      headTilt,
    );

    if (locateOpacity > 0.0)
      _drawLocatePointer(canvas, cx, torsoTop, locateOpacity);

    if (motionOpacity > 0.0 && rippleValue > 0.0 && rippleValue < 1.0) {
      _drawRipple(canvas, cx, torsoTop, compressionDepth, motionOpacity);
    }

    if (handsOpacity > 0.0) {
      _drawHands(
        canvas,
        cx,
        torsoTop,
        compressionDepth,
        handPlacementProgress,
        handsOpacity,
      );
    }

    if (postureOpacity > 0.0) {
      _drawArms(canvas, cx, torsoTop, compressionDepth, postureOpacity);
    }

    if (motionOpacity > 0.0) {
      _drawMotionIndicators(
        canvas,
        cx,
        torsoTop,
        compressionDepth,
        motionOpacity,
      );
    }

    canvas.restore();
  }

  void _drawTorso(
    Canvas canvas,
    double cx,
    double torsoTop,
    double depth,
    double chestExpansion,
    double headTilt,
  ) {
    final shoulderY = torsoTop + 20;
    final exp = chestExpansion * 12.0;

    // Main Torso Path for filling
    final torsoFillPath = Path();
    torsoFillPath.moveTo(cx, shoulderY + 12);
    torsoFillPath.lineTo(cx - 70 - exp * 0.5, shoulderY + 12);
    torsoFillPath.cubicTo(
      cx - 68 - exp,
      shoulderY + 50,
      cx - 55 + depth * 0.5 - exp,
      shoulderY + 90 + depth,
      cx - 55 - exp,
      shoulderY + 130,
    );
    torsoFillPath.cubicTo(
      cx - 50 - exp,
      shoulderY + 170,
      cx - 45 - exp * 0.5,
      shoulderY + 200,
      cx - 50,
      shoulderY + 240,
    );
    torsoFillPath.lineTo(cx + 50, shoulderY + 240);
    torsoFillPath.cubicTo(
      cx + 45 + exp * 0.5,
      shoulderY + 200,
      cx + 50 + exp,
      shoulderY + 170,
      cx + 55 + exp,
      shoulderY + 130,
    );
    torsoFillPath.cubicTo(
      cx + 55 - depth * 0.5 + exp,
      shoulderY + 90 + depth,
      cx + 68 + exp,
      shoulderY + 50,
      cx + 70 + exp * 0.5,
      shoulderY + 12,
    );
    torsoFillPath.close();

    // Chest curvature gradient (3D look)
    final chestGradient = RadialGradient(
      center: Alignment(0, -0.3 + (depth * 0.01) - (chestExpansion * 0.1)),
      radius: 1.5 + chestExpansion * 0.2,
      colors: [
        Colors.white.withOpacity(0.15 + chestExpansion * 0.05),
        Colors.white.withOpacity(0.05 + chestExpansion * 0.05),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(torsoFillPath.getBounds());

    canvas.drawPath(torsoFillPath, Paint()..shader = chestGradient);

    // Dark inner shadow to round the edges
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(torsoFillPath, shadowPaint);

    // Highlight top edge for 3D bevel
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(
      Offset(cx - 70 - exp * 0.5, shoulderY + 12),
      Offset(cx + 70 + exp * 0.5, shoulderY + 12),
      highlightPaint,
    );

    // 3D Head and Neck
    final headY = torsoTop - 20 - (headTilt * 10.0);
    final headGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      radius: 1.0,
      colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.02)],
    ).createShader(Rect.fromCircle(center: Offset(cx, headY), radius: 22));
    canvas.drawCircle(Offset(cx, headY), 22, Paint()..shader = headGradient);
    canvas.drawCircle(Offset(cx, headY), 22, shadowPaint..strokeWidth = 6);

    // Draw hands for head-tilt/chin-lift and air particles
    if (headTilt > 0.01) {
      final handOpacity = headTilt.clamp(0.0, 1.0);
      final hPaint = Paint()
        ..color = Colors.white.withOpacity(0.4 * handOpacity)
        ..style = PaintingStyle.fill;
      final hBorder = Paint()
        ..color = Colors.white.withOpacity(0.6 * handOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, headY - 18), width: 30, height: 16),
        hPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, headY - 18), width: 30, height: 16),
        hBorder,
      );

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, headY + 18), width: 20, height: 12),
        hPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, headY + 18), width: 20, height: 12),
        hBorder,
      );

      if (chestExpansion > 0.01) {
        final airOpacity = chestExpansion.clamp(0.0, 1.0);
        final airPaint = Paint()
          ..color = accentColor.withOpacity(airOpacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        final path = Path();
        path.moveTo(cx - 20, headY + 15);
        path.quadraticBezierTo(cx, headY + 5, cx, headY + 15);
        path.moveTo(cx + 20, headY + 15);
        path.quadraticBezierTo(cx, headY + 5, cx, headY + 15);
        canvas.drawPath(path, airPaint);
      }
    }

    // Soft indented ribs
    final ribPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final ribHighlight = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 5; i++) {
      final ribY =
          shoulderY +
          50 +
          i * 22 +
          (i > 1 ? depth * 0.3 : 0) -
          (chestExpansion * 5);
      final ribW = 38.0 - i * 2 + (exp * 0.8);
      final ribRect = Rect.fromCenter(
        center: Offset(cx, ribY),
        width: ribW * 2,
        height: 14,
      );
      canvas.drawArc(ribRect, 0.2, 2.7, false, ribPaint);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, ribY + 2),
          width: ribW * 2,
          height: 14,
        ),
        0.2,
        2.7,
        false,
        ribHighlight,
      );
    }
  }

  void _drawLocatePointer(
    Canvas canvas,
    double cx,
    double torsoTop,
    double opacity,
  ) {
    final sternumY = torsoTop + 130;

    final centerGlow = Paint()
      ..color = accentColor.withOpacity(opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(cx, sternumY), 25, centerGlow);

    final dot = Paint()..color = Colors.white.withOpacity(opacity);
    canvas.drawCircle(Offset(cx, sternumY), 4, dot);

    // Crosshairs
    final crossHair = Paint()
      ..color = accentColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cx - 30, sternumY),
      Offset(cx - 15, sternumY),
      crossHair,
    );
    canvas.drawLine(
      Offset(cx + 15, sternumY),
      Offset(cx + 30, sternumY),
      crossHair,
    );
    canvas.drawLine(
      Offset(cx, sternumY - 30),
      Offset(cx, sternumY - 15),
      crossHair,
    );
    canvas.drawLine(
      Offset(cx, sternumY + 15),
      Offset(cx, sternumY + 30),
      crossHair,
    );

    // Text Label "CENTER OF CHEST"
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CENTER OF CHEST',
        style: TextStyle(
          color: accentColor.withOpacity(opacity),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, sternumY + 40),
    );
  }

  void _drawHands(
    Canvas canvas,
    double cx,
    double torsoTop,
    double depth,
    double progress,
    double opacity,
  ) {
    if (opacity <= 0.0 && progress <= 0.0) return;

    final handY = torsoTop + 125 + depth;
    final pressIntensity = (depth / 12.0).clamp(0.0, 1.0); // 0 to 1

    final shadowBlur = 15.0 - (pressIntensity * 10.0);
    final shadowOffset = 10.0 - (pressIntensity * 8.0);

    double currentOpacity = opacity;
    double leftX = cx;
    double rightX = cx;
    double interlockProgress = 0.0;

    if (progress < 1.0) {
      if (progress < 0.33) {
        // Phase 1: Fade in side by side
        double p = progress / 0.33;
        currentOpacity = p;
        leftX = cx - 28;
        rightX = cx + 28;
      } else if (progress < 0.66) {
        // Phase 2: Slide together
        double p = (progress - 0.33) / 0.33;
        p = Curves.easeInOut.transform(p);
        leftX = cx - 28 * (1 - p);
        rightX = cx + 28 * (1 - p);
      } else {
        // Phase 3: Interlock fingers
        leftX = cx;
        rightX = cx;
        double p = (progress - 0.66) / 0.34;
        interlockProgress = Curves.easeInOut.transform(p);
      }
    } else {
      interlockProgress = 1.0;
    }

    final shadowOpacity = (0.5 + pressIntensity * 0.2) * currentOpacity;

    // Bottom hand (Left hand)
    final bottomHandRect = Rect.fromCenter(
      center: Offset(leftX, handY + 5),
      width: 50,
      height: 26,
    );
    final bottomHand = RRect.fromRectAndRadius(
      bottomHandRect,
      const Radius.circular(10),
    );

    // Draw left hand shadow
    canvas.drawRRect(
      bottomHand.shift(Offset(0, shadowOffset)),
      Paint()
        ..color = Colors.black.withOpacity(shadowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur),
    );

    // Draw left hand fingers BEFORE top hand and left hand fill
    for (int i = 0; i < 4; i++) {
      final fx = leftX - 15 + i * 10.0;
      final fingerPath = Path()
        ..moveTo(fx, handY + 5)
        ..lineTo(fx, handY - 25);

      canvas.drawPath(
        fingerPath,
        Paint()
          ..color = Colors.white.withOpacity(currentOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw left hand fill
    final bottomHandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.9 * currentOpacity),
          const Color(0xFFD0D0D0).withOpacity(0.9 * currentOpacity),
        ],
      ).createShader(bottomHandRect);

    canvas.drawRRect(bottomHand, bottomHandPaint);

    canvas.drawRRect(
      bottomHand,
      Paint()
        ..color = Colors.white.withOpacity(0.5 * currentOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final heelHighlight = Paint()
      ..color = accentColor.withOpacity(0.6 * currentOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(leftX, handY + 12), 16, heelHighlight);

    // Top hand (Right hand)
    final topHandRect = Rect.fromCenter(
      center: Offset(rightX, handY - 5),
      width: 46,
      height: 22,
    );
    final topHand = RRect.fromRectAndRadius(
      topHandRect,
      const Radius.circular(8),
    );

    // Shadow casting from top hand
    canvas.drawRRect(
      topHand.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withOpacity(0.4 * currentOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Top hand fingers (straight -> interlocked)
    for (int i = 0; i < 4; i++) {
      final fx = rightX - 15 + i * 10.0;
      double startX = fx;
      double startY = handY - 5;

      // straight up
      double upEndX = fx;
      double upEndY = handY - 33;

      // interlocked
      double lockEndX = fx - 4;
      double lockEndY = handY + 8;

      double endX = upEndX + (lockEndX - upEndX) * interlockProgress;
      double endY = upEndY + (lockEndY - upEndY) * interlockProgress;

      final fingerPath = Path()
        ..moveTo(startX, startY)
        ..lineTo(endX, endY);

      canvas.drawPath(
        fingerPath.shift(const Offset(2, 0)),
        Paint()
          ..color = Colors.black.withOpacity(0.3 * currentOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      canvas.drawPath(
        fingerPath,
        Paint()
          ..color = Colors.white.withOpacity(currentOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    final topHandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.95 * currentOpacity),
          const Color(0xFFB0B0B0).withOpacity(0.95 * currentOpacity),
        ],
      ).createShader(topHandRect);

    canvas.drawRRect(topHand, topHandPaint);

    canvas.drawRRect(
      topHand,
      Paint()
        ..color = Colors.white.withOpacity(0.8 * currentOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawArms(
    Canvas canvas,
    double cx,
    double torsoTop,
    double depth,
    double opacity,
  ) {
    final handY = torsoTop + 120 + depth;
    final leftShoulder = Offset(cx - 30, handY - 100);
    final rightShoulder = Offset(cx + 30, handY - 100);
    final handPos = Offset(cx, handY - 15);

    // 3D Arms using thick lines with gradients and shadows
    final armShadow = Paint()
      ..color = Colors.black.withOpacity(0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Left Arm Shadow
    canvas.drawLine(handPos, leftShoulder, armShadow);
    // Right Arm Shadow
    canvas.drawLine(handPos, rightShoulder, armShadow);

    // Draw the actual 3D looking arms using a cylindrical gradient
    _draw3DArm(canvas, handPos, leftShoulder, opacity);
    _draw3DArm(canvas, handPos, rightShoulder, opacity);

    // Angle/Posture indicator
    final indicatorPaint = Paint()
      ..color = accentColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(cx, handY - 120),
      Offset(cx, handY - 15),
      indicatorPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'STRAIGHT ARMS\nLOCKED ELBOWS',
        style: TextStyle(
          color: accentColor.withOpacity(opacity),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 20, handY - 100));
  }

  void _draw3DArm(Canvas canvas, Offset start, Offset end, double opacity) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    // Unit normal vector
    final nx = -dy / length;
    final ny = dx / length;

    const armWidth = 12.0;
    final p1 = Offset(
      start.dx + nx * armWidth / 2,
      start.dy + ny * armWidth / 2,
    );
    final p2 = Offset(
      start.dx - nx * armWidth / 2,
      start.dy - ny * armWidth / 2,
    );

    final armPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1 * opacity),
          Colors.white.withOpacity(0.5 * opacity),
          Colors.white.withOpacity(0.1 * opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromPoints(p1, p2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = armWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, armPaint);
  }

  void _drawMotionIndicators(
    Canvas canvas,
    double cx,
    double torsoTop,
    double depth,
    double opacity,
  ) {
    final arrowPaint = Paint()
      ..color = accentColor.withOpacity(
        opacity * (0.3 + 0.7 * compressionValue),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final arrowShift = compressionValue * 15.0;
    final bay = torsoTop + 40 + arrowShift;

    // Center big arrow
    canvas.drawLine(Offset(cx, bay), Offset(cx, bay + 24), arrowPaint);
    canvas.drawLine(Offset(cx - 8, bay + 16), Offset(cx, bay + 24), arrowPaint);
    canvas.drawLine(Offset(cx + 8, bay + 16), Offset(cx, bay + 24), arrowPaint);

    // Depth text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '~5 CM DEPTH',
        style: TextStyle(
          color: accentColor.withOpacity(opacity),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 15, bay + 5));
  }

  void _drawRipple(
    Canvas canvas,
    double cx,
    double torsoTop,
    double depth,
    double opacity,
  ) {
    final rippleRadius = 30.0 + rippleValue * 90.0;
    final rippleOpacity = (1.0 - rippleValue) * 0.6 * opacity;
    final ripplePaint = Paint()
      ..color = accentColor.withOpacity(rippleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      Offset(cx, torsoTop + 130 + depth),
      rippleRadius,
      ripplePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _InstructionPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.transitionProgress != transitionProgress ||
        oldDelegate.compressionValue != compressionValue ||
        oldDelegate.rippleValue != rippleValue ||
        oldDelegate.chestRiseValue != chestRiseValue ||
        oldDelegate.headTiltValue != headTiltValue;
  }
}
