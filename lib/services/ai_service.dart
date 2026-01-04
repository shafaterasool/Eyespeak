import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mlkit_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final MLKitService _mlKitService = MLKitService();
  
  // 🔐 Your Groq API Key
  static const String _groqApiKey = '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';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // ✅ Helper to check if API key is configured
  bool get _hasValidApiKey {
    return _groqApiKey.isNotEmpty && 
           _groqApiKey.startsWith('gsk_') && 
           _groqApiKey.length > 20;
  }

  Future<String> analyzeImage(File imageFile, bool isOnlineMode) async {
    // ✅ FIXED: Simple and clear logic
    if (isOnlineMode && _hasValidApiKey) {
      print('🌐 Online mode: Using Groq AI');
      return await _analyzeWithGroq(imageFile);
    } else {
      if (!_hasValidApiKey) {
        print('⚠️ No valid API key, using offline mode');
      } else {
        print('📱 Offline mode selected: Using ML Kit');
      }
      return await _analyzeWithMLKit(imageFile);
    }
  }

  Future<String> _analyzeWithGroq(File imageFile, {int retries = 2}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        print('🚀 Analyzing with Groq AI (attempt ${attempt + 1}/$retries)...');
        final stopwatch = Stopwatch()..start();
        
        // Convert image to base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        print('📸 Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

        // Optimized prompt for visually impaired users
        final response = await http.post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: jsonEncode({
            'model': _groqModel,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text': '''You are EyeSpeak AI, an assistant for visually impaired people. Describe this image clearly and concisely.

Format:
1. Main scene/subject (1 sentence)
2. Important objects, people, or details (2-4 items)
3. Any visible text (read it out)
4. Colors and spatial relationships if relevant
5. Safety-relevant information (traffic, obstacles, etc.)

Keep it under 100 words, natural and conversational.''',
                  },
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$base64Image',
                    },
                  },
                ],
              },
            ],
            'temperature': 0.5,
            'max_tokens': 450,
            'top_p': 1,
            'stream': false,
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Groq request timed out after 30 seconds');
          },
        );

        stopwatch.stop();
        print('⏱️ Request completed in ${stopwatch.elapsedMilliseconds}ms');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final description = data['choices'][0]['message']['content'].toString().trim();
          
          print('✅ Groq analysis complete!');
          print('📊 Response length: ${description.length} characters');
          print('📝 Preview: ${description.substring(0, description.length > 50 ? 50 : description.length)}...');
          
          return description;
        } else if (response.statusCode == 429) {
          print('⚠️ Groq rate limit hit (429)');
          if (attempt < retries - 1) {
            final waitTime = 2 * (attempt + 1);
            print('⏳ Waiting ${waitTime}s before retry...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
        } else if (response.statusCode == 401) {
          print('❌ Groq Error 401: Invalid API key');
          throw Exception('Invalid API key');
        } else if (response.statusCode == 400) {
          print('❌ Groq Error 400: Bad request');
          print('Response: ${response.body}');
          throw Exception('Bad request to Groq API');
        } else {
          print('❌ Groq Error ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        
        // If we reach here and it's the last attempt, fall back
        if (attempt == retries - 1) {
          print('⚠️ All Groq attempts failed, falling back to ML Kit');
          return await _analyzeWithMLKit(imageFile);
        }
      } catch (e, stackTrace) {
        print('❌ Error with Groq (attempt ${attempt + 1}): $e');
        print('Stack trace: $stackTrace');
        
        if (attempt == retries - 1) {
          print('⚠️ All attempts exhausted, falling back to ML Kit');
          return await _analyzeWithMLKit(imageFile);
        }
        
        final waitTime = 2 * (attempt + 1);
        print('⏳ Waiting ${waitTime}s before retry...');
        await Future.delayed(Duration(seconds: waitTime));
      }
    }
    
    // Final fallback
    return await _analyzeWithMLKit(imageFile);
  }

  Future<String> _analyzeWithMLKit(File imageFile) async {
    try {
      print('📱 Analyzing with ML Kit (offline mode)...');
      
      if (!_mlKitService.isInitialized) {
        print('🔧 Initializing ML Kit...');
        await _mlKitService.initialize();
      }
      
      final description = await _mlKitService.getSceneDescription(imageFile);
      print('✅ ML Kit analysis complete');
      print('📝 Description: $description');
      return description;
    } catch (e, stackTrace) {
      print('❌ Error with ML Kit: $e');
      print('Stack trace: $stackTrace');
      return 'Unable to analyze the image at this moment. Please ensure you have good lighting and try again.';
    }
  }

  // Test API connection
  Future<bool> testGroqConnection() async {
    print('🧪 Testing Groq API connection...');
    
    // ✅ FIXED: Check if key is valid
    if (!_hasValidApiKey) {
      print('❌ Invalid or missing Groq API key');
      print('   Key present: ${_groqApiKey.isNotEmpty}');
      print('   Key format: ${_groqApiKey.startsWith('gsk_')}');
      print('   Key length: ${_groqApiKey.length}');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': 'Test'}
          ],
          'max_tokens': 10,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Groq API connection successful!');
        final data = jsonDecode(response.body);
        print('📝 Test response: ${data['choices'][0]['message']['content']}');
        return true;
      } else {
        print('❌ Groq API connection failed');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Groq connection test exception: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> dispose() async {
    print('🧹 Disposing AIService...');
    await _mlKitService.dispose();
  }
}