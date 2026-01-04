import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/tts_service.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TTSService _ttsService = TTSService();
  final AIService _aiService = AIService();
  bool _testingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _announce();
  }

  Future<void> _announce() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ttsService.speak('Settings screen. You can toggle online mode, adjust voice speed, and select language.');
  }

  Future<void> _testGroqConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = null;
    });

    await _ttsService.speak('Testing Groq AI connection');

    final isConnected = await _aiService.testGroqConnection();

    setState(() {
      _testingConnection = false;
      _connectionStatus = isConnected 
          ? '✅ Groq AI Connected' 
          : '❌ Groq AI Not Connected (Check API Key)';
    });

    await _ttsService.speak(_connectionStatus!);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.yellow, size: 30),
          onPressed: () {
            _ttsService.speak('Going back');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.yellow, fontSize: 28),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Online/Offline Mode
          _buildSettingCard(
            title: 'AI Mode',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.isOnlineMode ? 'Online (Groq AI)' : 'Offline (ML Kit)',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          appState.isOnlineMode 
                              ? 'Fast, detailed descriptions' 
                              : 'Works without internet',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: appState.isOnlineMode,
                      onChanged: (value) async {
                        await appState.setOnlineMode(value);
                        await _ttsService.speak(
                          value ? 'Switched to online mode with Groq AI' : 'Switched to offline mode with ML Kit'
                        );
                      },
                      activeColor: Colors.yellow,
                      activeTrackColor: Colors.yellow.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (appState.isOnlineMode)
                  ElevatedButton.icon(
                    onPressed: _testingConnection ? null : _testGroqConnection,
                    icon: _testingConnection
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_testingConnection ? 'Testing...' : 'Test Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.withOpacity(0.2),
                      foregroundColor: Colors.yellow,
                    ),
                  ),
                if (_connectionStatus != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _connectionStatus!,
                    style: TextStyle(
                      fontSize: 16,
                      color: _connectionStatus!.contains('✅') ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Voice Speed
          _buildSettingCard(
            title: 'Voice Speed',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speed: ${appState.voiceSpeed.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 10),
                Slider(
                  value: appState.voiceSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: appState.voiceSpeed.toStringAsFixed(1),
                  activeColor: Colors.yellow,
                  inactiveColor: Colors.yellow.withOpacity(0.3),
                  onChanged: (value) async {
                    await appState.setVoiceSpeed(value);
                    await _ttsService.setSpeechRate(value);
                  },
                  onChangeEnd: (value) async {
                    await _ttsService.speak('Voice speed set to ${value.toStringAsFixed(1)}');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Language Selection
          _buildSettingCard(
            title: 'Language',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguageOption('English (US)', 'en-US', appState),
                _buildLanguageOption('English (UK)', 'en-GB', appState),
                _buildLanguageOption('Spanish', 'es-ES', appState),
                _buildLanguageOption('French', 'fr-FR', appState),
                _buildLanguageOption('German', 'de-DE', appState),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Test Voice Button
          _buildTestVoiceButton(),

          const SizedBox(height: 20),

          // Info Section
          _buildSettingCard(
            title: 'About',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Version', '1.0.0'),
                const SizedBox(height: 10),
                _buildInfoRow('Online AI', 'Groq (Llama 3.2 Vision)'),
                const SizedBox(height: 10),
                _buildInfoRow('Offline AI', 'Google ML Kit'),
                const SizedBox(height: 10),
                _buildInfoRow('Developer', 'Danial Murtaza'),
                const SizedBox(height: 10),
                _buildInfoRow('University', 'IUB'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => _ttsService.speak(title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String label,
    String code,
    AppStateProvider appState,
  ) {
    final isSelected = appState.selectedLanguage == code;

    return GestureDetector(
      onTap: () async {
        await appState.setLanguage(code);
        await _ttsService.setLanguage(code);
        await _ttsService.speak('Language changed to $label');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.grey,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: Colors.yellow,
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                color: isSelected ? Colors.yellow : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestVoiceButton() {
    return ElevatedButton(
      onPressed: () async {
        await _ttsService.speak(
          'This is a test of the text to speech system. You are currently using EyeSpeak with Groq AI.'
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(20),
      ),
      child: const Text(
        'Test Voice',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.yellow,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}