import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'face_detector_service.dart';

class FaceDetectorServiceImpl implements FaceDetectorService {
  late FaceDetector _faceDetector;

  @override
  Future<void> initialize() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  @override
  Future<List<dynamic>> processImage(dynamic image, dynamic camera) async {
    try {
      final inputImage = _inputImageFromCameraImage(image as CameraImage, camera as CameraDescription);
      if (inputImage == null) return [];
      
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      debugPrint('DEBUG: ML Kit error: $e');
      return [];
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    // 1. Log periodic frame info (every 100 frames)
    _frameCount++;
    if (_frameCount % 100 == 0) {
      debugPrint('DEBUG: Processing image format: ${image.format.group} | dimensions: ${image.width}x${image.height}');
    }

    // 2. Detection Parameters
    final sensorOrientation = camera.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    // ML Kit Android ONLY accepts NV21 (17) or YV12 (842094169)
    final format = InputImageFormat.nv21;

    // 3. ROBUST BYTE PACKING (YUV_420_888 to NV21)
    // Manually concatenating Y, U, and V without plane padding
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  int _frameCount = 0;

  @override
  void dispose() {
    _faceDetector.close();
  }
}

FaceDetectorService getFaceDetectorImpl() => FaceDetectorServiceImpl();
