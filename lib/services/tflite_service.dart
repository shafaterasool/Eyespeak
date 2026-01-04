import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class MLKitService {
  static final MLKitService _instance = MLKitService._internal();
  factory MLKitService() => _instance;
  MLKitService._internal();

  ImageLabeler? _imageLabeler;
  ObjectDetector? _objectDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize Image Labeler (for general object recognition)
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.5, // 50% confidence threshold
        ),
      );

      // Initialize Object Detector (for precise object detection with bounding boxes)
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);

      _isInitialized = true;
      print('ML Kit services initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing ML Kit: $e');
      return false;
    }
  }

  /// Detect objects using Image Labeling (faster, more general)
  Future<List<Map<String, dynamic>>> detectWithImageLabeling(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_imageLabeler == null) {
      print('Image Labeler not initialized');
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
          'index': label.index,
        });
      }

      print('Detected ${results.length} labels');
      return results;
    } catch (e) {
      print('Error during image labeling: $e');
      return [];
    }
  }

  /// Detect objects with Object Detection (more precise, includes location)
  Future<List<Map<String, dynamic>>> detectWithObjectDetection(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_objectDetector == null) {
      print('Object Detector not initialized');
      return [];
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<DetectedObject> objects = await _objectDetector!.processImage(inputImage);

      List<Map<String, dynamic>> results = [];
      for (var object in objects) {
        // Get the most confident label
        String label = 'Unknown';
        double confidence = 0.0;
        
        if (object.labels.isNotEmpty) {
          final bestLabel = object.labels.first;
          label = bestLabel.text;
          confidence = bestLabel.confidence;
        }

        results.add({
          'label': label,
          'confidence': confidence,
          'boundingBox': {
            'left': object.boundingBox.left,
            'top': object.boundingBox.top,
            'right': object.boundingBox.right,
            'bottom': object.boundingBox.bottom,
          },
        });
      }

      print('Detected ${results.length} objects');
      return results;
    } catch (e) {
      print('Error during object detection: $e');
      return [];
    }
  }

  /// Comprehensive detection (uses both methods)
  Future<String> getSceneDescription(File imageFile) async {
    try {
      // Use Image Labeling for general scene understanding
      final labels = await detectWithImageLabeling(imageFile);

      if (labels.isEmpty) {
        return 'No objects detected in the image.';
      }

      // Build natural language description
      StringBuffer description = StringBuffer('I can see: ');
      
      List<String> detections = [];
      for (var i = 0; i < labels.length && i < 5; i++) {
        final label = labels[i];
        final labelText = label['label'] as String;
        final confidence = ((label['confidence'] as double) * 100).toStringAsFixed(0);
        detections.add('$labelText ($confidence% confident)');
      }

      description.write(detections.join(', '));
      
      // Add count information
      if (labels.length > 5) {
        description.write(', and ${labels.length - 5} other objects');
      }

      return description.toString();
    } catch (e) {
      print('Error getting scene description: $e');
      return 'Unable to analyze the image at this moment.';
    }
  }

  Future<void> dispose() async {
    try {
      await _imageLabeler?.close();
      await _objectDetector?.close();
      _imageLabeler = null;
      _objectDetector = null;
      _isInitialized = false;
    } catch (e) {
      print('Error disposing ML Kit services: $e');
    }
  }
}