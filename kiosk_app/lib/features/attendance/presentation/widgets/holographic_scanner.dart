import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../shared/constants/app_constants.dart';

class HolographicScanner extends StatefulWidget {
  final double progress;
  final String label;
  const HolographicScanner({super.key, required this.progress, this.label = "SCANNING"});

  @override
  State<HolographicScanner> createState() => _HolographicScannerState();
}

class _HolographicScannerState extends State<HolographicScanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerPainter(
            progress: widget.progress,
            animationValue: _controller.value,
          ),
          child: Container(
            width: 380,
            height: 380,
            alignment: Alignment.center,
            child: widget.progress > 0 
              ? Text(
                  "${(widget.progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Color(AppConstants.accentColor), 
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                )
              : null,
          ),
        );
      },
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final double progress;
  final double animationValue;

  _ScannerPainter({required this.progress, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 1. Draw Corner Brackets (Tech Look)
    final bracketPaint = Paint()
      ..color = const Color(AppConstants.accentColor).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const bracketSize = 40.0;
    // Top-Left
    canvas.drawPath(Path()..moveTo(0, bracketSize)..lineTo(0, 0)..lineTo(bracketSize, 0), bracketPaint);
    // Top-Right
    canvas.drawPath(Path()..moveTo(size.width - bracketSize, 0)..lineTo(size.width, 0)..lineTo(size.width, bracketSize), bracketPaint);
    // Bottom-Left
    canvas.drawPath(Path()..moveTo(0, size.height - bracketSize)..lineTo(0, size.height)..lineTo(bracketSize, size.height), bracketPaint);
    // Bottom-Right
    canvas.drawPath(Path()..moveTo(size.width - bracketSize, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - bracketSize), bracketPaint);

    // 2. Main Scanning Circle (Outer)
    final outerCirclePaint = Paint()
      ..color = const Color(AppConstants.accentColor).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 20, outerCirclePaint);

    // 3. Rotating Tech Rings
    final ringPaint = Paint()
      ..color = const Color(AppConstants.accentColor).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Segmented ring 1
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * math.pi);
    for (var i = 0; i < 4; i++) {
       canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius - 30),
        i * math.pi / 2,
        math.pi / 4,
        false,
        ringPaint,
      );
    }
    canvas.restore();

    // Segmented ring 2 (Reverse)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-animationValue * 4 * math.pi);
    for (var i = 0; i < 8; i++) {
       canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius - 45),
        i * math.pi / 4,
        math.pi / 12,
        false,
        ringPaint..strokeWidth = 1.5,
      );
    }
    canvas.restore();

    // 4. Progress Pulse
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = const Color(AppConstants.accentColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      // Inner glow for progress
      final glowPaint = Paint()
        ..color = const Color(AppConstants.accentColor).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 30),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 30),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }

    // 5. Horizontal Scanning Line
    final scanLineY = center.dy + math.sin(animationValue * 2 * math.pi) * (radius - 50);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(AppConstants.accentColor).withOpacity(0),
          const Color(AppConstants.accentColor).withOpacity(0.5),
          const Color(AppConstants.accentColor).withOpacity(0),
        ],
      ).createShader(Rect.fromLTRB(center.dx - radius, scanLineY - 2, center.dx + radius, scanLineY + 2));
    
    canvas.drawRect(Rect.fromLTRB(center.dx - radius + 40, scanLineY - 1, center.dx + radius - 40, scanLineY + 1), scanLinePaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) => true;
}
