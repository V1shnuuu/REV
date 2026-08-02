# Revive: A Hybrid Edge-AI Cardiac Emergency Response System

Revive coaches bystanders through CPR in the critical minutes before EMS arrives — and it's built for exactly the situation most CPR apps ignore: **the connectivity gap**. Rural areas, disaster zones, basements, and crowded venues all have the same problem — no reliable signal at the moment someone collapses. Revive's core life-saving path never depends on a network connection to work.

> **This app augments a rescue. It never replaces one.**
> Always call emergency services yourself, first. See [Disclaimer & Liability](#disclaimer--liability) below.

---

## The problem with "AI CPR apps"

Most CPR-coaching demos wire an LLM into the compression loop for narration, then call it done. Two things about that don't hold up:

1. **The life-saving logic doesn't need an LLM.** Counting compressions and judging rhythm against a 100–120 BPM target is a threshold check on accelerometer data — arithmetic, not intelligence. An LLM sitting in that path just adds latency and a failure mode.
2. **"Offline" and "cloud-dependent LLM" are contradictory claims.** If your AI runs through a tunnel to a machine somewhere else, the app is not offline — it's hoping the network holds.

Revive is built around being honest about both of those, and using the LLM only where it earns its place.

---

## Architecture: hybrid, not offline, not cloud-only

**Works fully without connectivity — no AI dependency at all:**
- Accelerometer-based compression counting and 100–120 BPM rhythm coaching (`MotionService`)
- Audio metronome at the 110 BPM clinical target, with haptic feedback (`AudioService`)
- Full step-by-step CPR protocol, voiced via on-device TTS, pulled from a static, pre-written instruction set (`cprSteps`)
- Voice-activated emergency dialing on the keyword "emergency," "ambulance," or the local emergency number — this is local speech recognition (`onDevice: true`) triggering a phone call, no network round-trip
- An explicit **AI OFFLINE** indicator whenever the AI tunnel is unreachable, with canned rhythm/technique reminders substituted in — the rescuer never hits a dead end mid-compression

**Uses AI when available, for the one job that actually needs judgment:**
- **Bystander triage.** Before CPR starts, an optional "Quick Check" step lets the bystander describe what's happening in their own words. Gemma classifies it into cardiac arrest, choking, or drowning — three situations with three different first actions — and branches the guidance accordingly. A keyword filter can't reliably separate "he's turning blue and can't talk" (choking) from "he's turning blue and not moving" (cardiac arrest); this is a genuine natural-language classification problem.
- **Hands-free voice Q&A** during active compressions and in the standalone "Ask Gemma" chat, for anything outside the scripted protocol.
- Every AI-dependent screen rechecks connectivity and fails toward the safe, static default rather than stalling — see-cardiac-or-unknown routes to standard CPR, an unreachable tunnel skips straight to canned guidance instead of waiting out a timeout.

If the AI is unreachable at any point — tunnel down, no signal, Ollama not running — the rescuer keeps getting compression coaching, rhythm feedback, and step-by-step instructions. That's what "hybrid" means here: AI is additive, never load-bearing.

---

## Samsung platform integration

**Implemented — Health Connect incident logging.** After a CPR session ends, Revive writes an incident record (compression count, session duration, whether AI or static guidance was used) to Android Health Connect — the same on-device health data store Samsung Health reads from and writes to on modern Galaxy devices. This gives EMS or a hospital a timestamped record of what happened before they arrived, without needing a paired Watch or any second device. It fails silently and never blocks the CPR flow if Health Connect isn't installed or permission is denied.

**Next phase — Galaxy Watch haptic compression pacing.** A companion Wear OS module buzzing at the 110 BPM target would let a rescuer keep rhythm without looking at the phone. This needs a separate Wear OS build target and a physical paired Watch to test against, which wasn't feasible to build and verify overnight — flagged honestly rather than stubbed.

**Next phase — Samsung Health Sensor SDK.** Pulling heart rate/PPG from a paired Galaxy Watch to help detect or confirm a cardiac event requires Samsung partner SDK access, which isn't obtainable on a hackathon timeline. Pitched as the natural extension of the Health Connect integration already in place.

---

## Technical architecture

- **Framework:** Flutter (Dart), `StreamBuilder`-driven reactive UI
- **Sensors:** `sensors_plus` accelerometer stream, 20ms sampling, debounced peak-detection for compression counting
- **AI engine:** Gemma, served via Ollama, reached through an ngrok tunnel — used for triage classification and conversational Q&A only, never for compression counting or rhythm judgment
- **Samsung integration:** Android Health Connect (`health` package) for incident logging
- **Voice pipeline:** on-device Speech-to-Text and Text-to-Speech, continuous hands-free listening during active CPR
- **TLS:** the ngrok tunnel's certificate is trusted by hostname-scoped exception only — every other HTTPS connection gets standard certificate validation

---

## Design system

Revive is built on a token-driven design system rather than ad-hoc styling —
semantic colour tokens, a typographic scale, spacing, shape, motion and haptic
vocabularies, all in `lib/theme/`, with no raw hex values anywhere else in the
app. See **[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)**.

Two decisions worth calling out:

- **Red is reserved for "stop and call for help."** Out-of-range compression
  rate is a normal, transient state during correct CPR, so rhythm feedback uses
  amber. Using alarm-red for it would risk alarm fatigue on the one signal that
  must never be ignored.
- **Never colour alone.** Every state carries colour *and* icon *and* text
  *and* motion, so any single channel conveys the instruction on its own.

## Testing

The system is enforced by tooling, not convention:

| Check | Coverage |
|---|---|
| Compression logic | debounce, BPM calculation, threshold classification |
| Layout | 4 device sizes × 3 text scales × 2 brightnesses, plus notch/cutout insets |
| Accessibility | semantic labels, screen-reader activation, reduce-motion, touch targets |
| Rebuild scope | the BPM gauge must not rebuild on timer ticks |
| Contrast | 66 WCAG AA pairings, both themes, including alpha-composited backgrounds |

```bash
flutter analyze --no-fatal-infos && flutter test && python tool/contrast_check.py
```

Device-dependent verification that automation cannot cover is tracked in
**[QA_CHECKLIST.md](QA_CHECKLIST.md)**, along with the current known gaps.

---

## Disclaimer & Liability

- **This app provides CPR guidance only.** It is not a substitute for professional medical training or emergency services.
- **Always call emergency services yourself, first.** Voice-activated dialing (saying "emergency," "ambulance," or the emergency number aloud) is a hands-free convenience for when a rescuer's hands are occupied with compressions — it is not automatic, and it does not replace making that call.
- **The AI is a supplement, not the authority.** Triage classification and voice Q&A adapt guidance; they do not override the standard CPR protocol, and they default to that protocol whenever the classification is uncertain or unavailable.
- The developers are not liable for outcomes from using this app. See the in-app disclaimer, shown before every session.

---

## Installation and Setup

### AI backend (optional — core CPR coaching works without this)
1. Install Ollama and pull a Gemma model.
2. Expose it via `ngrok http 11434` (or run on the same network as the device).
3. Update the tunnel host in `lib/services/ollama_service.dart` (`OllamaService.ngrokHost`) and the matching TLS trust scope in `lib/main.dart`.

### Mobile app
1. Flutter 3.10+.
2. `flutter pub get`
3. Connect a physical Android device (accelerometer + Health Connect both need real hardware; Health Connect specifically needs the Health Connect app installed on Android 13 and below, or is built into Android 14+).
4. `flutter run`

---

## Credits

The original Revive CPR assistant — accelerometer compression tracking, the voice STT/TTS loop, the CPR step guide, and the animation work — was built by [@yogesh4216](https://github.com/yogesh4216). This repository is a copy of that project, shared with permission, extended here with the hybrid architecture, AI triage, Health Connect integration, and test coverage described above.

---

**Every Second Counts. Every Life Matters.**
