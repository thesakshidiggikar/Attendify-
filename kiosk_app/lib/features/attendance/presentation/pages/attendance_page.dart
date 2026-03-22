import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/widgets/professional_card.dart';
import '../widgets/holographic_scanner.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/face_detector_service.dart';
import '../services/face_detector_bridge.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/datasources/attendance_remote_data_source.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _showCapturedImage = false;
  Uint8List? _capturedBytes;
  List<CameraDescription> _cameras = [];
  DateTime _now = DateTime.now();
  Timer? _timer;
  List<Map<String, dynamic>> _recentAttendance = [];
  User? _currentUser;

  bool _isCameraActive = false;
  // Face Detection Service
  late final FaceDetectorService _faceDetectorService;
  bool _isBusy = false;
  DateTime? _faceDetectedStartTime;
  String _feedbackMessage = "POSITION YOUR FACE";
  double _scanProgress = 0.0;
  static const int _scanDurationSeconds = 3;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<AuthBloc>().state is AuthAuthenticated 
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user 
        : null;

    _faceDetectorService = getFaceDetector();
    _faceDetectorService.initialize();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _fetchRecentAttendance();
  }

  @override
  void dispose() {
    _faceDetectorService.dispose();
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startScanner() async {
    setState(() {
      _isCameraActive = true;
      _feedbackMessage = "STARTING CAMERA...";
    });
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final frontCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras[0],
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: (kIsWeb || (defaultTargetPlatform != TargetPlatform.android)) ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
          if (kIsWeb) {
            _startWebScanning();
          } else {
            _controller!.startImageStream(_processCameraImage);
          }
        }
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        setState(() {
          _isCameraActive = false;
          _feedbackMessage = "CAMERA ERROR - TRY AGAIN";
        });
      }
    }
  }

  Future<void> _processCameraImage(dynamic image) async {
    if (kIsWeb) return; 
    // Native logic...
  }

  void _startWebScanning() {
    if (!kIsWeb) return;
    Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || !_isCameraActive) {
        t.cancel();
        return;
      }
      setState(() {
        _scanProgress += 0.05;
        if (_scanProgress >= 1.0) {
          t.cancel();
          _scanProgress = 1.0;
          _captureImage();
        }
      });
    });
  }

  int? get FrontCameraIndex {
     if (_cameras.isEmpty) return null;
     int idx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
     return idx == -1 ? 0 : idx;
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() {
      _isCapturing = true;
      _feedbackMessage = "VERIFYING IDENTITY...";
    });
    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _capturedBytes = bytes;
          _showCapturedImage = true;
        });
      }
      final base64Image = base64Encode(bytes);
      
      final repo = AttendanceRepositoryImpl(AttendanceRemoteDataSource());
      await repo.markAttendance(base64Image);
      
      if (mounted) {
        setState(() => _feedbackMessage = "ACCESS GRANTED");
        _showSuccessDialog();
        await Future.delayed(const Duration(seconds: 3));
        await _fetchRecentAttendance();
      }
    } catch (e) {
      if (mounted) setState(() => _feedbackMessage = "AUTH FAILED - TRY AGAIN");
    } finally {
      if (mounted) {
        setState(() {
          _capturedBytes = null;
          _showCapturedImage = false;
          _isCapturing = false;
          _faceDetectedStartTime = null;
          _scanProgress = 0.0;
          _feedbackMessage = "SCANNING FOR FACE...";
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(AppConstants.successColor), size: 80),
              const SizedBox(height: 24),
              Text(
                'ATTENDANCE MARKED!',
                style: TextStyle(
                  color: const Color(AppConstants.textPrimary),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Identity verified for ${_currentUser?.name ?? "Student"}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(AppConstants.textSecondary)),
              ),
              const SizedBox(height: 24),
              Text(
                '${_now.hour}:${_now.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _fetchRecentAttendance() async {
    if (_currentUser == null) return;
    try {
      final repo = AttendanceRepositoryImpl(AttendanceRemoteDataSource());
      final data = await repo.getRecentAttendance(userId: _currentUser!.id);
      if (mounted) {
        setState(() {
          _recentAttendance = data;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            final padding = isNarrow ? 16.0 : AppConstants.defaultPadding;
            
            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  _buildHeader(isNarrow),
                  const SizedBox(height: 20),
                  _buildStatsRow(isNarrow),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isNarrow 
                      ? _buildVerticalLayout() 
                      : _buildHorizontalLayout(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return ProfessionalCard(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 20 : 32, 
        vertical: isNarrow ? 12 : 20
      ),
      borderRadius: 12,
      child: Row(
        children: [
          CircleAvatar(
            radius: isNarrow ? 20 : 24,
            backgroundColor: Color(AppConstants.primaryColor).withOpacity(0.1),
            child: Text(
              _currentUser?.name[0].toUpperCase() ?? 'S',
              style: const TextStyle(color: Color(AppConstants.primaryColor), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome, ${_currentUser?.name ?? "Student"}',
                  style: TextStyle(
                    color: const Color(AppConstants.textPrimary),
                    fontSize: isNarrow ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Student Dashboard • ${(_currentUser?.role ?? "Student").toUpperCase()}',
                  style: TextStyle(
                    color: const Color(AppConstants.textSecondary),
                    fontSize: isNarrow ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildClockWidget(isNarrow),
        ],
      ),
    );
  }

  Widget _buildClockWidget(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: const Color(AppConstants.textPrimary),
            fontSize: isNarrow ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_now.day} ${_getMonth(_now.month)}',
          style: TextStyle(
            color: const Color(AppConstants.textSecondary),
            fontSize: isNarrow ? 10 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Your Visits',
            value: '${_recentAttendance.length}',
            icon: Icons.history_rounded,
            color: const Color(AppConstants.accentColor),
            isNarrow: isNarrow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildLogoutCard(isNarrow)),
      ],
    );
  }

  Widget _buildLogoutCard(bool isNarrow) {
    return ProfessionalCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: InkWell(
        onTap: () {
          context.read<AuthBloc>().add(AuthLogoutRequested());
          Navigator.pushReplacementNamed(context, '/login');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 12 : 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.logout_rounded, color: Colors.red, size: isNarrow ? 20 : 24),
              ),
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isNarrow,
  }) {
    return ProfessionalCard(
      padding: EdgeInsets.all(isNarrow ? 12 : 20),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isNarrow ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isNarrow ? 20 : 24),
          ),
          SizedBox(width: isNarrow ? 12 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(AppConstants.textSecondary),
                  fontSize: isNarrow ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: const Color(AppConstants.textPrimary),
                  fontSize: isNarrow ? 18 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        Expanded(flex: 3, child: _buildCameraContainer(true)),
        const SizedBox(height: 20),
        Expanded(flex: 2, child: _buildRecentLogs(true)),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildCameraContainer(false)),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: _buildRecentLogs(false)),
      ],
    );
  }

  Widget _buildCameraContainer(bool isNarrow) {
    return ProfessionalCard(
      padding: EdgeInsets.all(isNarrow ? 12 : 24),
      borderRadius: 24,
      child: !_isCameraActive 
        ? _buildCameraPlaceholder(isNarrow)
        : _buildActiveCameraView(isNarrow),
    );
  }

  Widget _buildCameraPlaceholder(bool isNarrow) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_front_rounded, 
          size: isNarrow ? 64 : 100, 
          color: Color(AppConstants.primaryColor).withOpacity(0.2)
        ),
        const SizedBox(height: 24),
        Text(
          'READY FOR ATTENDANCE?',
          style: TextStyle(
            color: const Color(AppConstants.textPrimary),
            fontSize: isNarrow ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ensure your face is well lit',
          style: TextStyle(
            color: const Color(AppConstants.textSecondary),
            fontSize: isNarrow ? 12 : 14,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _startScanner,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('CAPTURE NOW'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 24 : 40, 
              vertical: isNarrow ? 16 : 24
            ),
            textStyle: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCameraView(bool isNarrow) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black,
            child: _isCameraInitialized
                ? (_showCapturedImage && _capturedBytes != null
                    ? Image.memory(_capturedBytes!, fit: BoxFit.cover)
                    : CameraPreview(_controller!))
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        if (!_showCapturedImage) 
          Center(
            child: Transform.scale(
              scale: isNarrow ? 0.7 : 0.9,
              child: HolographicScanner(progress: _scanProgress),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
            onPressed: () {
              setState(() {
                _isCameraActive = false;
                _isCameraInitialized = false;
                _controller?.dispose();
                _controller = null;
              });
            },
          ),
        ),
        Positioned(
          bottom: isNarrow ? 12 : 24,
          left: isNarrow ? 12 : 24,
          right: isNarrow ? 12 : 24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _feedbackMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isNarrow ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (_scanProgress > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: isNarrow ? 150 : 250,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _scanProgress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(AppConstants.primaryColor)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogs(bool isNarrow) {
    return ProfessionalCard(
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR RECENT LOGS',
                style: TextStyle(
                  color: const Color(AppConstants.textPrimary),
                  fontWeight: FontWeight.w900,
                  fontSize: isNarrow ? 12 : 14,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.refresh_rounded, color: Color(AppConstants.primaryColor), size: 20),
                onPressed: _fetchRecentAttendance,
              ),
            ],
          ),
          SizedBox(height: isNarrow ? 12 : 20),
          Expanded(
            child: _recentAttendance.isEmpty 
              ? Center(
                  child: Text(
                    'No attendance records found', 
                    style: TextStyle(color: const Color(AppConstants.textSecondary), fontSize: 13)
                  )
                )
              : ListView.separated(
                  itemCount: _recentAttendance.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final log = _recentAttendance[index];
                    return Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(AppConstants.successColor), size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRESENT', 
                                style: TextStyle(
                                  color: const Color(AppConstants.textPrimary), 
                                  fontWeight: FontWeight.bold,
                                  fontSize: isNarrow ? 13 : 14
                                )
                              ),
                              Text(
                                _formatTime(log['timestamp'] ?? ''),
                                style: TextStyle(color: const Color(AppConstants.textSecondary), fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(log['timestamp'] ?? ''),
                          style: TextStyle(color: const Color(AppConstants.textSecondary), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  String _getMonth(int m) {
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
  }

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '--:--';
    }
  }

  String _formatDate(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day} ${_getMonth(dt.month)}';
    } catch (_) {
      return '';
    }
  }
}