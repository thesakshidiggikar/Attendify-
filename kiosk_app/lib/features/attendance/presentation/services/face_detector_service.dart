abstract class FaceDetectorService {
  Future<void> initialize();
  Future<List<dynamic>> processImage(dynamic image, dynamic camera);
  void dispose();
}
