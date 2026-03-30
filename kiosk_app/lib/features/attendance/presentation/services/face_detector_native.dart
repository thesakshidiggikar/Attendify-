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
    final inputImage = _inputImageFromCameraImage(image as CameraImage, camera as CameraDescription);
    if (inputImage == null) return [];
    return await _faceDetector.processImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    
    // For front camera on Android, rotation is usually sensorOrientation.
    // If it behaves incorrectly, you might need to combine it with current device orientation.
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    // The ML Kit Android backend (Java fromByteArray) ONLY accepts NV21 (17) or YV12.
    // If the device's camera stream yields YUV_420_888 (35), ML Kit throws IllegalArgumentException!
    // We forcefully tell ML Kit to interpret the buffer as NV21.
    final format = InputImageFormat.nv21;

    Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      // For multi-plane formats on Android (like YUV_420_888), we need to ensure 
      // bytes array is correctly sized and formatted without overlapping duplication.
      // Often, plane.bytes are just views of the same underlying buffer.
      // We take the first plane's bytes up to the full required length (Y + UV).
      final yPlane = image.planes[0];
      final ySize = yPlane.bytesPerRow * image.height;
      final totalSize = ySize + (ySize ~/ 2); // 1.5x for NV21/YUV
      
      if (yPlane.bytes.length >= totalSize) {
        bytes = Uint8List.view(yPlane.bytes.buffer, yPlane.bytes.offsetInBytes, totalSize);
      } else {
        // Fallback: manually copy Y and V/U interleaving is too slow in Dart,
        // so we pad the buffer if it was short.
        bytes = Uint8List(totalSize);
        int offset = 0;
        for (final plane in image.planes) {
          final len = plane.bytes.length;
          if (offset + len <= totalSize) {
            bytes.setRange(offset, offset + len, plane.bytes);
            offset += len;
          } else {
            bytes.setRange(offset, totalSize, plane.bytes.sublist(0, totalSize - offset));
            break;
          }
        }
      }
    }

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

  @override
  void dispose() {
    _faceDetector.close();
  }
}

FaceDetectorService getFaceDetectorImpl() => FaceDetectorServiceImpl();
