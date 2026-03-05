import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech wrapper configured for Spanish (Mexico).
///
/// Ported from the Swift `SpeechService`.  Uses the `flutter_tts` package with
/// a slow speech rate appropriate for users with cognitive disabilities.
class SpeechService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  bool _isSpeaking = false;

  /// Whether the TTS engine is currently speaking.
  bool get isSpeaking => _isSpeaking;

  SpeechService() {
    _configure();
  }

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  Future<void> _configure() async {
    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _tts.setErrorHandler((message) {
      debugPrint('[SpeechService] TTS error: $message');
      _isSpeaking = false;
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Speaks the given [text].  If the engine is already speaking, the current
  /// utterance is stopped before starting the new one.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    if (_isSpeaking) {
      await _tts.stop();
    }

    await _tts.speak(text);
  }

  /// Stops any current speech immediately.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
