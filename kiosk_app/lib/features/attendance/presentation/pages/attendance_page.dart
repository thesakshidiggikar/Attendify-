import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/constants/app_constants.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io'; // Added for File
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../attendance/data/repositories/attendance_repository_impl.dart';
import '../../../attendance/data/datasources/attendance_remote_data_source.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _showCapturedImage = false; // New flag
  List<CameraDescription> _cameras = [];
  DateTime _now = DateTime.now();
  Timer? _timer;
  List<Map<String, dynamic>> _recentAttendance = [];
  // Removed: Timer? _attendanceTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _fetchRecentAttendance(); // Only fetch on page load
    // Removed: _attendanceTimer = Timer.periodic(...)
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isCapturing = true;
    });
    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
        _showCapturedImage = true;
      });
      // Read image bytes and convert to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      // Call attendance API
      final repo = AttendanceRepositoryImpl(AttendanceRemoteDataSource());
      await repo.markAttendance(base64Image);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully!')),
        );
        await Future.delayed(const Duration(seconds: 2));
        await _fetchRecentAttendance();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark attendance: $e')),
        );
      }
    } finally {
      // Restart camera after marking attendance or error
      await _controller?.dispose();
      _controller = null;
      setState(() {
        _capturedImage = null;
        _showCapturedImage = false;
        _isCameraInitialized = false;
        _isCapturing = false;
      });
      await _initCamera();
    }
  }

  Future<void> _fetchRecentAttendance() async {
    try {
      final repo = AttendanceRepositoryImpl(AttendanceRemoteDataSource());
      final data = await repo.getRecentAttendance();
      setState(() {
        _recentAttendance = data;
      });
    } catch (e) {
      debugPrint('Failed to fetch recent attendance: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    // Removed: _attendanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Color(AppConstants.primaryColor)),
            const SizedBox(width: 8),
            Text(
              'FaceAttend Kiosk',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Removed logout button and user avatar since authentication is removed
        ],
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera and status area
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Camera preview
                  Expanded(
                    child: _isCameraInitialized
                        ? (_showCapturedImage && _capturedImage != null
                            ? (kIsWeb
                                ? Image.network(
                                    _capturedImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_capturedImage!.path),
                                    fit: BoxFit.cover,
                                  ))
                            : AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: CameraPreview(_controller!),
                              ))
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isCapturing || !_isCameraInitialized ? null : _captureImage,
                    icon: const Icon(Icons.camera_alt),
                    label: _isCapturing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Capture'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            // Right panel: clock, date, recent attendance
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TimeBox(label: 'Hours', value: _now.hour.toString().padLeft(2, '0')),
                            const SizedBox(width: 8),
                            _TimeBox(label: 'Minutes', value: _now.minute.toString().padLeft(2, '0')),
                            const SizedBox(width: 8),
                            _TimeBox(label: 'Seconds', value: _now.second.toString().padLeft(2, '0')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Attendance',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: _fetchRecentAttendance,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Recent attendance list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentAttendance.length,
                      itemBuilder: (context, index) {
                        final entry = _recentAttendance[index];
                        final username = entry['username'] ?? '';
                        final timestamp = entry['timestamp'] ?? '';
                        String timeStr = '';
                        try {
                          final dt = DateTime.parse(timestamp).toLocal();
                          timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
                        } catch (_) {}
                        return _AttendanceRow(name: username, status: timeStr);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  const _TimeBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final String name;
  final String status;
  const _AttendanceRow({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          Text(status, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
} 