import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<bool> initialize(List<CameraDescription> cameras) async {
    if (_isInitialized) return true;

    try {
      _cameras = cameras;
      
      if (_cameras.isEmpty) {
        print('No cameras available');
        return false;
      }

      // Use the rear camera
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      
      print('Camera initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  Future<File?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      print('Camera not initialized');
      return null;
    }

    try {
      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile picture = await _controller!.takePicture();
      final File imageFile = File(picture.path);
      
      // Copy to temp directory
      final File savedImage = await imageFile.copy(imagePath);
      
      // Delete original
      await imageFile.delete();
      
      print('Picture saved at: $imagePath');
      return savedImage;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.setFlashMode(mode);
      } catch (e) {
        print('Error setting flash mode: $e');
      }
    }
  }

  Future<double> getMaxZoomLevel() async {
    if (_controller != null && _isInitialized) {
      try {
        return await _controller!.getMaxZoomLevel();
      } catch (e) {
        print('Error getting max zoom level: $e');
        return 1.0;
      }
    }
    return 1.0;
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.setZoomLevel(zoom);
      } catch (e) {
        print('Error setting zoom level: $e');
      }
    }
  }
}