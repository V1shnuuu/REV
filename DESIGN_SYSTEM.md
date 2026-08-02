# Revive Design System

A token-driven design system for an app used one-handed, under stress, by
someone who has never opened it before and may never open it again.

Every rule below exists because of that sentence. Where a decision looks
unusual, the reasoning is stated rather than assumed.

---

## Principles

**1. Never rely on colour alone.**
Every state carries colour **and** icon **and** text **and** motion. Any one
channel alone conveys the instruction. A rescuer who is colour-blind, glancing
sideways, or has reduce-motion enabled gets the same message.

**2. Red means "stop and call for help" — nothing else.**
Out-of-range compression rate is a *normal, frequently transient* state during
correct CPR; rescuers drift in and out of the target band constantly. Flashing
alarm-red for that would dilute red's meaning and risk alarm fatigue on the one
signal that must never be ignored. Rhythm feedback therefore uses **amber** for
out-of-range, and red is reserved for urgent action.

**3. Degraded is not broken.**
When the AI is unreachable, the mic is denied, or Health Connect is missing,
the state is **amber** and says explicitly that CPR coaching is unaffected.
Only a genuinely blocking failure (no motion sensor) is red.

**4. Instructions, not observations.**
`PUSH FASTER`, not `TOO SLOW`. The rescuer needs the action, not the diagnosis.
This applies to screen-reader output too, which is deliberately fuller than the
visual label because a screen-reader user gets no colour or position cue.

**5. The critical numbers are always the largest thing on screen.**
On the live CPR screen the BPM numeral is `displayLarge`. When space is tight,
the illustration shrinks first — never the numbers.

---

## Tokens

All tokens live in `lib/theme/`. **No widget outside that directory contains a
raw hex value.** Access is through `context.colors` and `context.text`.

### Colour — `app_colors.dart`

Semantic names only, via a `ReviveColors` `ThemeExtension`, so light and dark
resolve automatically.

| Token | Purpose |
|---|---|
| `surfacePrimary` / `surfaceSunken` / `surfaceRaised` / `surfaceOverlay` | Elevation-ordered surfaces |
| `borderSubtle` / `borderStrong` | Dividers, outlines |
| `urgentAction` / `urgentActionPressed` / `onUrgentAction` / `urgentActionSubtle` | Primary CTA and emergency emphasis **only** |
| `inRangeSuccess` / `onInRangeSuccess` / `inRangeSuccessSubtle` | Correct technique |
| `belowRangeWarning` / `aboveRangeWarning` | Rhythm out of band (amber, by design) |
| `noDataNeutral` | No reading yet |
| `infoCalm` / `infoCalmSubtle` | Non-urgent notices (rescue-breath prompt) |
| `textPrimary` / `textSecondary` / `textTertiary` | Text hierarchy |

**`onUrgentAction` is near-black in dark mode, white in light mode.** White on
the dark-mode coral measures 3.09:1 — below the 4.5:1 AA floor for button
labels. Darkening the coral enough to carry white would have cost the accent
its 6.27:1 contrast as standalone text, so the label inverts instead. This was
found by the automated audit, not by eye.

### Type — `app_typography.dart`

Inter (body/labels) and Outfit (display/headings), **bundled locally as
variable fonts**. Not fetched via `google_fonts`: this app's core promise is
that it works with no connectivity, and a runtime font fetch fails silently to
system default in exactly that scenario.

15 slots mapped to Flutter's `TextTheme`. Display styles use **tabular
figures** so the BPM, compression count and timer don't jitter in width as
digits change.

| Group | Sizes | Use |
|---|---|---|
| `display` | 72 / 56 / 40 | Glanceable numerals |
| `headline` | 28 / 24 / 20 | Screen and section titles |
| `title` | 18 / 16 / 14 | Card headers, emphasis |
| `body` | 16 / 14 / 12 | Instructions and prose |
| `label` | 14 / 12 / 10 | All-caps metadata, buttons, pills |

### Spacing — `app_spacing.dart`

4pt scale (`xs` 4 → `giant` 64), plus pre-built gap widgets and page padding.

Touch targets are separate constants with intent baked in:
`minimum` 48 (Android floor, exceeds the 44pt iOS floor), `comfortable` 56,
and **`critical` 64** — used for live CPR controls, which are hit one-handed,
under stress, often without looking directly at the target.

### Shape and elevation — `app_shape.dart`

Radius scale `xs` 8 → `xxl` 36 plus `pill`. Generous and soft-edged, in the
spirit of One UI without imitating it.

Elevation is **shadow recipes that differ by brightness**, not Material's
numeric elevation: drop shadows are invisible on near-black surfaces, so dark
mode uses ambient depth and a coloured `glow()` for state reinforcement. Glow
is always paired with icon and label — never the sole signal.

### Motion — `app_motion.dart`

| Token | Duration | Use |
|---|---|---|
| `instant` | 100ms | Press feedback |
| `fast` | 150ms | Micro-interactions |
| `normal` | 220ms | Default state transitions |
| `slow` | 320ms | Entrances, page changes |
| `deliberate` | 500ms | Attention-drawing |
| `compressionCycle` | 545ms | One beat at 110 BPM |

`compressionCycle` **must stay in sync with `AudioService.compressionIntervalMs`**
— the metronome beep and the visual pulse have to land on the same beat or the
rescuer gets conflicting rhythm cues.

**`ResolvedMotion.of(context)`** resolves all of this against the platform
reduce-motion setting. Decorative loops are skipped entirely; state transitions
collapse to zero duration so state still *changes*, it just arrives without
travel. Curves become linear — the overshoot is the part that causes
discomfort.

### Haptics — `app_haptics.dart`

Flutter's `HapticFeedback` already routes to `UIImpactFeedbackGenerator` on iOS
and `HapticFeedbackConstants` on Android, so the platform work is choosing
**intensities**, not APIs: the same constant feels materially different on the
two platforms, and Android motors under-report light impacts.

| Cue | When |
|---|---|
| `compressionBeat` | Every metronome tick. Lightest reliably perceptible cue — it repeats twice a second for minutes. |
| `rangeTransition` | Crossing into/out of the 100–120 band, so the correction is felt with eyes on the patient. |
| `prompt` | Rescue-breath interruption. Heavier, must cut through the ongoing rhythm. |
| `tap` | Ordinary control confirmation. |

---

## Components

`lib/widgets/components/`. Screens compose these; they do not invent one-off
styling.

| Component | States |
|---|---|
| `ReviveButton` | primary / secondary / tertiary × standard / critical; enabled, pressed, disabled, loading, **focused** |
| `ReviveBpmGauge` | below-range, in-range, above-range, no-data; plus a `compact` variant |
| `ReviveCard` | neutral, info, caution, critical, success |
| `ReviveStatusPill` | same five tones; icon always paired with label |
| `ReviveStateView` | named constructors per real failure mode (AI unavailable, sensor missing, mic denied, Health Connect absent) |
| `ReviveLoadingView` | sized to the content it replaces, so layout doesn't jump |
| `VoiceActivityIndicator` | listening / thinking / speaking / idle |
| `ReviveDialog` | emphasis block for the line that must not be missed |

Notes on specific decisions:

- **Disabled buttons change fill, border and text colour together** — not
  opacity alone, so the state survives greyscale and high-contrast modes.
- **Disabled buttons remain focusable** and announce as disabled. A disabled
  control invisible to a screen reader leaves the user unable to tell why an
  action is missing.
- **`VoiceActivityIndicator` is deliberately not a chat bubble.** Mid-CPR the
  rescuer is not reading a transcript; they need to know at a glance whether
  the app is hearing, thinking, or talking. Listening uses a symmetric bounce
  and thinking a travelling pulse, so the states differ by *motion pattern*,
  not only hue.
- **`ReviveDialog.emphasis`** renders in its own accented, bordered block at
  title weight above the body — so "call emergency services first" cannot be
  skimmed past on the way to the dismiss button.

### Dev screens

Route-gated and absent from app navigation. Self-contained, so deleting the
file and its route removes them cleanly.

- `/dev/design` — every token, with a light/dark toggle
- `/dev/components` — every component in every state

---

## Verification

This system is enforced by tooling, not by convention. Everything below runs on
`flutter test` and in CI.

| Check | Coverage |
|---|---|
| **Contrast** (`tool/contrast_check.py`) | 66 pairings, both themes, **including alpha-composited** pill / card / dialog backgrounds. Fails the build below WCAG AA. |
| **Layout** (`test/layout_test.dart`) | 4 device sizes × 3 text scales × 2 brightnesses, plus notch/cutout inset profiles. |
| **Accessibility** (`test/accessibility_test.dart`) | Semantic labels, screen-reader activation, enabled/disabled/busy state, reduce-motion, touch targets. |
| **Rebuild scope** (`test/rebuild_test.dart`) | The gauge must not rebuild on timer ticks. |
| **Compression logic** (`test/motion_service_test.dart`) | Debounce, BPM calculation, threshold classification. |

```bash
flutter analyze --no-fatal-infos
flutter test
python tool/contrast_check.py
```

Each of these has caught a real defect that code review missed: overflowing
numerals at large text scales, white-on-coral button labels below AA, nine
buttons that screen readers could announce but not press, and a one-second
timer rebuilding the entire live CPR screen.

---

## Known gaps

- **No performance profiling on a physical device.** Rebuild scope is fixed and
  tested; frame timing under real sensor load is not measured.
- **iOS has never been built.** Android only.
- **Light mode has never been seen by a human.** It is proven to lay out
  correctly at every size, which is not the same as looking right.
- 12 analyzer infos remain in the service layer (debug `print` calls and
  `speech_to_text` deprecations). CI passes `--no-fatal-infos`; remove that
  flag once they are resolved.

See `QA_CHECKLIST.md` for what still needs a device.
