import 'package:flutter/material.dart';
import '../services/motion_service.dart';

class BpmGauge extends StatelessWidget {
  final BpmReading reading;

  const BpmGauge({super.key, required this.reading});

  Color get _statusColor {
    switch (reading.status) {
      case BpmStatus.good:
        return const Color(0xFF2ECC71);
      case BpmStatus.tooSlow:
        return const Color(0xFFF39C12);
      case BpmStatus.tooFast:
        return const Color(0xFFE74C3C);
      case BpmStatus.waiting:
        return const Color(0xFF6C757D);
    }
  }

  String get _statusText {
    switch (reading.status) {
      case BpmStatus.good:
        return 'PERFECT RHYTHM';
      case BpmStatus.tooSlow:
        return 'PUSH FASTER';
      case BpmStatus.tooFast:
        return 'SLOW DOWN';
      case BpmStatus.waiting:
        return 'START PUSHING';
    }
  }

  IconData get _statusIcon {
    switch (reading.status) {
      case BpmStatus.good:
        return Icons.check_circle_outline;
      case BpmStatus.tooSlow:
        return Icons.fast_forward;
      case BpmStatus.tooFast:
        return Icons.speed;
      case BpmStatus.waiting:
        return Icons.touch_app;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_statusIcon, color: _statusColor, size: 22),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                child: Text(_statusText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetric(
                'BPM',
                reading.bpm > 0 ? reading.bpm.toStringAsFixed(0) : '--',
                _statusColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.1),
              ),
              _buildMetric(
                'COMPRESSIONS',
                reading.compressionCount.toString(),
                Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Target zone indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  // Target zone (100-120 BPM mapped to 0-1)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0,
                    child: Row(
                      children: [
                        // Too slow zone
                        Expanded(
                          flex: 100,
                          child: Container(
                            color: const Color(0xFFF39C12).withOpacity(0.3),
                          ),
                        ),
                        // Good zone
                        Expanded(
                          flex: 20,
                          child: Container(
                            color: const Color(0xFF2ECC71).withOpacity(0.5),
                          ),
                        ),
                        // Too fast zone
                        Expanded(
                          flex: 80,
                          child: Container(
                            color: const Color(0xFFE74C3C).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current BPM indicator
                  if (reading.bpm > 0)
                    Positioned(
                      left: _bpmToPosition(reading.bpm, 1.0),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '60',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
              Text(
                'TARGET: 100-120',
                style: TextStyle(
                  color: const Color(0xFF2ECC71).withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '200',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _bpmToPosition(double bpm, double maxWidth) {
    // Map BPM 60-200 to 0-maxWidth
    return ((bpm - 60) / 140).clamp(0.0, 1.0) * maxWidth;
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
