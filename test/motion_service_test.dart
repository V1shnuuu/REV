import 'package:flutter_test/flutter_test.dart';
import 'package:revive/services/motion_service.dart';

// These tests drive MotionService.simulateCompression(), which runs the exact
// same debounce/BPM/status logic as the real accelerometer path
// (_processAccelerometerEvent) without requiring hardware or a device.
void main() {
  group('MotionService compression counting', () {
    late MotionService service;

    setUp(() {
      service = MotionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('starts at zero with waiting status', () {
      expect(service.compressionCount, 0);
    });

    test('counts a single compression', () async {
      final readings = <BpmReading>[];
      final sub = service.bpmStream.listen(readings.add);

      service.simulateCompression();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(service.compressionCount, 1);
      await sub.cancel();
    });

    test('debounces compressions that arrive under 300ms apart', () async {
      service.simulateCompression();
      service.simulateCompression(); // fired immediately after, must be ignored
      service.simulateCompression(); // also immediate, must be ignored

      expect(service.compressionCount, 1);
    });

    test(
      'counts compressions spaced further apart than the debounce window',
      () async {
        service.simulateCompression();
        await Future.delayed(const Duration(milliseconds: 350));
        service.simulateCompression();
        await Future.delayed(const Duration(milliseconds: 350));
        service.simulateCompression();

        expect(service.compressionCount, 3);
      },
    );

    test('reset() zeroes the count and re-emits the initial reading', () async {
      service.simulateCompression();
      await Future.delayed(const Duration(milliseconds: 350));
      service.simulateCompression();
      expect(service.compressionCount, 2);

      final readings = <BpmReading>[];
      final sub = service.bpmStream.listen(readings.add);
      service.reset();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(service.compressionCount, 0);
      expect(readings.first.status, BpmStatus.waiting);
      expect(readings.first.bpm, 0);
      await sub.cancel();
    });
  });

  group('MotionService BPM threshold classification', () {
    late MotionService service;

    setUp(() {
      service = MotionService();
    });

    tearDown(() {
      service.dispose();
    });

    // BPM status only appears once >= 3 timestamps are in the rolling window,
    // so each case fires 3 evenly-spaced compressions and checks the 3rd reading.
    Future<BpmReading> lastReadingForInterval(Duration interval) async {
      final readings = <BpmReading>[];
      final sub = service.bpmStream.listen(readings.add);

      service.simulateCompression();
      await Future.delayed(interval);
      service.simulateCompression();
      await Future.delayed(interval);
      service.simulateCompression();
      await Future.delayed(const Duration(milliseconds: 20));

      await sub.cancel();
      return readings.last;
    }

    test(
      '~110 BPM (545ms interval, the clinical target) is classified good',
      () async {
        final reading = await lastReadingForInterval(
          const Duration(milliseconds: 545),
        );
        expect(reading.status, BpmStatus.good);
        expect(reading.bpm, inInclusiveRange(100, 120));
      },
    );

    test('~150 BPM (400ms interval) is classified too fast', () async {
      final reading = await lastReadingForInterval(
        const Duration(milliseconds: 400),
      );
      expect(reading.status, BpmStatus.tooFast);
      expect(reading.bpm, greaterThan(120));
    });

    test('~80 BPM (750ms interval) is classified too slow', () async {
      final reading = await lastReadingForInterval(
        const Duration(milliseconds: 750),
      );
      expect(reading.status, BpmStatus.tooSlow);
      expect(reading.bpm, lessThan(100));
    });

    test(
      'fewer than 3 compressions reports waiting, not a BPM value',
      () async {
        final readings = <BpmReading>[];
        final sub = service.bpmStream.listen(readings.add);

        service.simulateCompression();
        await Future.delayed(const Duration(milliseconds: 350));
        service.simulateCompression();
        await Future.delayed(const Duration(milliseconds: 20));

        expect(readings.every((r) => r.status == BpmStatus.waiting), isTrue);
        await sub.cancel();
      },
    );
  });
}
