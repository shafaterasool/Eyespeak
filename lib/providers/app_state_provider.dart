import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateProvider with ChangeNotifier {
  bool _isOnlineMode = true;
  double _voiceSpeed = 1.0;
  String _selectedLanguage = 'en-US';
  bool _isProcessing = false;
  String _lastDescription = '';

  // Getters
  bool get isOnlineMode => _isOnlineMode;
  double get voiceSpeed => _voiceSpeed;
  String get selectedLanguage => _selectedLanguage;
  bool get isProcessing => _isProcessing;
  String get lastDescription => _lastDescription;

  AppStateProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnlineMode = prefs.getBool('isOnlineMode') ?? true;
      _voiceSpeed = prefs.getDouble('voiceSpeed') ?? 1.0;
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'en-US';
      notifyListeners();
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> setOnlineMode(bool value) async {
    _isOnlineMode = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnlineMode', value);
    } catch (e) {
      print('Error saving online mode: $e');
    }
  }

  Future<void> setVoiceSpeed(double value) async {
    _voiceSpeed = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('voiceSpeed', value);
    } catch (e) {
      print('Error saving voice speed: $e');
    }
  }

  Future<void> setLanguage(String value) async {
    _selectedLanguage = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', value);
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void setLastDescription(String description) {
    _lastDescription = description;
    notifyListeners();
  }

  Map<String, dynamic> getSettings() {
    return {
      'isOnlineMode': _isOnlineMode,
      'voiceSpeed': _voiceSpeed,
      'selectedLanguage': _selectedLanguage,
    };
  }
}