import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MLKitService {
  static final MLKitService _instance = MLKitService._internal();
  factory MLKitService() => _instance;
  MLKitService._internal();

  ImageLabeler? _imageLabeler;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.5,
        ),
      );

      _isInitialized = true;
      print('✅ ML Kit initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing ML Kit: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> detectObjects(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_imageLabeler == null) {
      print('❌ Image Labeler not initialized');
      return [];
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<ImageLabel> labels = await _imageLabeler!.processImage(inputImage);

      List<Map<String, dynamic>> results = [];
      for (var label in labels) {
        results.add({
          'label': label.label,
          'confidence': label.confidence,
        });
      }

      print('✅ ML Kit detected ${results.length} objects');
      return results;
    } catch (e) {
      print('❌ Error during ML Kit detection: $e');
      return [];
    }
  }

  Future<String> getSceneDescription(File imageFile) async {
    try {
      final labels = await detectObjects(imageFile);

      if (labels.isEmpty) {
        return 'No objects detected in the image. Please try capturing again with better lighting.';
      }

      // Build natural description
      StringBuffer description = StringBuffer('I can see: ');
      
      List<String> detections = [];
      for (var i = 0; i < labels.length && i < 5; i++) {
        final label = labels[i];
        final labelText = label['label'] as String;
        final confidence = ((label['confidence'] as double) * 100).toStringAsFixed(0);
        detections.add('$labelText ($confidence% confident)');
      }

      description.write(detections.join(', '));
      
      if (labels.length > 5) {
        description.write(', and ${labels.length - 5} more items');
      }

      return description.toString();
    } catch (e) {
      print('❌ Error getting scene description: $e');
      return 'Unable to analyze the image. Please try again.';
    }
  }

  Future<void> dispose() async {
    try {
      await _imageLabeler?.close();
      _imageLabeler = null;
      _isInitialized = false;
      print('✅ ML Kit disposed');
    } catch (e) {
      print('❌ Error disposing ML Kit: $e');
    }
  }
}