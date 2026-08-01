import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  Timer? _metronomeTimer;
  bool _isPlaying = false;
  double _volume = 1.0;

  /// Duration for one compression cycle (110 BPM target = ~545ms)
  static const int compressionIntervalMs = 545;

  bool get isPlaying => _isPlaying;

  /// Generate a short beep sound as WAV bytes
  Uint8List _generateBeepWav() {
    const int sampleRate = 44100;
    const double duration = 0.06; // 60ms beep
    const double frequency = 880.0; // A5 note
    final int numSamples = (sampleRate * duration).toInt();
    final int dataSize = numSamples * 2; // 16-bit mono

    final ByteData wav = ByteData(44 + dataSize);

    // WAV header
    // "RIFF"
    wav.setUint8(0, 0x52);
    wav.setUint8(1, 0x49);
    wav.setUint8(2, 0x46);
    wav.setUint8(3, 0x46);
    wav.setUint32(4, 36 + dataSize, Endian.little); // File size - 8
    // "WAVE"
    wav.setUint8(8, 0x57);
    wav.setUint8(9, 0x41);
    wav.setUint8(10, 0x56);
    wav.setUint8(11, 0x45);
    // "fmt "
    wav.setUint8(12, 0x66);
    wav.setUint8(13, 0x6D);
    wav.setUint8(14, 0x74);
    wav.setUint8(15, 0x20);
    wav.setUint32(16, 16, Endian.little); // Subchunk1 size
    wav.setUint16(20, 1, Endian.little); // PCM format
    wav.setUint16(22, 1, Endian.little); // Mono
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    wav.setUint16(32, 2, Endian.little); // Block align
    wav.setUint16(34, 16, Endian.little); // Bits per sample
    // "data"
    wav.setUint8(36, 0x64);
    wav.setUint8(37, 0x61);
    wav.setUint8(38, 0x74);
    wav.setUint8(39, 0x61);
    wav.setUint32(40, dataSize, Endian.little);

    // Generate sine wave with envelope
    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      // Apply fade-in/fade-out envelope
      double envelope = 1.0;
      int fadeLen = (numSamples * 0.1).toInt();
      if (i < fadeLen) {
        envelope = i / fadeLen;
      } else if (i > numSamples - fadeLen) {
        envelope = (numSamples - i) / fadeLen;
      }
      double sample = sin(2 * pi * frequency * t) * 0.8 * envelope;
      int intSample = (sample * 32767).toInt().clamp(-32768, 32767);
      wav.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return wav.buffer.asUint8List();
  }

  /// Start the metronome at CPR compression rate
  Future<void> startMetronome() async {
    if (_isPlaying) return;
    _isPlaying = true;

    final beepData = _generateBeepWav();

    // Play first beep immediately
    await _playBeep(beepData);

    _metronomeTimer = Timer.periodic(
      const Duration(milliseconds: compressionIntervalMs),
      (_) => _playBeep(beepData),
    );
  }

  Future<void> _playBeep(Uint8List beepData) async {
    try {
      HapticFeedback.lightImpact();
      await _player.setVolume(_volume);
      await _player.play(BytesSource(beepData));
    } catch (_) {
      // Silently handle playback errors
    }
  }

  /// Stop the metronome
  void stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _isPlaying = false;
    _player.stop();
  }

  /// Set metronome volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  void dispose() {
    stopMetronome();
    _player.dispose();
  }
}
