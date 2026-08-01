import 'package:flutter/material.dart';

class CompressionAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final String feedbackText;

  const CompressionAnimation({
    super.key,
    required this.controller,
    required this.color,
    this.feedbackText = 'Follow the rhythm',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double scale = 1.0 - (controller.value * 0.25);
        final double outerScale = 1.0 + (controller.value * 0.15);
        final double opacity = 1.0 - (controller.value * 0.6);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple ring 3
                  Transform.scale(
                    scale: outerScale + 0.3,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(opacity * 0.15),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Outer ripple ring 2
                  Transform.scale(
                    scale: outerScale + 0.15,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(opacity * 0.25),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Outer ripple ring 1
                  Transform.scale(
                    scale: outerScale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(opacity * 0.4),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  // Glow behind main circle
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Main pulsing circle
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                          center: const Alignment(-0.2, -0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.white.withOpacity(0.9),
                              size: 48,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PUSH',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              child: Text(feedbackText),
            ),
          ],
        );
      },
    );
  }
}
