import 'package:flutter/material.dart';

class HandPlacementVisual extends StatefulWidget {
  const HandPlacementVisual({super.key});

  @override
  State<HandPlacementVisual> createState() => _HandPlacementVisualState();
}

class _HandPlacementVisualState extends State<HandPlacementVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowIntensity = 0.3 + (_glowController.value * 0.4);

        return Container(
          width: 280,
          height: 340,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE63946).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Body outline
              CustomPaint(
                size: const Size(280, 340),
                painter: _ChestDiagramPainter(
                  glowIntensity: glowIntensity,
                ),
              ),
              // Hand placement indicator with glow
              Positioned(
                top: 140,
                child: Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE63946),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFE63946).withOpacity(glowIntensity),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pan_tool,
                      color: Color(0xFFE63946),
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Arrow pointing down
              Positioned(
                top: 110,
                child: Column(
                  children: [
                    Icon(
                      Icons.keyboard_double_arrow_down,
                      color: Color(0xFFE63946).withOpacity(glowIntensity + 0.2),
                      size: 30,
                    ),
                  ],
                ),
              ),
              // Label
              Positioned(
                bottom: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CENTER OF CHEST',
                    style: TextStyle(
                      color: Color(0xFFE63946),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChestDiagramPainter extends CustomPainter {
  final double glowIntensity;

  _ChestDiagramPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cx = size.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, 45), 25, paint);

    // Neck
    canvas.drawLine(Offset(cx - 8, 70), Offset(cx - 8, 85), paint);
    canvas.drawLine(Offset(cx + 8, 70), Offset(cx + 8, 85), paint);

    // Shoulders
    canvas.drawLine(Offset(cx - 8, 85), Offset(cx - 70, 100), paint);
    canvas.drawLine(Offset(cx + 8, 85), Offset(cx + 70, 100), paint);

    // Torso sides
    canvas.drawLine(Offset(cx - 70, 100), Offset(cx - 60, 260), paint);
    canvas.drawLine(Offset(cx + 70, 100), Offset(cx + 60, 260), paint);

    // Rib cage hint lines
    final ribPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = 120.0 + i * 30;
      final w = 45.0 - i * 3;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, y), width: w * 2, height: 20),
        0.3,
        2.5,
        false,
        ribPaint,
      );
    }

    // Sternum line
    final sternumPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, 85), Offset(cx, 230), sternumPaint);
  }

  @override
  bool shouldRepaint(covariant _ChestDiagramPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}
