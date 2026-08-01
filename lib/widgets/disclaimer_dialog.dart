import 'package:flutter/material.dart';
import '../constants/app_config.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const DisclaimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE63946).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE63946).withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE63946),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'IMPORTANT NOTICE',
              style: TextStyle(
                color: Color(0xFFE63946),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This app provides CPR guidance only. It augments a rescue — '
              'it never replaces calling for help.\n\n'
              'It is NOT a substitute for professional medical training or emergency services.\n\n'
              'Always call emergency services (${AppConfig.emergencyNumber}) yourself first. '
              'Saying "emergency," "ambulance," or "${AppConfig.emergencyNumber}" aloud will also '
              'voice-dial for you — it does not dial automatically on its own.\n\n'
              'The developers are not liable for any outcomes from using this app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'I UNDERSTAND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
