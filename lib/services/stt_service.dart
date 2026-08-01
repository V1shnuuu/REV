import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _continuousMode = false;
  bool _isPaused = false;
  Function(String)? _onResultCallback;
  Timer? _restartTimer;
  Timer? _debounceTimer;
  String _lastRecognizedWords = '';

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }

    _isInitialized = await _speechToText.initialize(
      onError: (val) {
        print('STT Error: ${val.errorMsg} - ${val.permanent}');
        // Note: Do not call _scheduleRestart() here to avoid duplicate triggers with onStatus
      },
      onStatus: (val) {
        print('STT Status: $val');
        if (val == 'done' || val == 'notListening') {
          if (_continuousMode && !_isPaused) {
            _scheduleRestart();
          }
        }
      },
    );
    return _isInitialized;
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_continuousMode && !_isPaused) {
        _startListeningInternal();
      }
    });
  }

  bool get isListening => _speechToText.isListening;

  Future<void> startContinuousListening({required Function(String) onResult}) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    _continuousMode = true;
    _isPaused = false;
    _onResultCallback = onResult;
    _startListeningInternal();
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    _continuousMode = false;
    _isPaused = false;
    _onResultCallback = onResult;
    _startListeningInternal();
  }

  Future<void> _startListeningInternal() async {
    if (!_isInitialized) return;

    // If already listening, do not interrupt it!
    if (_speechToText.isListening) return;

    _lastRecognizedWords = '';

    _speechToText.listen(
      onResult: (result) {
        final recognizedWords = result.recognizedWords.trim();
        if (recognizedWords.isNotEmpty) {
          if (recognizedWords != _lastRecognizedWords) {
            _lastRecognizedWords = recognizedWords;

            if (_continuousMode) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 1400), () {
                if (_lastRecognizedWords.isNotEmpty) {
                  final textToSubmit = _lastRecognizedWords;
                  _lastRecognizedWords = '';
                  _onResultCallback?.call(textToSubmit);
                }
              });
            }
          }

          if (result.finalResult) {
            _debounceTimer?.cancel();
            final textToSubmit = recognizedWords;
            _lastRecognizedWords = '';
            _onResultCallback?.call(textToSubmit);
          }
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 15),
      listenMode: ListenMode.deviceDefault,
      cancelOnError: false,
      partialResults: true,
      onDevice: true,
    );
  }

  Future<void> pauseListening() async {
    _isPaused = true;
    _restartTimer?.cancel();
    _debounceTimer?.cancel();
    await _speechToText.cancel();
  }

  Future<void> resumeListening() async {
    if (_continuousMode && _onResultCallback != null) {
      _isPaused = false;
      // Small delay to ensure native hardware has fully released the mic before re-binding
      await Future.delayed(const Duration(milliseconds: 250));
      _startListeningInternal();
    }
  }

  Future<void> stopListening() async {
    _continuousMode = false;
    _isPaused = false;
    _restartTimer?.cancel();
    _debounceTimer?.cancel();
    _onResultCallback = null;
    await _speechToText.cancel();
  }
}
