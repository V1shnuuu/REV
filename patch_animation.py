import re

with open('/Users/yogeshm/first-aid/lib/widgets/cpr_instruction_animation.dart', 'r') as f:
    content = f.read()

# 1. Enum
content = content.replace(
    'enum InstructionStep { locate, handPlacement, posture, compression, rhythm }',
    'enum InstructionStep { locate, handPlacement, posture, compression, rhythm, airwayBreathing }'
)

# 2. Controllers & Anims
content = content.replace(
    'late AnimationController _rhythmController;',
    'late AnimationController _rhythmController;\n  late AnimationController _breathController;'
)
content = content.replace(
    'late Animation<double> _rippleAnim;',
    'late Animation<double> _rippleAnim;\n  late Animation<double> _chestRiseAnim;\n  late Animation<double> _headTiltAnim;'
)

# 3. initState
content = content.replace(
    '''    _rhythmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545), // 110 BPM
    );''',
    '''    _rhythmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545), // 110 BPM
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _chestRiseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
    ]).animate(_breathController);

    _headTiltAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
    ]).animate(_breathController);'''
)

# 4. _scheduleNextStep
content = content.replace(
    '''    } else if (_currentStep == InstructionStep.compression) {
      durationMs = 4500; 
    } else {
      return; // Rhythm step runs indefinitely
    }''',
    '''    } else if (_currentStep == InstructionStep.compression) {
      durationMs = 4500; 
    } else if (_currentStep == InstructionStep.airwayBreathing) {
      _breathController.repeat();
      return;
    } else {
      return; // Rhythm step runs indefinitely
    }'''
)

# 5. dispose
content = content.replace(
    '''    _rhythmController.dispose();
    super.dispose();''',
    '''    _rhythmController.dispose();
    _breathController.dispose();
    super.dispose();'''
)

# 6. build
content = content.replace(
    '''                : AnimatedBuilder(
                    animation: _rhythmController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 300),
                        painter: _InstructionPainter(
                          step: _currentStep,
                          transitionProgress: t,
                          compressionValue: _compressionAnim.value,
                          rippleValue: _rippleAnim.value,
                          accentColor: widget.accentColor,
                        ),
                      );
                    },
                  ),''',
    '''                : AnimatedBuilder(
                    animation: Listenable.merge([_rhythmController, _breathController, _transitionController]),
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
                  ),'''
)

# 7. Labels
content = content.replace(
    '''      InstructionStep.compression: "4. PRESS DOWN HARD (~5CM)",
      InstructionStep.rhythm: "5. PUSH TO THE RHYTHM",
    };''',
    '''      InstructionStep.compression: "4. PRESS DOWN HARD (~5CM)",
      InstructionStep.rhythm: "5. PUSH TO THE RHYTHM",
      InstructionStep.airwayBreathing: "TILT HEAD, LIFT CHIN & BREATHE",
    };'''
)

# 8. Painter class
content = content.replace(
    '''  final InstructionStep step;
  final double transitionProgress; 
  final double compressionValue;
  final double rippleValue;
  final Color accentColor;

  _InstructionPainter({
    required this.step,
    required this.transitionProgress,
    required this.compressionValue,
    required this.rippleValue,
    required this.accentColor,
  });''',
    '''  final InstructionStep step;
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
  });'''
)

# 9. paint vars
content = content.replace(
    '''    double zoom = 1.0;
    double panY = 0.0;
    
    double locateOpacity = 0.0;''',
    '''    double zoom = 1.0;
    double panY = 0.0;
    double chestExpansion = 0.0;
    double headTilt = 0.0;
    
    double locateOpacity = 0.0;'''
)

content = content.replace(
    '''    else if (step == InstructionStep.rhythm) {
      zoom = 1.0;
      panY = 0.0;
      handPlacementProgress = 1.0;
      handsOpacity = 1.0;
      postureOpacity = 1.0;
      motionOpacity = 1.0;
    }''',
    '''    else if (step == InstructionStep.rhythm) {
      zoom = 1.0;
      panY = 0.0;
      handPlacementProgress = 1.0;
      handsOpacity = 1.0;
      postureOpacity = 1.0;
      motionOpacity = 1.0;
    }
    else if (step == InstructionStep.airwayBreathing) {
      zoom = 1.2;
      panY = -10;
      chestExpansion = chestRiseValue;
      headTilt = headTiltValue;
    }'''
)

content = content.replace(
    '''    _drawTorso(canvas, cx, torsoTop, compressionDepth);''',
    '''    _drawTorso(canvas, cx, torsoTop, compressionDepth, chestExpansion, headTilt);'''
)

# 10. _drawTorso params and logic
old_torso = '''  void _drawTorso(Canvas canvas, double cx, double torsoTop, double depth) {
    final shoulderY = torsoTop + 20;
    
    // Main Torso Path for filling
    final torsoFillPath = Path();
    torsoFillPath.moveTo(cx, shoulderY + 12);
    torsoFillPath.lineTo(cx - 70, shoulderY + 12);
    torsoFillPath.cubicTo(cx - 68, shoulderY + 50, cx - 55 + depth * 0.5, shoulderY + 90 + depth, cx - 55, shoulderY + 130);
    torsoFillPath.cubicTo(cx - 50, shoulderY + 170, cx - 45, shoulderY + 200, cx - 50, shoulderY + 240);
    torsoFillPath.lineTo(cx + 50, shoulderY + 240);
    torsoFillPath.cubicTo(cx + 45, shoulderY + 200, cx + 50, shoulderY + 170, cx + 55, shoulderY + 130);
    torsoFillPath.cubicTo(cx + 55 - depth * 0.5, shoulderY + 90 + depth, cx + 68, shoulderY + 50, cx + 70, shoulderY + 12);
    torsoFillPath.close();

    // Chest curvature gradient (3D look)
    final chestGradient = RadialGradient(
      center: Alignment(0, -0.3 + (depth * 0.01)),
      radius: 1.5,
      colors: [
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.05),
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
    canvas.drawLine(Offset(cx - 70, shoulderY + 12), Offset(cx + 70, shoulderY + 12), highlightPaint);

    // 3D Head and Neck
    final headGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      radius: 1.0,
      colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.02)],
    ).createShader(Rect.fromCircle(center: Offset(cx, torsoTop - 20), radius: 22));
    canvas.drawCircle(Offset(cx, torsoTop - 20), 22, Paint()..shader = headGradient);
    canvas.drawCircle(Offset(cx, torsoTop - 20), 22, shadowPaint..strokeWidth = 6);

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
      final ribY = shoulderY + 50 + i * 22 + (i > 1 ? depth * 0.3 : 0);
      final ribW = 38.0 - i * 2;
      final ribRect = Rect.fromCenter(center: Offset(cx, ribY), width: ribW * 2, height: 14);
      canvas.drawArc(ribRect, 0.2, 2.7, false, ribPaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx, ribY + 2), width: ribW * 2, height: 14), 0.2, 2.7, false, ribHighlight);
    }
  }'''

new_torso = '''  void _drawTorso(Canvas canvas, double cx, double torsoTop, double depth, double chestExpansion, double headTilt) {
    final shoulderY = torsoTop + 20;
    final exp = chestExpansion * 12.0;
    
    // Main Torso Path for filling
    final torsoFillPath = Path();
    torsoFillPath.moveTo(cx, shoulderY + 12);
    torsoFillPath.lineTo(cx - 70 - exp * 0.5, shoulderY + 12);
    torsoFillPath.cubicTo(cx - 68 - exp, shoulderY + 50, cx - 55 + depth * 0.5 - exp, shoulderY + 90 + depth, cx - 55 - exp, shoulderY + 130);
    torsoFillPath.cubicTo(cx - 50 - exp, shoulderY + 170, cx - 45 - exp * 0.5, shoulderY + 200, cx - 50, shoulderY + 240);
    torsoFillPath.lineTo(cx + 50, shoulderY + 240);
    torsoFillPath.cubicTo(cx + 45 + exp * 0.5, shoulderY + 200, cx + 50 + exp, shoulderY + 170, cx + 55 + exp, shoulderY + 130);
    torsoFillPath.cubicTo(cx + 55 - depth * 0.5 + exp, shoulderY + 90 + depth, cx + 68 + exp, shoulderY + 50, cx + 70 + exp * 0.5, shoulderY + 12);
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
    canvas.drawLine(Offset(cx - 70 - exp * 0.5, shoulderY + 12), Offset(cx + 70 + exp * 0.5, shoulderY + 12), highlightPaint);

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
      final hPaint = Paint()..color = Colors.white.withOpacity(0.4 * handOpacity)..style = PaintingStyle.fill;
      final hBorder = Paint()..color = Colors.white.withOpacity(0.6 * handOpacity)..style = PaintingStyle.stroke..strokeWidth=1;
      
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, headY - 18), width: 30, height: 16), hPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, headY - 18), width: 30, height: 16), hBorder);
      
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, headY + 18), width: 20, height: 12), hPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, headY + 18), width: 20, height: 12), hBorder);
      
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
      final ribY = shoulderY + 50 + i * 22 + (i > 1 ? depth * 0.3 : 0) - (chestExpansion * 5);
      final ribW = 38.0 - i * 2 + (exp * 0.8);
      final ribRect = Rect.fromCenter(center: Offset(cx, ribY), width: ribW * 2, height: 14);
      canvas.drawArc(ribRect, 0.2, 2.7, false, ribPaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx, ribY + 2), width: ribW * 2, height: 14), 0.2, 2.7, false, ribHighlight);
    }
  }'''

content = content.replace(old_torso, new_torso)

content = content.replace(
'''  bool shouldRepaint(covariant _InstructionPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.transitionProgress != transitionProgress ||
        oldDelegate.compressionValue != compressionValue ||
        oldDelegate.rippleValue != rippleValue;
  }''',
'''  bool shouldRepaint(covariant _InstructionPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.transitionProgress != transitionProgress ||
        oldDelegate.compressionValue != compressionValue ||
        oldDelegate.rippleValue != rippleValue ||
        oldDelegate.chestRiseValue != chestRiseValue ||
        oldDelegate.headTiltValue != headTiltValue;
  }'''
)

with open('/Users/yogeshm/first-aid/lib/widgets/cpr_instruction_animation.dart', 'w') as f:
    f.write(content)
print("Updated animation file!")
