import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

enum BpmStatus { tooSlow, good, tooFast, waiting }

class BpmReading {
  final double bpm;
  final BpmStatus status;
  final int compressionCount;

  const BpmReading({
    required this.bpm,
    required this.status,
    required this.compressionCount,
  });

  static const BpmReading initial = BpmReading(
    bpm: 0,
    status: BpmStatus.waiting,
    compressionCount: 0,
  );
}

class MotionService {
  static const double _threshold = 12.0; // Z-axis threshold for compression
  static const int _debounceMs = 300; // Prevent double-counting
  static const int _windowSize = 6; // Rolling window for BPM calc

  StreamSubscription<AccelerometerEvent>? _subscription;
  final List<int> _timestamps = [];
  int _compressionCount = 0;
  int _lastCompressionTime = 0;

  final StreamController<BpmReading> _bpmController =
      StreamController<BpmReading>.broadcast();

  Stream<BpmReading> get bpmStream => _bpmController.stream;
  int get compressionCount => _compressionCount;

  /// Start listening to accelerometer
  void startListening() {
    _compressionCount = 0;
    _timestamps.clear();
    _lastCompressionTime = 0;

    _bpmController.add(BpmReading.initial);

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      _processAccelerometerEvent(event);
    });
  }

  void _processAccelerometerEvent(AccelerometerEvent event) {
    final double z = event.z;
    final int now = DateTime.now().millisecondsSinceEpoch;

    // Detect a downward compression push
    if (z > _threshold && (now - _lastCompressionTime) > _debounceMs) {
      _lastCompressionTime = now;
      _compressionCount++;
      _timestamps.add(now);

      // Keep rolling window
      if (_timestamps.length > _windowSize) {
        _timestamps.removeAt(0);
      }

      // Calculate BPM when we have enough data
      if (_timestamps.length >= 3) {
        final int diff = _timestamps.last - _timestamps.first;
        if (diff > 0) {
          final double bpm =
              ((_timestamps.length - 1) / (diff / 60000.0));
          _bpmController.add(BpmReading(
            bpm: bpm,
            status: _evaluateBpm(bpm),
            compressionCount: _compressionCount,
          ));
        }
      } else {
        _bpmController.add(BpmReading(
          bpm: 0,
          status: BpmStatus.waiting,
          compressionCount: _compressionCount,
        ));
      }
    }
  }

  BpmStatus _evaluateBpm(double bpm) {
    if (bpm < 100) return BpmStatus.tooSlow;
    if (bpm > 120) return BpmStatus.tooFast;
    return BpmStatus.good;
  }

  /// Simulate a compression (for testing on devices without accelerometer)
  void simulateCompression() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if ((now - _lastCompressionTime) > _debounceMs) {
      _lastCompressionTime = now;
      _compressionCount++;
      _timestamps.add(now);

      if (_timestamps.length > _windowSize) {
        _timestamps.removeAt(0);
      }

      if (_timestamps.length >= 3) {
        final int diff = _timestamps.last - _timestamps.first;
        if (diff > 0) {
          final double bpm =
              ((_timestamps.length - 1) / (diff / 60000.0));
          _bpmController.add(BpmReading(
            bpm: bpm,
            status: _evaluateBpm(bpm),
            compressionCount: _compressionCount,
          ));
        }
      } else {
        _bpmController.add(BpmReading(
          bpm: 0,
          status: BpmStatus.waiting,
          compressionCount: _compressionCount,
        ));
      }
    }
  }

  /// Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void reset() {
    _compressionCount = 0;
    _timestamps.clear();
    _lastCompressionTime = 0;
    _bpmController.add(BpmReading.initial);
  }

  void dispose() {
    stopListening();
    _bpmController.close();
  }
}
