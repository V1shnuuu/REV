/// Single source of truth for the number "voice-activated emergency dialing"
/// calls. Hardcoding 911 breaks outside the US/Canada — most regions Samsung
/// ships in use a different emergency line (e.g. 112 in the EU/India, 108 for
/// ambulance specifically in India, 999 in the UK).
///
/// For the hackathon demo this stays as a single constant so it's a one-line
/// change to retarget for a judging region; a future phase should detect the
/// device locale/SIM country and pick automatically.
class AppConfig {
  AppConfig._();

  static const String emergencyNumber = '911';
}
