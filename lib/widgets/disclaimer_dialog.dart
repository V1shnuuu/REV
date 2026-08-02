import 'package:flutter/material.dart';

import '../constants/app_config.dart';
import 'components/revive_dialog.dart';

/// First-run safety notice. Built on [ReviveDialog] so the
/// "call emergency services first" line is the visual focal point rather than
/// a sentence buried in body text — it renders in its own accented block at
/// title weight, above everything else.
class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return ReviveDialog.show<void>(context, dialog: const DisclaimerDialog());
  }

  @override
  Widget build(BuildContext context) {
    return ReviveDialog(
      icon: Icons.warning_amber_rounded,
      title: 'IMPORTANT NOTICE',
      emphasis:
          'Call ${AppConfig.emergencyNumber} first. This app augments a '
          'rescue — it never replaces one.',
      body:
          'Revive provides CPR guidance only. It is not a substitute for '
          'professional medical training or emergency services.\n\n'
          'Saying "emergency", "ambulance", or "${AppConfig.emergencyNumber}" '
          'aloud will voice-dial for you when your hands are busy — it does '
          'not dial automatically on its own.\n\n'
          'The developers are not liable for any outcomes from using this app.',
      confirmLabel: 'I UNDERSTAND',
    );
  }
}
