
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TTSService _ttsService = TTSService();
  int _currentStep = 0;

  final List<Map<String, String>> _helpSteps = [
    {
      'title': 'Welcome to EyeSpeak',
      'description': 'EyeSpeak is your AI-powered assistant that helps you understand your surroundings through your phone camera and voice commands.',
    },
    {
      'title': 'How to Use',
      'description': 'From the home screen, tap the large yellow button to open the camera. Point your camera at any scene and tap the screen to capture and analyze it.',
    },
    {
      'title': 'Voice Commands',
      'description': 'You can also use voice commands. Long press the home button and say "describe surroundings", "settings", "help", or "repeat" to hear the last description again.',
    },
    {
      'title': 'Online and Offline Modes',
      'description': 'In online mode, EyeSpeak uses advanced AI for detailed descriptions. In offline mode, it uses on-device AI for faster, private analysis.',
    },
    {
      'title': 'Settings',
      'description': 'You can adjust voice speed, change language, and switch between online and offline modes in the settings menu.',
    },
    {
      'title': 'Getting Started',
      'description': 'Ready to start? Return to the home screen and try capturing a scene. EyeSpeak will describe what it sees.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _announceCurrentStep();
  }

  Future<void> _announceCurrentStep() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final step = _helpSteps[_currentStep];
    await _ttsService.speak('${step['title']}. ${step['description']}');
  }

  void _nextStep() {
    if (_currentStep < _helpSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _announceCurrentStep();
    } else {
      _ttsService.speak('End of tutorial. Going back to home.');
      Navigator.pop(context);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _announceCurrentStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _helpSteps[_currentStep];

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
          'Help & Tutorial',
          style: TextStyle(color: Colors.yellow, fontSize: 28),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _helpSteps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentStep
                        ? Colors.yellow
                        : Colors.grey[700],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Step Content
            Expanded(
              child: GestureDetector(
                onTap: () => _ttsService.speak('${step['title']}. ${step['description']}'),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.yellow, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconForStep(_currentStep),
                        size: 80,
                        color: Colors.yellow,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        step['title']!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step['description']!,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: _previousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 5),
                        Text(
                          'Previous',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentStep == _helpSteps.length - 1 ? 'Finish' : 'Next',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Icon(_currentStep == _helpSteps.length - 1 ? Icons.check : Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Actions
            Text(
              'Step ${_currentStep + 1} of ${_helpSteps.length}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForStep(int step) {
    switch (step) {
      case 0:
        return Icons.waving_hand;
      case 1:
        return Icons.camera_alt;
      case 2:
        return Icons.mic;
      case 3:
        return Icons.cloud;
      case 4:
        return Icons.settings;
      case 5:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}