import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/app_state_provider.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TTSService _ttsService = TTSService();
  final STTService _sttService = STTService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _ttsService.initialize();
    await _sttService.initialize();
    
    // Welcome message
    await Future.delayed(const Duration(milliseconds: 500));
    await _ttsService.speak('Welcome to EyeSpeak. Tap the center button to describe your surroundings, or say "help" for instructions.');
  }

  Future<void> _startVoiceCommand() async {
    if (_isListening) return;

    setState(() => _isListening = true);
    
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    await _ttsService.speak('Listening for your command');

    await _sttService.startListening(
      onResult: (text) async {
        setState(() => _isListening = false);
        await _handleVoiceCommand(text.toLowerCase());
      },
    );
  }

  Future<void> _handleVoiceCommand(String command) async {
    print('Voice command: $command');

    if (command.contains('describe') || 
        command.contains('see') || 
        command.contains('what') ||
        command.contains('surroundings')) {
      await _openCamera();
    } else if (command.contains('settings') || command.contains('setting')) {
      await _openSettings();
    } else if (command.contains('help')) {
      await _openHelp();
    } else if (command.contains('repeat')) {
      final appState = context.read<AppStateProvider>();
      if (appState.lastDescription.isNotEmpty) {
        await _ttsService.speak(appState.lastDescription);
      } else {
        await _ttsService.speak('No previous description available');
      }
    } else {
      await _ttsService.speak('Command not recognized. Say "describe surroundings", "settings", or "help"');
    }
  }

  Future<void> _openCamera() async {
    await _ttsService.speak('Opening camera');
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
    }
  }

  Future<void> _openSettings() async {
    await _ttsService.speak('Opening settings');
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  Future<void> _openHelp() async {
    await _ttsService.speak('Opening help');
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HelpScreen()),
      );
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _startVoiceCommand(),
          onLongPress: () => _openCamera(),
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Title
                  const Text(
                    'EyeSpeak',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // Main Action Button
                  GestureDetector(
                    onTap: () => _openCamera(),
                    onLongPress: () => _startVoiceCommand(),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : Colors.yellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : Colors.yellow).withOpacity(0.5),
                            spreadRadius: 10,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.camera_alt,
                        size: 100,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _isListening 
                          ? 'Listening...'
                          : 'Tap to open camera\nLong press for voice command',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.yellow,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Bottom Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: _openSettings,
                      ),
                      _buildNavButton(
                        icon: Icons.help,
                        label: 'Help',
                        onTap: _openHelp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.yellow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.yellow),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}