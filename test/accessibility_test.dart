import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revive/services/motion_service.dart';
import 'package:revive/theme/app_theme.dart';
import 'package:revive/widgets/components/revive_bpm_gauge.dart';
import 'package:revive/widgets/components/revive_button.dart';
import 'package:revive/widgets/components/revive_card.dart';
import 'package:revive/widgets/components/revive_state_view.dart';
import 'package:revive/widgets/components/voice_activity_indicator.dart';

/// Accessibility guarantees, asserted rather than assumed.
///
/// These cover the things a screen-reader or reduce-motion user depends on and
/// that are easy to regress silently: that state is announced in words and not
/// only in colour, that touch targets clear platform minimums, and that
/// reduce-motion genuinely stops animating rather than just running faster.

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Collects every semantic label in the tree, flattened to one string.
String _allSemanticLabels(WidgetTester tester) {
  final buffer = StringBuffer();
  void visit(SemanticsNode node) {
    buffer.write('${node.label} ');
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.rootElement!.renderObject!.debugSemantics!);
  return buffer.toString();
}

void main() {
  group('BPM state is announced in words, not only colour', () {
    testWidgets('in-range reading announces rate, instruction and count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const ReviveBpmGauge(
            reading: BpmReading(
              bpm: 110,
              status: BpmStatus.good,
              compressionCount: 42,
            ),
          ),
        ),
      );

      final labels = _allSemanticLabels(tester);
      expect(labels, contains('110'));
      expect(labels.toLowerCase(), contains('beats per minute'));
      expect(labels.toLowerCase(), contains('good rhythm'));
      expect(labels, contains('42 compressions'));
      handle.dispose();
    });

    testWidgets('out-of-range reading announces the corrective action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const ReviveBpmGauge(
            reading: BpmReading(
              bpm: 82,
              status: BpmStatus.tooSlow,
              compressionCount: 12,
            ),
          ),
        ),
      );

      // "push faster" is the instruction; "too slow" would only be an
      // observation. A screen-reader user needs the action.
      expect(_allSemanticLabels(tester).toLowerCase(), contains('push faster'));
      handle.dispose();
    });

    testWidgets('no-data state says it is waiting, not a fake zero', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const ReviveBpmGauge(reading: BpmReading.initial)),
      );

      final labels = _allSemanticLabels(tester).toLowerCase();
      expect(labels, contains('waiting for compressions'));
      handle.dispose();
    });
  });

  group('Interactive elements expose button semantics', () {
    testWidgets('enabled button is announced as an enabled button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(ReviveButton(label: 'BEGIN COMPRESSIONS', onPressed: () {})),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('BEGIN COMPRESSIONS')),
        matchesSemantics(
          label: 'BEGIN COMPRESSIONS',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets(
      'disabled button reports disabled rather than just looking it',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _wrap(const ReviveButton(label: 'DISABLED', onPressed: null)),
        );

        // Still focusable, and with no tap action. A disabled control that is
        // unreachable by a screen reader leaves the user unable to tell why
        // the action is missing, so it is announced rather than hidden.
        expect(
          tester.getSemantics(find.bySemanticsLabel('DISABLED')),
          matchesSemantics(
            label: 'DISABLED',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            isFocusable: true,
          ),
        );
        handle.dispose();
      },
    );

    testWidgets('loading button announces busy', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          ReviveButton(label: 'SENDING', onPressed: () {}, isLoading: true),
        ),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('SENDING'));
      expect(node.hint, contains('Busy'));
      handle.dispose();
    });

    testWidgets('status pill announces its meaning, not its abbreviation', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const ReviveStatusPill(
            label: 'AI OFFLINE',
            icon: Icons.cloud_off,
            tone: ReviveCardTone.caution,
            semanticLabel:
                'AI guidance offline. Core CPR coaching still active.',
          ),
        ),
      );

      expect(
        _allSemanticLabels(tester),
        contains('Core CPR coaching still active'),
      );
      handle.dispose();
    });
  });

  group('Degraded states explain themselves', () {
    testWidgets('AI-unavailable state reassures that CPR still works', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(ReviveStateView.aiUnavailable()));

      final labels = _allSemanticLabels(tester).toLowerCase();
      expect(labels, contains('ai guidance offline'));
      handle.dispose();
    });
  });

  group('Reduce motion actually stops animation', () {
    testWidgets('ResolvedMotion collapses durations and curves', (
      tester,
    ) async {
      late ResolvedMotion reduced;
      late ResolvedMotion normal;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              reduced = ResolvedMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              normal = ResolvedMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(reduced.reduceMotion, isTrue);
      expect(reduced.shouldAnimate, isFalse);
      expect(reduced.duration(AppMotion.slow), Duration.zero);
      expect(reduced.curve(AppMotion.compressionPulse), Curves.linear);

      expect(normal.reduceMotion, isFalse);
      expect(normal.shouldAnimate, isTrue);
      expect(normal.duration(AppMotion.slow), AppMotion.slow);
    });

    testWidgets('voice waveform settles instead of looping forever', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const VoiceActivityIndicator(state: VoiceActivityState.listening),
          disableAnimations: true,
        ),
      );

      // pumpAndSettle only returns if no frames remain scheduled. A still
      // running repeat() would keep scheduling and time this out, so reaching
      // the assertion proves the loop was genuinely stopped, not just sped up.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Touch targets clear platform minimums', () {
    // 48dp (Android) also satisfies the 44pt iOS floor.
    testWidgets('every button variant is at least 48dp tall', (tester) async {
      for (final variant in ReviveButtonVariant.values) {
        await tester.pumpWidget(
          _wrap(
            ReviveButton(
              key: const Key('btn'),
              label: variant.name.toUpperCase(),
              variant: variant,
              onPressed: () {},
            ),
          ),
        );
        final size = tester.getSize(find.byKey(const Key('btn')));
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: '${variant.name} button is below the 48dp minimum',
        );
      }
    });

    testWidgets('critical-size controls are larger still', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReviveButton(
            key: const Key('critical'),
            label: 'STOP SESSION',
            size: ReviveButtonSize.critical,
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('critical'))).height,
        greaterThanOrEqualTo(64),
      );
    });
  });
}
