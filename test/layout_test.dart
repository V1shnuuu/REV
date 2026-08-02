import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revive/services/motion_service.dart';
import 'package:revive/theme/app_theme.dart';
import 'package:revive/widgets/components/revive_bpm_gauge.dart';
import 'package:revive/widgets/components/revive_button.dart';
import 'package:revive/widgets/components/revive_card.dart';
import 'package:revive/widgets/components/revive_dialog.dart';
import 'package:revive/widgets/components/revive_state_view.dart';
import 'package:revive/widgets/components/voice_activity_indicator.dart';

/// Layout regression tests across device sizes, text scales and brightnesses.
///
/// The live CPR screen's numerals are the app's most important pixels and also
/// the most likely to overflow, because they are large by design and sit next
/// to each other in a Row. These tests assert they survive a small phone at
/// double text scale, which is the realistic worst case for an older device
/// with accessibility text turned up.
///
/// Flutter surfaces overflow as a rendering exception, so any RenderFlex
/// overflow inside a pumped frame fails the test automatically.

/// Logical sizes (dp/pt), not physical pixels.
const _sizes = <String, Size>{
  'small phone (320x568)': Size(320, 568),
  'iPhone SE (375x667)': Size(375, 667),
  'Pixel 7 (412x915)': Size(412, 915),
  'large phone (430x932)': Size(430, 932),
};

const _textScales = <double>[1.0, 1.3, 2.0];

/// Wraps a widget in a themed, size-constrained app shell.
Widget _harness({
  required Widget child,
  required Brightness brightness,
  required double textScale,
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget widget) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('ReviveBpmGauge survives every size / text scale / brightness', () {
    // Worst case: three-digit BPM and a four-digit compression count, which is
    // the widest the numerals ever get in a real session.
    const worstCase = BpmReading(
      bpm: 148,
      status: BpmStatus.tooFast,
      compressionCount: 1024,
    );

    for (final entry in _sizes.entries) {
      for (final scale in _textScales) {
        for (final brightness in Brightness.values) {
          testWidgets('${entry.key} @ ${scale}x ${brightness.name}', (
            tester,
          ) async {
            await _pumpAt(
              tester,
              entry.value,
              _harness(
                brightness: brightness,
                textScale: scale,
                child: const ReviveBpmGauge(reading: worstCase),
              ),
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('Live-CPR-style composition does not overflow', () {
    // Approximates the stacked layout on the live screen: gauge plus voice
    // indicator plus the critical-size control, which is the densest column in
    // the app.
    Widget composition() => Column(
      children: [
        const ReviveBpmGauge(
          reading: BpmReading(
            bpm: 110,
            status: BpmStatus.good,
            compressionCount: 240,
          ),
        ),
        AppSpacing.gapMd,
        const VoiceActivityIndicator(
          state: VoiceActivityState.speaking,
          transcript: 'Push hard and fast, centre of the chest.',
        ),
        AppSpacing.gapMd,
        ReviveButton(
          label: 'STOP SESSION',
          icon: Icons.stop,
          size: ReviveButtonSize.critical,
          onPressed: () {},
        ),
      ],
    );

    for (final entry in _sizes.entries) {
      for (final scale in _textScales) {
        testWidgets('${entry.key} @ ${scale}x', (tester) async {
          await _pumpAt(
            tester,
            entry.value,
            _harness(
              brightness: Brightness.dark,
              textScale: scale,
              child: composition(),
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('State views and cards hold up at large text', () {
    for (final entry in _sizes.entries) {
      testWidgets('${entry.key} @ 2.0x', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          _harness(
            brightness: Brightness.dark,
            textScale: 2.0,
            child: Column(
              children: [
                ReviveStateView.aiUnavailable(onRetry: () {}),
                AppSpacing.gapMd,
                ReviveStateView.sensorUnavailable(onUseTapMode: () {}),
                AppSpacing.gapMd,
                const ReviveCard(
                  tone: ReviveCardTone.caution,
                  child: Text('Degraded but working'),
                ),
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    ReviveStatusPill(label: 'LIVE', icon: Icons.circle),
                    ReviveStatusPill(
                      label: 'AI OFFLINE',
                      icon: Icons.cloud_off,
                      tone: ReviveCardTone.caution,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Disclaimer dialog fits the smallest screen at large text', () {
    for (final scale in _textScales) {
      testWidgets('320x568 @ ${scale}x', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const ReviveDialog(
                icon: Icons.warning_amber_rounded,
                title: 'IMPORTANT NOTICE',
                emphasis:
                    'Call 911 first. This app augments a rescue — it never '
                    'replaces one.',
                body:
                    'Revive provides CPR guidance only. It is not a substitute '
                    'for professional medical training or emergency services.',
                confirmLabel: 'I UNDERSTAND',
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Critical content clears notches, cutouts and gesture bars', () {
    // Realistic worst-case insets. Dynamic Island devices report ~59dp top;
    // Android cutout devices land in a similar range. Bottom is the gesture
    // bar / home indicator.
    const insetCases = <String, EdgeInsets>{
      'Dynamic Island (59 top, 34 bottom)': EdgeInsets.only(
        top: 59,
        bottom: 34,
      ),
      'Android cutout (48 top, 24 bottom)': EdgeInsets.only(
        top: 48,
        bottom: 24,
      ),
      'no insets': EdgeInsets.zero,
    };

    for (final entry in insetCases.entries) {
      testWidgets('gauge stays inside safe area: ${entry.key}', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);

        const gaugeKey = Key('gauge');

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: MediaQuery(
              data: MediaQueryData(padding: entry.value),
              child: Scaffold(
                body: SafeArea(
                  child: Column(
                    children: const [
                      ReviveBpmGauge(
                        key: gaugeKey,
                        reading: BpmReading(
                          bpm: 110,
                          status: BpmStatus.good,
                          compressionCount: 42,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        final rect = tester.getRect(find.byKey(gaugeKey));
        // The gauge must begin below the top inset and end above the bottom
        // inset — i.e. never render underneath system chrome.
        expect(
          rect.top,
          greaterThanOrEqualTo(entry.value.top),
          reason: 'gauge overlaps the top inset for ${entry.key}',
        );
        expect(
          rect.bottom,
          lessThanOrEqualTo(844 - entry.value.bottom),
          reason: 'gauge overlaps the bottom inset for ${entry.key}',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Buttons meet platform touch-target minimums', () {
    testWidgets('standard >= 48dp, critical >= 64dp', (tester) async {
      await _pumpAt(
        tester,
        const Size(375, 667),
        _harness(
          brightness: Brightness.dark,
          textScale: 1.0,
          child: Column(
            children: [
              ReviveButton(
                key: const Key('standard'),
                label: 'STANDARD',
                onPressed: () {},
              ),
              ReviveButton(
                key: const Key('critical'),
                label: 'CRITICAL',
                size: ReviveButtonSize.critical,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      final standard = tester.getSize(find.byKey(const Key('standard')));
      final critical = tester.getSize(find.byKey(const Key('critical')));

      // 48dp is the Android floor and exceeds the 44pt iOS floor.
      expect(standard.height, greaterThanOrEqualTo(48));
      expect(critical.height, greaterThanOrEqualTo(64));
      expect(tester.takeException(), isNull);
    });
  });
}
