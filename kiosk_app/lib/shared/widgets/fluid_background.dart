import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_constants.dart';

class FluidBackground extends StatefulWidget {
  final Widget child;
  const FluidBackground({super.key, required this.child});

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Color(AppConstants.backgroundColor)),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _FluidPainter(animationValue: _controller.value),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _FluidPainter extends CustomPainter {
  final double animationValue;
  _FluidPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Color(AppConstants.accentColor).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final paint2 = Paint()
      ..color = Color(AppConstants.accentColor).withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    // Orbiting blob 1
    final x1 = size.width / 2 + math.cos(animationValue * 2 * math.pi) * (size.width / 3);
    final y1 = size.height / 2 + math.sin(animationValue * 2 * math.pi) * (size.height / 4);
    canvas.drawCircle(Offset(x1, y1), 200, paint1);

    // Orbiting blob 2
    final x2 = size.width / 2 + math.sin(animationValue * 2 * math.pi * 0.5) * (size.width / 2);
    final y2 = size.height / 2 + math.cos(animationValue * 2 * math.pi * 0.7) * (size.height / 3);
    canvas.drawCircle(Offset(x2, y2), 250, paint2);
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) => true;
}
