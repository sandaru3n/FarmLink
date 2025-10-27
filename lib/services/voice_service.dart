import 'package:flutter/foundation.dart';
// import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService with ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String _recognizedText = '';
  String? _error;

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  String? get error => _error;

  /// Initialize voice services
  Future<void> initialize() async {
    if (_isDisposed) {
      print('VoiceService: Cannot initialize after disposal');
      return;
    }
    
    try {
      // Speech to text temporarily disabled due to compatibility issues
      // Initialize text to speech only
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (!_isDisposed) {
          _isSpeaking = true;
          _safeNotifyListeners();
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (!_isDisposed) {
          _isSpeaking = false;
          _safeNotifyListeners();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (!_isDisposed) {
          _setError('Text-to-speech error: $msg');
          _isSpeaking = false;
          _safeNotifyListeners();
        }
      });

      _isInitialized = true;
      _clearError();
      _safeNotifyListeners();
    } catch (e) {
      if (!_isDisposed) {
        _setError('Failed to initialize voice services: $e');
      }
    }
  }

  /// Start listening for speech input (temporarily disabled)
  Future<void> startListening({
    String? localeId,
    Function(String)? onResult,
    Function(String)? onPartialResult,
  }) async {
    // Speech to text temporarily disabled
    _setError('Speech-to-text is temporarily disabled due to compatibility issues');
  }

  /// Stop listening for speech input (temporarily disabled)
  Future<void> stopListening() async {
    // Speech to text temporarily disabled
    if (!_isDisposed) {
      _isListening = false;
      _safeNotifyListeners();
    }
  }

  /// Cancel speech recognition (temporarily disabled)
  Future<void> cancelListening() async {
    // Speech to text temporarily disabled
    if (!_isDisposed) {
      _isListening = false;
      _recognizedText = '';
      _safeNotifyListeners();
    }
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      _setError('Voice services not initialized');
      return;
    }

    try {
      _clearError();
      await _flutterTts.speak(text);
    } catch (e) {
      _setError('Failed to speak text: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      if (!_isDisposed) {
        _isSpeaking = false;
        _safeNotifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _setError('Failed to stop speaking: $e');
      }
    }
  }

  /// Set language for speech recognition (temporarily disabled)
  Future<void> setLanguage(String languageCode) async {
    try {
      // speech_to_text temporarily disabled
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      _setError('Failed to set language: $e');
    }
  }

  /// Set speech rate for text-to-speech
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      _setError('Failed to set speech rate: $e');
    }
  }

  /// Set volume for text-to-speech
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      _setError('Failed to set volume: $e');
    }
  }

  /// Set pitch for text-to-speech
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      _setError('Failed to set pitch: $e');
    }
  }

  /// Get available languages for speech recognition (temporarily disabled)
  Future<List<dynamic>> getAvailableLanguages() async {
    try {
      // speech_to_text temporarily disabled
      return [];
    } catch (e) {
      _setError('Failed to get available languages: $e');
      return [];
    }
  }

  /// Check if speech recognition is available (temporarily disabled)
  Future<bool> isSpeechRecognitionAvailable() async {
    try {
      // speech_to_text temporarily disabled
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear recognized text
  void clearRecognizedText() {
    if (!_isDisposed) {
      _recognizedText = '';
      _safeNotifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (!_isDisposed) {
      _error = error;
      _safeNotifyListeners();
    }
  }

  void _clearError() {
    if (!_isDisposed) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // _speechToText.cancel(); // temporarily disabled
    _flutterTts.stop();
    super.dispose();
  }
}
