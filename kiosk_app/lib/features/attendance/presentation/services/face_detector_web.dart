import 'face_detector_service.dart';

class FaceDetectorServiceWeb implements FaceDetectorService {
  @override
  Future<void> initialize() async {}

  @override
  Future<List<dynamic>> processImage(dynamic image, dynamic camera) async {
    return [];
  }

  @override
  void dispose() {}
}

FaceDetectorService getFaceDetectorImpl() => FaceDetectorServiceWeb();
