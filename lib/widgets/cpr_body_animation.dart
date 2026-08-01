import 'dart:math';
import 'package:flutter/material.dart';

class CprBodyAnimation extends StatefulWidget {
  /// Color for the feedback state (green/orange/red)
  final Color feedbackColor;

  /// Text to show below the animation
  final String feedbackText;

  /// Current compression count from the sensor
  final int compressionCount;

  const CprBodyAnimation({
    super.key,
    this.feedbackColor = const Color(0xFFE63946),
    this.feedbackText = 'FOLLOW THE RHYTHM',
    this.compressionCount = 0,
  });

  @override
  State<CprBodyAnimation> createState() => _CprBodyAnimationState();
}

class _CprBodyAnimationState extends State<CprBodyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _compressionAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _arrowAnim;
  late Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();
    // 110 BPM = ~545ms per cycle. Full cycle (down and up).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    );

    // 3-phase motion cycle:
    // 1. Fast press down (0.0 -> 1.0)
    // 2. Short hold at bottom (1.0)
    // 3. Slower release (1.0 -> 0.0)
    _compressionAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35, // 35% of the time: pressing down
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 10, // 10% of the time: hold at the bottom
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55, // 55% of the time: release
      ),
    ]).animate(_controller);

    // Glow: brighter when pressed
    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 0.85).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.85),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 0.25).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
    ]).animate(_controller);

    // Arrow bounce - arrows move down during press and return
    _arrowAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
    ]).animate(_controller);

    // Ripple effect that expands rapidly when pressing down
    _rippleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45, // expands across the press and hold
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 55,
      ),
    ]).animate(_controller);

    // Animation now waits for the first compression count update to trigger
  }

  @override
  void didUpdateWidget(CprBodyAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.compressionCount > oldWidget.compressionCount) {
      _controller.forward(from: 0.0);
    } else if (widget.compressionCount == 0 && !_controller.isAnimating) {
      // Auto-loop to provide a visual rhythm guide even before first compression
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SizedBox(
              width: 300,
              height: 430,
              child: CustomPaint(
                painter: _CprBodyPainter(
                  compressionValue: _compressionAnim.value,
                  glowValue: _glowAnim.value,
                  arrowValue: _arrowAnim.value,
                  rippleValue: _rippleAnim.value,
                  accentColor: widget.feedbackColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: widget.feedbackColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          child: Text(widget.feedbackText),
        ),
      ],
    );
  }
}

class _CprBodyPainter extends CustomPainter {
  final double compressionValue; // 0 = rest, 1 = pressed
  final double glowValue;
  final double arrowValue;
  final double rippleValue;
  final Color accentColor;

  _CprBodyPainter({
    required this.compressionValue,
    required this.glowValue,
    required this.arrowValue,
    required this.rippleValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final torsoTop = 60.0;

    // How much the chest compresses inward
    final compressionDepth = compressionValue * 8.0;

    _drawGlow(canvas, cx, torsoTop, size, compressionDepth);
    _drawTorso(canvas, cx, torsoTop, size, compressionDepth);
    _drawChestHighlight(canvas, cx, torsoTop, compressionDepth);
    _drawHand(canvas, cx, torsoTop, compressionDepth);
    _drawArrows(canvas, cx, torsoTop, compressionDepth);
  }

  void _drawGlow(
      Canvas canvas, double cx, double torsoTop, Size size, double depth) {
    // Chest glow — gets brighter when pressed
    final glowCenter = Offset(cx, torsoTop + 130 + depth);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(glowValue * 0.6),
          accentColor.withOpacity(glowValue * 0.2),
          accentColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: 80));

    canvas.drawCircle(glowCenter, 80, glowPaint);
  }

  void _drawTorso(Canvas canvas, double cx, double torsoTop, Size size,
      double depth) {
    final bodyPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // --- Head ---
    canvas.drawCircle(Offset(cx, torsoTop - 20), 22, bodyPaint);

    // --- Neck ---
    canvas.drawLine(
      Offset(cx - 7, torsoTop + 2),
      Offset(cx - 7, torsoTop + 18),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(cx + 7, torsoTop + 2),
      Offset(cx + 7, torsoTop + 18),
      bodyPaint,
    );

    // --- Shoulders ---
    final shoulderY = torsoTop + 20;
    canvas.drawLine(
        Offset(cx - 7, shoulderY), Offset(cx - 70, shoulderY + 12), bodyPaint);
    canvas.drawLine(
        Offset(cx + 7, shoulderY), Offset(cx + 70, shoulderY + 12), bodyPaint);

    // --- Arms (slightly bent) ---
    // Left arm
    canvas.drawLine(Offset(cx - 70, shoulderY + 12),
        Offset(cx - 80, shoulderY + 90), bodyPaint);
    canvas.drawLine(Offset(cx - 80, shoulderY + 90),
        Offset(cx - 70, shoulderY + 150), bodyPaint);
    // Right arm
    canvas.drawLine(Offset(cx + 70, shoulderY + 12),
        Offset(cx + 80, shoulderY + 90), bodyPaint);
    canvas.drawLine(Offset(cx + 80, shoulderY + 90),
        Offset(cx + 70, shoulderY + 150), bodyPaint);

    // --- Torso outline with chest compression ---
    final torsoPath = Path();

    // Left side
    torsoPath.moveTo(cx - 70, shoulderY + 12);

    // Chest area — curves inward when compressed
    torsoPath.cubicTo(
      cx - 68, shoulderY + 50,
      cx - 55 + depth * 0.5, shoulderY + 90 + depth, // compression point
      cx - 55, shoulderY + 130,
    );

    // Waist
    torsoPath.cubicTo(
      cx - 50, shoulderY + 170,
      cx - 45, shoulderY + 200,
      cx - 50, shoulderY + 240,
    );

    // Hip
    torsoPath.lineTo(cx - 40, shoulderY + 260);

    canvas.drawPath(torsoPath, bodyPaint);

    // Right side (mirrored)
    final torsoPathR = Path();
    torsoPathR.moveTo(cx + 70, shoulderY + 12);

    torsoPathR.cubicTo(
      cx + 68, shoulderY + 50,
      cx + 55 - depth * 0.5, shoulderY + 90 + depth,
      cx + 55, shoulderY + 130,
    );

    torsoPathR.cubicTo(
      cx + 50, shoulderY + 170,
      cx + 45, shoulderY + 200,
      cx + 50, shoulderY + 240,
    );

    torsoPathR.lineTo(cx + 40, shoulderY + 260);

    canvas.drawPath(torsoPathR, bodyPaint);

    // --- Rib hints ---
    final ribPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final ribY = shoulderY + 50 + i * 22 + (i > 1 ? depth * 0.3 : 0);
      final ribW = 38.0 - i * 2;

      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, ribY), width: ribW * 2, height: 14),
        0.2,
        2.7,
        false,
        ribPaint,
      );
    }

    // --- Sternum ---
    final sternumPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(cx, shoulderY + 10),
      Offset(cx, shoulderY + 150 + depth * 0.3),
      sternumPaint,
    );
  }

  void _drawChestHighlight(
      Canvas canvas, double cx, double torsoTop, double depth) {
    final highlightCenter = Offset(cx, torsoTop + 130 + depth);

    // Ripple ring
    if (rippleValue > 0.0 && rippleValue < 1.0) {
      final rippleRadius = 32.0 + rippleValue * 80.0;
      final rippleOpacity = (1.0 - rippleValue) * 0.5;
      final ripplePaint = Paint()
        ..color = accentColor.withOpacity(rippleOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(highlightCenter, rippleRadius, ripplePaint);
    }

    // Outer ring
    final ringPaint = Paint()
      ..color = accentColor.withOpacity(0.15 + glowValue * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(highlightCenter, 32, ringPaint);

    // Inner dashed circle
    final innerPaint = Paint()
      ..color = accentColor.withOpacity(0.3 + glowValue * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw dashed circle
    const dashCount = 12;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (2 * pi / dashCount) * i;
      final sweepAngle = (2 * pi / dashCount) * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: highlightCenter, radius: 22),
        startAngle,
        sweepAngle,
        false,
        innerPaint,
      );
    }

    // Center dot
    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.4 + glowValue * 0.4);
    canvas.drawCircle(highlightCenter, 4, dotPaint);
  }

  void _drawHand(Canvas canvas, double cx, double torsoTop, double depth) {
    // Hand position moves down with compression
    final handY = torsoTop + 85 + depth * 2.5;

    // Hand shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3 * compressionValue);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, handY + 35), width: 50, height: 10),
      shadowPaint,
    );

    // Single merged hand shape (representing interlocked hands)
    final handPaint = Paint()
      ..color = Colors.white.withOpacity(0.8 + compressionValue * 0.2)
      ..style = PaintingStyle.fill;

    final handRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, handY + 10), width: 52, height: 32),
      const Radius.circular(10),
    );
    canvas.drawRRect(handRRect, handPaint);

    // Hand outline
    final handOutline = Paint()
      ..color = accentColor.withOpacity(0.5 + compressionValue * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(handRRect, handOutline);

    // Subtle interlock line in the middle
    final interlockPaint = Paint()
      ..color = accentColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(cx - 20, handY + 10),
      Offset(cx + 20, handY + 10),
      interlockPaint,
    );

    // Finger hints on bottom hand
    for (int i = 0; i < 4; i++) {
      final fx = cx - 15 + i * 10.0;
      canvas.drawLine(
        Offset(fx, handY + 26),
        Offset(fx, handY + 30),
        interlockPaint,
      );
    }

    // Arms coming from above
    final armPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Left arm
    canvas.drawLine(
      Offset(cx - 18, handY - 8),
      Offset(cx - 55, handY - 70),
      armPaint,
    );
    // Right arm
    canvas.drawLine(
      Offset(cx + 18, handY - 8),
      Offset(cx + 55, handY - 70),
      armPaint,
    );
  }

  void _drawArrows(Canvas canvas, double cx, double torsoTop, double depth) {
    // Downward pressure arrows — animate with compression
    final arrowOpacity = 0.2 + arrowValue * 0.5;
    final arrowShift = arrowValue * 12.0;

    final arrowPaint = Paint()
      ..color = accentColor.withOpacity(arrowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Three small arrows on the left side
    for (int i = 0; i < 3; i++) {
      final ax = cx - 60;
      final ay = torsoTop + 80 + i * 18 + arrowShift;
      final arrowSize = 6.0 - i * 0.5;

      // Arrow stem
      canvas.drawLine(
        Offset(ax, ay),
        Offset(ax, ay + 14),
        arrowPaint,
      );
      // Arrow head
      canvas.drawLine(
        Offset(ax - arrowSize, ay + 14 - arrowSize),
        Offset(ax, ay + 14),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(ax + arrowSize, ay + 14 - arrowSize),
        Offset(ax, ay + 14),
        arrowPaint,
      );
    }

    // Three small arrows on the right side
    for (int i = 0; i < 3; i++) {
      final ax = cx + 60;
      final ay = torsoTop + 80 + i * 18 + arrowShift;
      final arrowSize = 6.0 - i * 0.5;

      canvas.drawLine(
        Offset(ax, ay),
        Offset(ax, ay + 14),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(ax - arrowSize, ay + 14 - arrowSize),
        Offset(ax, ay + 14),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(ax + arrowSize, ay + 14 - arrowSize),
        Offset(ax, ay + 14),
        arrowPaint,
      );
    }

    // Center large arrow above hands
    final bigArrowPaint = Paint()
      ..color = accentColor.withOpacity(arrowOpacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final bay = torsoTop + 40 + arrowShift;
    canvas.drawLine(
      Offset(cx, bay),
      Offset(cx, bay + 20),
      bigArrowPaint,
    );
    canvas.drawLine(
      Offset(cx - 8, bay + 12),
      Offset(cx, bay + 20),
      bigArrowPaint,
    );
    canvas.drawLine(
      Offset(cx + 8, bay + 12),
      Offset(cx, bay + 20),
      bigArrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CprBodyPainter oldDelegate) {
    return oldDelegate.compressionValue != compressionValue ||
        oldDelegate.glowValue != glowValue ||
        oldDelegate.arrowValue != arrowValue ||
        oldDelegate.rippleValue != rippleValue ||
        oldDelegate.accentColor != accentColor;
  }
}
