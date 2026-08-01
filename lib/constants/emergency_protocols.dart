/// The result of AI triage classification. `cardiacArrest` and `unknown`
/// both route to the standard CPR flow — that flow is the correct default
/// when the picture is unclear, and it never depends on this classification
/// to function (see [EmergencyType.unknown]).
enum EmergencyType { cardiacArrest, choking, drowning, unknown }

class EmergencyProtocol {
  final EmergencyType type;
  final String label;
  final String voiceIntro;
  final List<String> steps;

  const EmergencyProtocol({
    required this.type,
    required this.label,
    required this.voiceIntro,
    required this.steps,
  });
}

const EmergencyProtocol chokingProtocol = EmergencyProtocol(
  type: EmergencyType.choking,
  label: 'Choking',
  voiceIntro:
      "This sounds like choking, not cardiac arrest. Switch to abdominal thrusts, not chest compressions.",
  steps: [
    'Stand behind the person and wrap your arms around their waist.',
    'Make a fist and place the thumb side just above the navel, below the ribs.',
    'Grasp your fist with your other hand and give quick, hard upward thrusts.',
    'Repeat until the object is expelled, or the person can cough or breathe.',
    'If the person becomes unresponsive, lower them to the ground and begin CPR immediately.',
  ],
);

const EmergencyProtocol drowningProtocol = EmergencyProtocol(
  type: EmergencyType.drowning,
  label: 'Drowning',
  voiceIntro:
      "This sounds like a drowning emergency. Rescue breaths come first, before any compressions.",
  steps: [
    'Remove the person from the water only if it is safe for you to do so.',
    'Check for breathing. If not breathing normally, give 5 initial rescue breaths before starting compressions.',
    'Then begin standard CPR: 30 compressions, 2 breaths, and continue that cycle.',
    'Water in the lungs can cause vomiting — turn the head to the side if this happens.',
  ],
);
