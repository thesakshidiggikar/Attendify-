import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class NeonGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double blur;

  const NeonGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 32.0,
    this.borderColor,
    this.blur = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (borderColor ?? Colors.white).withOpacity(0.02),
                blurRadius: 20,
                spreadRadius: -10,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
