import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../main.dart';
import '../providers/app_state_provider.dart';
import '../services/camera_service.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final AIService _aiService = AIService();
  final TTSService _ttsService = TTSService();
  
  bool _isProcessing = false;
  String _statusMessage = 'Point camera at the scene';
  String _processingStep = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initialize(cameras);
    
    if (!success) {
      await _ttsService.speak('Failed to initialize camera');
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    await _ttsService.speak('Camera ready. Tap screen to capture and analyze');
    setState(() {});
  }

  Future<void> _captureAndAnalyze() async {
    if (_isProcessing) return;

    final appState = context.read<AppStateProvider>();

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing image...';
      _processingStep = '📸 Capturing...';
    });

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    await _ttsService.speak('Capturing image');

    final imageFile = await _cameraService.takePicture();

    if (imageFile == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed to capture image';
        _processingStep = '';
      });
      await _ttsService.speak('Failed to capture image. Please try again.');
      return;
    }

    setState(() {
      _statusMessage = appState.isOnlineMode 
          ? 'Analyzing with Groq AI...' 
          : 'Analyzing with device AI...';
      _processingStep = appState.isOnlineMode ? '🚀 AI Processing...' : '📱 Local Processing...';
    });

    await _ttsService.speak('Analyzing');

    final stopwatch = Stopwatch()..start();
    final description = await _aiService.analyzeImage(
      imageFile,
      appState.isOnlineMode,
    );
    stopwatch.stop();

    print('⏱️ Total analysis time: ${stopwatch.elapsedMilliseconds}ms');

    // Clean up image file
    try {
      await imageFile.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }

    setState(() {
      _isProcessing = false;
      _statusMessage = description;
      _processingStep = '';
    });

    appState.setLastDescription(description);
    await _ttsService.speak(description);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          if (_cameraService.isInitialized && _cameraService.controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraService.controller!.value.previewSize!.height,
                  height: _cameraService.controller!.value.previewSize!.width,
                  child: CameraPreview(_cameraService.controller!),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              ),
            ),

          // Tap to capture overlay
          GestureDetector(
            onTap: _captureAndAnalyze,
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Top Status Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.yellow, size: 30),
                          onPressed: () {
                            _ttsService.speak('Going back');
                            Navigator.pop(context);
                          },
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: appState.isOnlineMode ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                appState.isOnlineMode ? Icons.cloud : Icons.offline_bolt,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                appState.isOnlineMode ? 'Groq AI' : 'ML Kit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_processingStep.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _processingStep,
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom Status and Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (_isProcessing)
                      Column(
                        children: const [
                          CircularProgressIndicator(color: Colors.yellow),
                          SizedBox(height: 10),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.yellow),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: _captureAndAnalyze,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 15),
                    
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    if (!_isProcessing)
                      const Text(
                        'Tap anywhere to capture and analyze',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}