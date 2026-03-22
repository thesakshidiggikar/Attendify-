import 'face_detector_service.dart';
import 'face_detector_service_stub.dart'
    if (dart.library.html) 'face_detector_web.dart'
    if (dart.library.io) 'face_detector_native.dart';

FaceDetectorService getFaceDetector() => getFaceDetectorImpl();
