import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4); // Slow and clear for emergencies
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.9); // Slightly lower pitch — calmer

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (_onComplete != null) _onComplete!();
    });

    _isInitialized = true;
  }

  Function? _onComplete;
  void setOnComplete(Function? callback) => _onComplete = callback;

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    // Stop any current speech before starting new
    if (_isSpeaking) {
      await _tts.stop();
    }

    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  bool get isSpeaking => _isSpeaking;

  Future<void> dispose() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}
