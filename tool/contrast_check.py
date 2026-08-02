#!/usr/bin/env python3
"""WCAG 2.1 contrast audit for the Revive design tokens.

Mirrors the values in lib/theme/app_colors.dart. Run after changing any
token:  python tool/contrast_check.py

Thresholds:
  AA normal text (< 18pt, or < 14pt bold)  -> 4.5:1
  AA large text (>= 18pt, or >= 14pt bold) -> 3.0:1
  AA non-text UI components / graphics     -> 3.0:1
"""

AA_NORMAL = 4.5
AA_LARGE = 3.0

DARK = {
    "surfacePrimary": "0B0E11",
    "surfaceSunken": "070909",
    "surfaceRaised": "14181C",
    "surfaceOverlay": "1C2229",
    "urgentAction": "FF5A45",
    "urgentActionPressed": "E64A36",
    # Near-black rather than white: see note in app_colors.dart.
    "onUrgentAction": "0B0E11",
    "inRangeSuccess": "3DDC97",
    "onInRangeSuccess": "0B0E11",
    "belowRangeWarning": "FFC24B",
    "aboveRangeWarning": "FF9A3D",
    "noDataNeutral": "8A94A0",
    "infoCalm": "4FB0F5",
    "textPrimary": "F2F5F7",
    "textSecondary": "A8B2BD",
    "textTertiary": "6B7480",
}

LIGHT = {
    "surfacePrimary": "F5F7F9",
    "surfaceSunken": "E8ECEF",
    "surfaceRaised": "FFFFFF",
    "surfaceOverlay": "FFFFFF",
    "urgentAction": "C7371F",
    "urgentActionPressed": "A82C17",
    "onUrgentAction": "FFFFFF",
    "inRangeSuccess": "0B7A57",
    "onInRangeSuccess": "FFFFFF",
    "belowRangeWarning": "8A5A00",
    "aboveRangeWarning": "9C4600",
    "noDataNeutral": "5C6570",
    "infoCalm": "0B5FA8",
    "textPrimary": "0B0E11",
    "textSecondary": "454F5A",
    "textTertiary": "6B7480",
}

# (foreground, background, minimum_ratio, description)
PAIRINGS = [
    ("textPrimary", "surfacePrimary", AA_NORMAL, "body text on page"),
    ("textPrimary", "surfaceRaised", AA_NORMAL, "body text on card"),
    ("textPrimary", "surfaceOverlay", AA_NORMAL, "body text on overlay"),
    ("textSecondary", "surfacePrimary", AA_NORMAL, "secondary text on page"),
    ("textSecondary", "surfaceRaised", AA_NORMAL, "secondary text on card"),
    ("textTertiary", "surfacePrimary", AA_LARGE, "tertiary/meta text on page"),
    ("urgentAction", "surfacePrimary", AA_LARGE, "CTA accent / large numerals"),
    ("urgentAction", "surfaceRaised", AA_LARGE, "CTA accent on card"),
    ("onUrgentAction", "urgentAction", AA_NORMAL, "button label on CTA fill"),
    ("onUrgentAction", "urgentActionPressed", AA_NORMAL, "button label, pressed"),
    ("inRangeSuccess", "surfacePrimary", AA_LARGE, "in-range BPM numerals"),
    ("inRangeSuccess", "surfaceRaised", AA_LARGE, "in-range on card"),
    ("onInRangeSuccess", "inRangeSuccess", AA_NORMAL, "label on success fill"),
    ("belowRangeWarning", "surfacePrimary", AA_LARGE, "too-slow numerals"),
    ("belowRangeWarning", "surfaceRaised", AA_LARGE, "too-slow on card"),
    ("aboveRangeWarning", "surfacePrimary", AA_LARGE, "too-fast numerals"),
    ("aboveRangeWarning", "surfaceRaised", AA_LARGE, "too-fast on card"),
    ("noDataNeutral", "surfacePrimary", AA_LARGE, "no-data state"),
    ("infoCalm", "surfacePrimary", AA_LARGE, "info / breath prompt"),
    ("infoCalm", "surfaceRaised", AA_LARGE, "info on card"),
]


# Alpha-composited pairings: (foreground, overlay, overlay_alpha, base,
# minimum_ratio, description).
#
# The components do not only put solid colours on solid colours. Status pills,
# card tones and state views paint an accent at low alpha over a surface and
# then place full-strength accent text on top. The effective background is the
# composite, not either token on its own, so these need checking separately -
# they are exactly the pairings a token-only audit misses.
COMPOSITE_PAIRINGS = [
    # ReviveStatusPill / ReviveCard: accent @ ~0.12 over a surface.
    ("urgentAction", "urgentAction", 0.12, "surfaceRaised", AA_LARGE,
     "pill label on urgent tint"),
    ("inRangeSuccess", "inRangeSuccess", 0.12, "surfaceRaised", AA_LARGE,
     "pill label on success tint"),
    ("belowRangeWarning", "belowRangeWarning", 0.12, "surfaceRaised", AA_LARGE,
     "pill label on caution tint"),
    ("infoCalm", "infoCalm", 0.12, "surfaceRaised", AA_LARGE,
     "pill label on info tint"),
    ("noDataNeutral", "noDataNeutral", 0.12, "surfaceRaised", AA_LARGE,
     "pill label on neutral tint"),
    # ReviveCard tones over the page surface: body text on the tinted card.
    ("textPrimary", "urgentAction", 0.10, "surfacePrimary", AA_NORMAL,
     "body text on critical card"),
    ("textPrimary", "belowRangeWarning", 0.10, "surfacePrimary", AA_NORMAL,
     "body text on caution card"),
    ("textPrimary", "infoCalm", 0.10, "surfacePrimary", AA_NORMAL,
     "body text on info card"),
    ("textSecondary", "belowRangeWarning", 0.10, "surfacePrimary", AA_NORMAL,
     "secondary text on caution card"),
    ("textSecondary", "infoCalm", 0.10, "surfacePrimary", AA_NORMAL,
     "secondary text on info card"),
    # ReviveStateView: accent icon/heading on its tinted card.
    ("belowRangeWarning", "belowRangeWarning", 0.10, "surfacePrimary",
     AA_LARGE, "degraded-state icon on its own tint"),
    ("urgentAction", "urgentAction", 0.10, "surfacePrimary", AA_LARGE,
     "blocking-state icon on its own tint"),
    # Dialog emphasis block: the line that must not be missed.
    ("textPrimary", "urgentAction", 0.14, "surfaceRaised", AA_NORMAL,
     "dialog emphasis text on urgent tint"),
]


def composite(overlay_hex: str, alpha: float, base_hex: str) -> str:
    """Flatten `overlay` at `alpha` over `base`, returning a solid hex."""
    out = []
    for i in (0, 2, 4):
        o = int(overlay_hex[i:i + 2], 16)
        b = int(base_hex[i:i + 2], 16)
        out.append(round(o * alpha + b * (1 - alpha)))
    return "".join(f"{c:02X}" for c in out)


def _channel(v: float) -> float:
    v /= 255.0
    return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4


def luminance(hex_color: str) -> float:
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b)


def contrast(fg: str, bg: str) -> float:
    a, b = luminance(fg), luminance(bg)
    lighter, darker = max(a, b), min(a, b)
    return (lighter + 0.05) / (darker + 0.05)


def audit(name: str, tokens: dict) -> int:
    print(f"\n{'=' * 78}\n  {name}\n{'=' * 78}")
    print(f"{'foreground':<22}{'background':<20}{'ratio':>8}  {'min':>5}  result")
    print("-" * 78)
    failures = 0
    for fg, bg, minimum, desc in PAIRINGS:
        ratio = contrast(tokens[fg], tokens[bg])
        ok = ratio >= minimum
        if not ok:
            failures += 1
        mark = "PASS" if ok else "FAIL"
        print(f"{fg:<22}{bg:<20}{ratio:>7.2f}:1  {minimum:>5.1f}  {mark}   {desc}")

    print(f"\n  -- alpha-composited backgrounds --")
    for fg, overlay, alpha, base, minimum, desc in COMPOSITE_PAIRINGS:
        effective = composite(tokens[overlay], alpha, tokens[base])
        ratio = contrast(tokens[fg], effective)
        ok = ratio >= minimum
        if not ok:
            failures += 1
        mark = "PASS" if ok else "FAIL"
        label = f"{overlay}@{alpha:g}/{base}"
        print(f"{fg:<22}{label:<20}{ratio:>7.2f}:1  {minimum:>5.1f}  {mark}   {desc}")
    return failures


if __name__ == "__main__":
    total = audit("DARK THEME", DARK) + audit("LIGHT THEME", LIGHT)
    print(f"\n{'=' * 78}")
    print("ALL PAIRINGS PASS" if total == 0 else f"{total} FAILING PAIRING(S)")
    print("=" * 78)
    raise SystemExit(1 if total else 0)
