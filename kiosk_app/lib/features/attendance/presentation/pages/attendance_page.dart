import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/constants/app_constants.dart';
import '../widgets/holographic_scanner.dart';
import '../widgets/attendance_success_overlay.dart';
import '../widgets/attendance_failure_overlay.dart';
import '../widgets/attendance_already_marked_overlay.dart';
import '../widgets/attendance_system_paused_overlay.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/face_detector_service.dart';
import '../services/face_detector_bridge.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/datasources/attendance_remote_data_source.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Camera
  CameraController? _controller;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  // Face Detection
  late final FaceDetectorService _faceDetectorService;
  DateTime? _faceDetectedStartTime;
  double _scanProgress = 0.0;
  static const int _scanDurationMs = 2000; // 2 seconds stable face

  // State
  String _machineId = '';
  String _statusMessage = 'INITIALIZING CAMERA...';
  bool _isProcessing = false;
  bool _isCooldown = false;
  DateTime _now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  late String _currentDayStr;
  Timer? _clockTimer;
  Timer? _webScanTimer;

  // Overlays
  bool _showSuccessOverlay = false;
  bool _showFailureOverlay = false;
  bool _showAlreadyMarkedOverlay = false;
  String _successStudentName = '';
  String? _successUserId;
  String _failureMessage = 'Face Not Recognized';

  // Pause / Resume
  bool _isPaused = false;
  bool _isSystemPaused = false;

  // Rate limiting — block after 5 failed attempts per session
  static const int _maxFailedAttempts = 5;
  int _failedAttempts = 0;
  bool _isRateLimited = false;

  // Throttling for Android performance
  DateTime _lastProcessTime = DateTime.now();
  static const int _processIntervalMs = 250; // Max 4 frames per second for detection

  // Recent logs (on this machine today)
  List<Map<String, dynamic>> _recentLogs = [];

  // Admin menu
  bool _showAdminMenu = false;

  @override
  void initState() {
    super.initState();

    // Get machine ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is MachineAuthenticated) {
      _machineId = authState.machineId;
    }

    _faceDetectorService = getFaceDetector();
    _faceDetectorService.initialize();

    _currentDayStr = '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final newNow = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
        final newDayStr = '${newNow.year}-${newNow.month.toString().padLeft(2, '0')}-${newNow.day.toString().padLeft(2, '0')}';
        
        if (newDayStr != _currentDayStr) {
          _currentDayStr = newDayStr;
          _fetchRecentLogs();
        }
        
        setState(() => _now = newNow);
      }
    });

    WidgetsBinding.instance.addObserver(this);

    // Start camera immediately
    _initCamera();
    _fetchRecentLogs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _webScanTimer?.cancel();
    _tryDisposeCamera();
    try {
      _faceDetectorService.dispose();
    } catch (e) {
      debugPrint('ML Kit disposal warning: $e');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (mounted) {
        setState(() {
          _isSystemPaused = true;
          _statusMessage = 'SYSTEM INTERRUPTED';
        });
      }
      _tryDisposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // We explicitly DO NOT auto-restart the camera. We wait for user input.
    }
  }

  void _recoverFromSystemPause() {
    setState(() {
      _isSystemPaused = false;
      _statusMessage = 'RESTARTING CAMERA...';
    });
    _initCamera();
  }

  Future<void> _tryDisposeCamera() async {
    if (_controller != null) {
      final oldController = _controller;
      _controller = null; // Detach immediately 
      try {
        if (oldController!.value.isInitialized) {
          if (oldController.value.isStreamingImages) {
            await oldController.stopImageStream();
          }
        }
        await oldController.dispose();
      } catch (e) {
        debugPrint('Camera disposal error: $e');
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      // 1. Dispose old controller safely
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // 2. Refresh camera list
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _statusMessage = 'NO CAMERA FOUND');
        return;
      }

      // 3. Selection: Always try front camera first, then fall back
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras[0],
      );

      // 4. Create new controller
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      // 5. Initialize with delay to clear hardware locks (especially after hot restart)
      await Future.delayed(const Duration(milliseconds: 400));
      
      try {
        await _controller!.initialize();
      } catch (e) {
        if (e is CameraException && e.code.contains('already_exists')) {
           // Retry once after a second
           await Future.delayed(const Duration(seconds: 1));
           await _controller!.initialize();
        } else {
           rethrow;
        }
      }

      if (mounted && _controller != null) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'READY — SHOW YOUR FACE';
        });

        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
          _startWebFaceDetection();
        } else if (_controller!.value.isInitialized) {
          try {
            await _controller!.startImageStream(_processNativeCameraImage);
          } catch (e) {
            debugPrint('Stream start error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        String msg = 'CAMERA ERROR — RESTART APP';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('cameranotreadable') || errStr.contains('notreadable')) {
          msg = 'CAMERA BLOCKED — CHECK PERMISSIONS';
        } else if (errStr.contains('not found')) {
          msg = 'NO CAMERA FOUND';
        }
        setState(() => _statusMessage = msg);
      }
    }
  }

  bool _isDetecting = false;

  // ─── NATIVE FACE DETECTION (Android/iOS) ─────────────────────────
  Future<void> _processNativeCameraImage(CameraImage image) async {
    if (_isProcessing || _isCooldown || _showSuccessOverlay || _showFailureOverlay || _isDetecting) return;

    // Throttling: Skip if last process was too recent
    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < _processIntervalMs) {
      return;
    }
    _lastProcessTime = now;

    // ---- BRIGHTNESS CHECK ----
    double avgBrightness = 0;
    if (image.format.group == ImageFormatGroup.nv21 && image.planes.isNotEmpty) {
      final bytes = image.planes[0].bytes;
      int sum = 0;
      int step = 20; // Sample every 20th pixel for performance
      for (int i = 0; i < bytes.length; i += step) {
         sum += bytes[i];
      }
      int count = bytes.length ~/ step;
      if (count > 0) avgBrightness = sum / count;
    } else if (image.format.group == ImageFormatGroup.bgra8888 && image.planes.isNotEmpty) {
      final bytes = image.planes[0].bytes;
      int sum = 0;
      int step = 80; // 4 bytes per pixel, sample every 20th pixel
      int count = bytes.length ~/ step;
      for (int i = 0; i + 2 < bytes.length; i += step) {
         sum += (bytes[i] + bytes[i+1] + bytes[i+2]) ~/ 3;
      }
      if (count > 0) avgBrightness = sum / count;
    }
    // -------------------------

    _isDetecting = true;
    try {
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras[0],
      );

      final faces = await _faceDetectorService.processImage(image, frontCamera);

      if (!mounted) return;

      if (_isProcessing) return; // double check

      if (faces.isNotEmpty) {
        debugPrint('DEBUG: Detected ${faces.length} faces (Brightness: ${avgBrightness.toStringAsFixed(1)})');
        if (_faceDetectedStartTime == null) {
          _faceDetectedStartTime = DateTime.now();
          setState(() => _statusMessage = 'FACE DETECTED — HOLD STILL');
        }

        final elapsed = DateTime.now().difference(_faceDetectedStartTime!).inMilliseconds;
        final progress = (elapsed / _scanDurationMs).clamp(0.0, 1.0);

        setState(() => _scanProgress = progress);

        if (progress >= 1.0) {
          // Face stable long enough — capture!
          await _captureAndSubmit();
        }
      } else {
        // No face — reset
        if (_faceDetectedStartTime != null) {
          setState(() {
            _faceDetectedStartTime = null;
            _scanProgress = 0.0;
          });
        }

        // Contextual Environment Hint if no face is detected
        if (avgBrightness > 0) {
          if (avgBrightness < 45) {
            if (mounted && _statusMessage != 'CAMERA NOT VISIBLE - TOO DARK') {
              setState(() => _statusMessage = 'CAMERA NOT VISIBLE - TOO DARK');
            }
          } else if (avgBrightness > 210) {
            if (mounted && _statusMessage != 'FACE NOT CLEARLY VISIBLE - TOO BRIGHT') {
               setState(() => _statusMessage = 'FACE NOT CLEARLY VISIBLE - TOO BRIGHT');
            }
          } else {
            if (mounted && _statusMessage != 'READY — SHOW YOUR FACE') {
               setState(() => _statusMessage = 'READY — SHOW YOUR FACE');
            }
          }
        } else {
           if (mounted && _statusMessage != 'READY — SHOW YOUR FACE') {
              setState(() => _statusMessage = 'READY — SHOW YOUR FACE');
           }
        }
      }
    } catch (e) {
      debugPrint('Face processing error: $e');
    } finally {
      if (mounted) {
        _isDetecting = false;
      }
    }
  }

  // ─── WEB FACE DETECTION (simulated) ──────────────────────────────
  void _startWebFaceDetection() {
    _webScanTimer?.cancel();
    _webScanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _isProcessing || _isCooldown || _isPaused || _isRateLimited ||
          _showSuccessOverlay || _showFailureOverlay || _showAlreadyMarkedOverlay) {
        return;
      }

      // On desktop/web, simulate face detection with a progressive scan
      if (_faceDetectedStartTime == null) {
        _faceDetectedStartTime = DateTime.now();
        setState(() => _statusMessage = 'SCANNING FACE...');
      }

      final elapsed = DateTime.now().difference(_faceDetectedStartTime!).inMilliseconds;
      final progress = (elapsed / _scanDurationMs).clamp(0.0, 1.0);

      setState(() => _scanProgress = progress);

      if (progress >= 1.0) {
        timer.cancel();
        _captureAndSubmit();
      }
    });
  }

  // ─── CAPTURE & SUBMIT TO BACKEND ─────────────────────────────────
  Future<void> _captureAndSubmit() async {
    if (_isProcessing || _isPaused || _isRateLimited) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'VERIFYING IDENTITY...';
    });

    try {
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // ✅ Delete the temp file immediately — we only need the base64 for AWS
      // Images must NOT be stored on device storage
      if (!kIsWeb) {
        try {
          await File(image.path).delete();
        } catch (_) {} // Safe to ignore if already gone
      }

      // Send to backend
      final repo = AttendanceRepositoryImpl(AttendanceRemoteDataSource());
      final result = await repo.markAttendance(base64Image, machineId: _machineId);

      if (mounted) {
        final name = result['name'] ?? 'Unknown';
        final userId = result['user_id'] as String?;
        final message = (result['message'] ?? '').toString().toLowerCase();

        // Detect "already marked" response from Lambda
        final isAlreadyMarked = message.contains('already');

        if (isAlreadyMarked) {
          // Show amber "Already Marked" overlay and add to log in ORANGE
          final nowIST = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
          _recentLogs.insert(0, {
            'name': name,
            'user_id': userId ?? '',
            'timestamp': nowIST.toIso8601String(),
            'is_already_marked': true,
          });
          if (_recentLogs.length > 10) _recentLogs = _recentLogs.sublist(0, 10);

          setState(() {
            _successStudentName = name;
            _successUserId = userId;
            _showAlreadyMarkedOverlay = true;
            _isProcessing = false;
          });
        } else {
          // Reset failed attempts on any real success
          _failedAttempts = 0;
          final nowIST = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

          // Add to local recent logs for fresh mark (GREEN)
          _recentLogs.insert(0, {
            'name': name,
            'user_id': userId ?? '',
            'timestamp': nowIST.toIso8601String(),
            'is_already_marked': false,
          });
          if (_recentLogs.length > 10) _recentLogs = _recentLogs.sublist(0, 10);

          setState(() {
            _successStudentName = name;
            _successUserId = userId;
            _showSuccessOverlay = true;
            _isProcessing = false;
          });
          
          // Re-fetch global log to include manual marks from dashboard
          _fetchRecentLogs();
        }
      }
    } catch (e) {
      debugPrint('Attendance error: $e');
      if (mounted) {
        // Increment failed attempts and check rate limit
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          setState(() {
            _isRateLimited = true;
            _isProcessing = false;
            _statusMessage = 'TOO MANY ATTEMPTS — PAUSED FOR 60s';
          });
          // Auto-reset rate limit after 60 seconds
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted) {
              setState(() {
                _isRateLimited = false;
                _failedAttempts = 0;
                _statusMessage = 'READY — SHOW YOUR FACE';
              });
            }
          });
          return;
        }

        String errorMsg = 'System Error - Try again later';
        final errStr = e.toString().toLowerCase();
        
        if (errStr.contains('exception:')) {
          errorMsg = e.toString().split('exception:').last.trim();
          
          final lowerMsg = errorMsg.toLowerCase();
          // Filter out generic status code errors to be more human-readable
          if (lowerMsg.contains('failed to mark attendance:')) {
            errorMsg = 'System Error - Please contact administrator';
          } else if (lowerMsg.contains('invalidparameterexception') || lowerMsg.contains('no faces')) {
            errorMsg = 'Face Not Clearly Visible';
          } else if (errorMsg.length > 50) {
            errorMsg = 'System Error - Please try again later';
          }
        }
        
        if (errStr.contains('not recognized') || errStr.contains('no match') || errStr.contains('unknown')) {
          errorMsg = 'Face Not Recognized';
        } else if (errStr.contains('network') || errStr.contains('timeout') || errStr.contains('socket')) {
          errorMsg = 'Low Network - Please check connection';
        }

        setState(() {
          _failureMessage = errorMsg;
          _showFailureOverlay = true;
          _isProcessing = false;
        });
      }
    }
  }

  // ─── PAUSE / RESUME ───────────────────────────────────────────────
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _webScanTimer?.cancel();
        _faceDetectedStartTime = null;
        _scanProgress = 0.0;
        _statusMessage = 'PAUSED';
      } else {
        _statusMessage = 'READY — SHOW YOUR FACE';
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux) {
          _startWebFaceDetection();
        }
      }
    });
  }

  void _onOverlayDismissed() {
    setState(() {
      _showSuccessOverlay = false;
      _showFailureOverlay = false;
      _showAlreadyMarkedOverlay = false;
      _faceDetectedStartTime = null;
      _scanProgress = 0.0;
      _isCooldown = true;
      _statusMessage = 'COOLING DOWN...';
    });

    // Cooldown before next scan
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isPaused && !_isRateLimited) {
        setState(() {
          _isCooldown = false;
          _statusMessage = 'READY — SHOW YOUR FACE';
        });

        // Restart image stream or web scanning
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
          _faceDetectedStartTime = null;
          _startWebFaceDetection();
        } else if (_controller != null && _controller!.value.isInitialized) {
          _controller!.startImageStream(_processNativeCameraImage);
        }
      }
    });
  }

  Future<void> _fetchRecentLogs() async {
    try {
      final repo = AttendanceRepositoryImpl(AttendanceRemoteDataSource());
      final data = await repo.getRecentAttendance(machineId: _machineId);
      if (mounted) {
        final todaysLogs = data.where((log) {
          try {
            final logTs = log['timestamp'] as String?;
            if (logTs == null) return false;
            final dt = DateTime.parse(logTs).toUtc().add(const Duration(hours: 5, minutes: 30));
            final logDateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            return logDateStr == _currentDayStr;
          } catch (_) {
            return false;
          }
        }).toList();

        setState(() => _recentLogs = todaysLogs.take(10).toList());
      }
    } catch (e) {
      debugPrint('Failed to fetch logs: $e');
    }
  }

  void _deactivateMachine() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deactivate Machine?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will unregister $_machineId as a kiosk device.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(MachineLogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Deactivate', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                return Column(
                  children: [
                    _buildTopBar(isNarrow, constraints.maxWidth),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isNarrow
                          ? _buildVerticalLayout()
                          : _buildHorizontalLayout(),
                    ),
                  ],
                );
              },
            ),
          ),

          // Success Overlay
          if (_showSuccessOverlay)
            AttendanceSuccessOverlay(
              studentName: _successStudentName,
              userId: _successUserId,
              onDismiss: _onOverlayDismissed,
            ),

          // Already Marked Overlay (amber)
          if (_showAlreadyMarkedOverlay)
            AttendanceAlreadyMarkedOverlay(
              studentName: _successStudentName,
              userId: _successUserId,
              onDismiss: _onOverlayDismissed,
            ),

          // Failure Overlay
          if (_showFailureOverlay)
            AttendanceFailureOverlay(
              message: _failureMessage,
              onDismiss: _onOverlayDismissed,
            ),

          // System Paused Recovery Overlay
          if (_isSystemPaused)
            AttendanceSystemPausedOverlay(
              onResume: _recoverFromSystemPause,
            ),
        ],
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────
  Widget _buildTopBar(bool isNarrow, double width) {
    final isVeryNarrow = width < 500;
    final isExtremelyNarrow = width < 400;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isExtremelyNarrow ? 8 : (isNarrow ? 12 : 24),
        vertical: 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isExtremelyNarrow ? 12 : (isNarrow ? 16 : 24),
        vertical: isExtremelyNarrow ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Machine icon + ID
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.devices_rounded, color: Color(AppConstants.primaryColor), size: 20),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _machineId,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isExtremelyNarrow ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isCooldown
                            ? Colors.orange
                            : const Color(AppConstants.successColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCooldown ? 'Cooldown' : 'Active',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),

          // Clock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isExtremelyNarrow ? 18 : 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: isExtremelyNarrow ? 1 : 2,
                ),
              ),
              if (!isVeryNarrow)
                Text(
                  '${_now.day} ${_getMonth(_now.month)} ${_now.year}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Pause / Resume Button ──
          Tooltip(
            message: _isPaused ? 'Resume Scanning' : 'Pause Scanning',
            child: GestureDetector(
              onTap: _togglePause,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isPaused
                      ? Colors.orange.withOpacity(0.18)
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPaused
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: _isPaused ? Colors.orange : Colors.white.withOpacity(0.55),
                      size: 18,
                    ),
                    if (!isVeryNarrow) ...[
                      const SizedBox(width: 6),
                      Text(
                        _isPaused ? 'RESUME' : 'PAUSE',
                        style: TextStyle(
                          color: _isPaused ? Colors.orange : Colors.white.withOpacity(0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Admin settings button
          IconButton(
            icon: Icon(Icons.settings_rounded, color: Colors.white.withOpacity(0.3), size: 22),
            onPressed: _deactivateMachine,
            tooltip: 'Admin Menu',
          ),
        ],
      ),
    );
  }

  // ─── LAYOUTS ─────────────────────────────────────────────────────
  Widget _buildVerticalLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Expanded(flex: 3, child: _buildCameraView(true)),
          const SizedBox(height: 12),
          Expanded(flex: 2, child: _buildRecentLogs(true)),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildCameraView(false)),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildRecentLogs(false)),
        ],
      ),
    );
  }

  // ─── CAMERA VIEW ─────────────────────────────────────────────────
  Widget _buildCameraView(bool isNarrow) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: _isCameraInitialized && _controller != null && _controller!.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 100,
                        height: 100 / _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(AppConstants.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Holographic scanner overlay
          if (_isCameraInitialized && !_showSuccessOverlay && !_showFailureOverlay)
            Center(
              child: Transform.scale(
                scale: isNarrow ? 0.6 : 0.8,
                child: HolographicScanner(progress: _scanProgress),
              ),
            ),

          // Status bar at bottom
          if (_isCameraInitialized)
            Positioned(
              bottom: isNarrow ? 12 : 20,
              left: isNarrow ? 12 : 20,
              right: isNarrow ? 12 : 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isProcessing
                        ? const Color(AppConstants.primaryColor).withOpacity(0.5)
                        : _isCooldown
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(AppConstants.primaryColor),
                        ),
                      )
                    else
                      Icon(
                        _isCooldown
                            ? Icons.hourglass_top_rounded
                            : Icons.face_retouching_natural_rounded,
                        color: _isCooldown
                            ? Colors.orange
                            : const Color(AppConstants.accentColor),
                        size: 18,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isNarrow ? 13 : 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── RECENT LOGS ─────────────────────────────────────────────────
  Widget _buildRecentLogs(bool isNarrow) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: Color(AppConstants.accentColor), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S LOG',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.accentColor).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_recentLogs.length}',
                  style: const TextStyle(
                    color: Color(AppConstants.accentColor),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _recentLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, color: Colors.white.withOpacity(0.15), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No attendance yet',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _recentLogs.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.06),
                      height: 20,
                    ),
                    itemBuilder: (context, index) {
                      final log = _recentLogs[index];
                      final isAlreadyMarked = log['is_already_marked'] == true;
                      
                      final color = isAlreadyMarked ? Colors.orange : const Color(AppConstants.successColor);
                      final icon = isAlreadyMarked ? Icons.info_outline_rounded : Icons.check_rounded;

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['name'] ?? log['user_id'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTime(log['timestamp'] ?? ''),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _getMonth(int m) {
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
  }

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toUtc().add(const Duration(hours: 5, minutes: 30));
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return '--:--';
    }
  }
}