import 'package:speech_to_text/speech_to_text.dart' as stt;

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('STT Error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          print('STT Status: $status');
          if (status == 'notListening') {
            _isListening = false;
          }
        },
      );
      
      print('STT Service initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      print('Error initializing STT: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: false,
      );
    } catch (e) {
      print('Error starting listening: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
      }
    } catch (e) {
      print('Error stopping listening: $e');
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
    } catch (e) {
      print('Error canceling listening: $e');
    }
  }

  Future<List<stt.LocaleName>> getLocales() async {
    try {
      return await _speech.locales();
    } catch (e) {
      print('Error getting locales: $e');
      return [];
    }
  }

  void dispose() {
    _speech.cancel();
  }
}