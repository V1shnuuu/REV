import 'package:flutter/material.dart';
import 'app_config.dart';

enum StepVisualType {
  none,
  handPlacement,
  compressionPractice,
  rescueBreath,
  chinPosition,
}

class CprStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final String voiceScript;
  final IconData icon;
  final String? detail;
  final StepVisualType visualType;

  const CprStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.voiceScript,
    required this.icon,
    this.detail,
    this.visualType = StepVisualType.none,
  });
}

final List<CprStep> cprSteps = [
  CprStep(
    stepNumber: 1,
    title: 'Safety & Response',
    instruction: 'Ensure area is safe. Tap shoulders and shout "Are you okay?".',
    voiceScript: 'Ensure the area is safe. Tap their shoulders firmly and shout, Are you okay?',
    icon: Icons.shield_outlined,
    detail: 'Look for hazards. If no response, proceed.',
  ),
  CprStep(
    stepNumber: 2,
    title: 'Call for Help',
    instruction: 'Shout for help. Tell someone to call ${AppConfig.emergencyNumber} and get an AED.',
    voiceScript: 'If no response, shout for help. Tell someone nearby to call emergency services and find an AED.',
    icon: Icons.phone_in_talk_outlined,
    detail: 'If alone, call emergency services yourself and put the phone on speaker.',
  ),
  CprStep(
    stepNumber: 3,
    title: 'Position the Person',
    instruction: 'Lay the person flat on their back. Tilt their head back and lift their chin to open the airway.',
    voiceScript: 'Carefully lay the person flat on their back on a firm surface. Gently tilt their head back and lift their chin to open the airway.',
    icon: Icons.person_outline,
    detail: 'A firm surface and open airway are essential for life-saving CPR.',
    visualType: StepVisualType.chinPosition,
  ),
  CprStep(
    stepNumber: 4,
    title: 'Hand Placement',
    instruction: 'Place heel of one hand in center of chest. Place other hand on top and lock fingers.',
    voiceScript: 'Step 1, hold your hands out side by side. Step 2, place one hand over the other. Step 3, interlock your fingers securely.',
    icon: Icons.pan_tool_outlined,
    detail: 'Keep arms straight and position shoulders directly over hands.',
    visualType: StepVisualType.handPlacement,
  ),
  CprStep(
    stepNumber: 5,
    title: 'Chest Compressions',
    instruction: 'Push hard and fast: 100-120 per min. At least 2 inches deep.',
    voiceScript: 'Place your interlocked hands on the center of the chest, lower half of the sternum. Push hard and fast, 100 to 120 compressions per minute. At least 2 inches deep. Allow the chest to recoil completely.',
    icon: Icons.fitness_center_outlined,
    detail: 'Allow the chest to recoil completely between compressions.',
    visualType: StepVisualType.compressionPractice,
  ),
  CprStep(
    stepNumber: 6,
    title: 'Airway & Breathing',
    instruction: 'After 30 compressions, open airway and give 2 rescue breaths.',
    voiceScript: 'After 30 compressions, open the airway using the head-tilt chin-lift maneuver. Pinch the nose shut and give two rescue breaths, each lasting 1 second, making the chest rise.',
    icon: Icons.air_outlined,
    detail: 'If the chest does not rise, re-tilt the head before the second breath.',
    visualType: StepVisualType.rescueBreath,
  ),
  CprStep(
    stepNumber: 7,
    title: 'Continue Cycle',
    instruction: 'Continue 30 compressions and 2 breaths. Or do Hands-Only CPR.',
    voiceScript: 'Continue the cycle of 30 compressions and 2 breaths. If you are untrained or uncomfortable giving breaths, perform hands-only CPR by focusing on continuous chest compressions.',
    icon: Icons.autorenew_outlined,
    detail: 'Do not stop until help arrives, an AED is ready, or the person wakes up.',
  ),
];
