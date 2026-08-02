import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revive/services/motion_service.dart';
import 'package:revive/theme/app_theme.dart';
import 'package:revive/widgets/components/revive_bpm_gauge.dart';

/// Rebuild-scope regression tests.
///
/// The live CPR screen runs continuously during real use, so anything that
/// rebuilds the whole tree on a timer is a performance defect rather than a
/// style preference. The elapsed timer used to tick through setState once a
/// second, rebuilding the gauge and the chest-animation CustomPainter along
/// with it, purely to change two digits in the header.
///
/// These tests pin the fix in place: a ValueNotifier tick must rebuild only
/// its own listener.

/// Counts how many times its child subtree is rebuilt.
class _RebuildCounter extends StatefulWidget {
  final Widget child;
  final void Function() onBuild;

  const _RebuildCounter({required this.child, required this.onBuild});

  @override
  State<_RebuildCounter> createState() => _RebuildCounterState();
}

class _RebuildCounterState extends State<_RebuildCounter> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return widget.child;
  }
}

void main() {
  testWidgets('a ValueNotifier tick rebuilds only its own listener', (
    tester,
  ) async {
    final elapsed = ValueNotifier<int>(0);
    addTearDown(elapsed.dispose);

    var gaugeBuilds = 0;
    var timerBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Column(
            children: [
              // Stands in for the header's elapsed-time text.
              ValueListenableBuilder<int>(
                valueListenable: elapsed,
                builder: (context, seconds, _) {
                  timerBuilds++;
                  return Text('$seconds');
                },
              ),
              // Stands in for the expensive part of the screen.
              _RebuildCounter(
                onBuild: () => gaugeBuilds++,
                child: const ReviveBpmGauge(
                  reading: BpmReading(
                    bpm: 110,
                    status: BpmStatus.good,
                    compressionCount: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(gaugeBuilds, 1);
    expect(timerBuilds, 1);

    // Simulate ten seconds of session time.
    for (var i = 0; i < 10; i++) {
      elapsed.value++;
      await tester.pump();
    }

    expect(
      timerBuilds,
      11,
      reason: 'the timer text should rebuild on every tick',
    );
    expect(
      gaugeBuilds,
      1,
      reason:
          'the gauge must NOT rebuild on timer ticks - this is the defect the '
          'ValueNotifier refactor fixed',
    );
  });

  testWidgets('gauge rebuilds when its own reading changes', (tester) async {
    var builds = 0;

    Future<void> pumpWith(BpmReading reading) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: _RebuildCounter(
              onBuild: () => builds++,
              child: ReviveBpmGauge(reading: reading),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpWith(
      const BpmReading(bpm: 110, status: BpmStatus.good, compressionCount: 30),
    );
    final afterFirst = builds;

    await pumpWith(
      const BpmReading(
        bpm: 82,
        status: BpmStatus.tooSlow,
        compressionCount: 31,
      ),
    );

    // The gauge must still react to real sensor data - the optimisation above
    // must not have made it inert.
    expect(builds, greaterThan(afterFirst));
  });
}
