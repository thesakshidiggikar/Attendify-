import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ProfessionalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double elevation;

  const ProfessionalCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.color = Colors.white,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
