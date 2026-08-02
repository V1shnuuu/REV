# Manual QA Checklist

Everything in this file needs a **physical device**. Anything that could be
verified programmatically already has been, and is listed under
[Already automated](#already-automated) — don't re-do those by hand.

Run `flutter test` first. If it fails, stop; nothing below is worth doing until
it passes.

---

## Priority 1 — never shipped, never seen

These have never been observed by a human. Do these before anything else.

- [ ] **Light mode, every screen.** `themeMode` follows the system setting, and
      light mode has been proven to *lay out* correctly at every size — that is
      not the same as looking right. Toggle the system theme and walk all five
      screens.
- [ ] **Health Connect write.** Run a session of 5+ compressions, stop it, and
      confirm the "Incident logged to Health Connect" snackbar appears **and**
      that the record actually shows up in Health Connect / Samsung Health.
      Compiles correctly; has never executed.
- [ ] **AI triage branch.** Say a choking description ("he's choking, can't
      breathe, clutching his throat") and confirm it routes to the choking
      protocol rather than straight to CPR. Repeat for drowning.
- [ ] **Haptics.** Simulators do not vibrate. On device, confirm: the
      compression beat is felt but not numbing over ~2 minutes; the
      range-transition buzz is distinguishable from the beat; the rescue-breath
      prompt is heavier still.

## Priority 2 — accessibility on device

- [ ] **TalkBack (Android) on the live CPR screen.** Confirm the BPM gauge
      announces rate, instruction and compression count — and that it
      *re-announces* as the rate changes (it is a live region).
- [ ] **VoiceOver (iOS)** equivalent.
- [ ] **Screen-reader activation.** Double-tap the START button, the close
      button, and the mic button with the reader on. All nine semantic buttons
      were announced-but-unactivatable until this phase; verify the fix on real
      assistive tech, not just in tests.
- [ ] **Reduce motion.** Enable it system-wide. The voice waveform should be
      static, the home-screen pulse and breathe should stop entirely, and the
      gauge glow should disappear. Nothing should merely animate faster.
- [ ] **Large text.** Set system font size to maximum. Layout is proven not to
      overflow; confirm it is still *readable* and the BPM numeral is still the
      dominant element.

## Priority 3 — connectivity and degradation

- [ ] **Airplane mode, cold start.** Fonts must render as Inter/Outfit, not a
      system fallback — this is the whole point of bundling them.
- [ ] **Airplane mode, full flow.** Home shows "AI OFFLINE"; triage skips
      straight to CPR; live CPR shows the AI OFFLINE pill and speaks canned
      fallback tips with no long pause; chat opens with the offline message and
      no suggestion chips.
- [ ] **Tunnel drop mid-session.** Start a session with AI reachable, then kill
      the ngrok tunnel. The pill should appear within ~20s and the voice
      assistant should fall back without a 30s hang.
- [ ] **Deny microphone permission.** Every screen using voice should show the
      degraded state with a route into settings, not a dead mic button.
- [ ] **Speech recognition still works after the `SpeechListenOptions`
      migration.** The deprecated `listen()` parameters were moved into the
      options object with identical values, and it compiles — but this is the
      hands-free voice path and has not run on hardware since the change.
      Confirm continuous listening, the 1.4s debounce, and auto-restart all
      still behave, and that recognition stays **on-device** in airplane mode.

## Priority 4 — platform and form factor

- [ ] **Small phone** (~320–375dp wide) and **large phone** (~430dp). Layout is
      automated; confirm nothing *looks* cramped or lost.
- [ ] **Notch / Dynamic Island / punch-hole.** Nothing critical underneath.
      Automated for the gauge; eyeball the rest.
- [ ] **Gesture navigation bar.** The critical-size STOP/BEGIN control must not
      sit under the home indicator.
- [ ] **iOS back-swipe** from the screen edge behaves.
- [ ] **Rotation.** Portrait is locked deliberately — confirm the app does not
      rotate. See `main.dart` for why (Z-axis compression detection assumes a
      fixed orientation).
- [ ] **Interruptions.** Take a phone call mid-session; background and resume.
      The metronome and mic should stop and restart cleanly.

## Priority 5 — the one-handed claim

- [ ] Hold the phone one-handed, thumb only, and run a full session: start,
      register compressions, respond to the breath prompt, stop. If any control
      needs a second hand, that is a finding.

---

## Already automated

Do not spend device time on these — they run in CI and on `flutter test`.

| Area | Coverage | Where |
|---|---|---|
| WCAG AA contrast | 66 pairings, both themes, **including alpha-composited** pill/card/dialog backgrounds | `tool/contrast_check.py` |
| Layout overflow | 4 device sizes x 3 text scales x 2 brightnesses | `test/layout_test.dart` |
| Safe-area insets | Dynamic Island + Android cutout profiles | `test/layout_test.dart` |
| Touch targets | every button variant >= 48dp, critical >= 64dp | `test/layout_test.dart`, `test/accessibility_test.dart` |
| Semantic labels | gauge announces rate/instruction/count; pills announce meaning | `test/accessibility_test.dart` |
| Screen-reader activation | tap action present on buttons | `test/accessibility_test.dart` |
| Reduce motion | durations collapse; waveform genuinely stops | `test/accessibility_test.dart` |
| Compression logic | debounce, BPM calculation, threshold classification | `test/motion_service_test.dart` |

## Known gaps

- **Performance profiling is not done.** Phase 6. The compression pulse and
  gauge run continuously during real use and have not been checked for dropped
  frames. This needs a profile-mode run on a physical device.
- **iOS has never been built.** Only Android debug builds have been verified.
