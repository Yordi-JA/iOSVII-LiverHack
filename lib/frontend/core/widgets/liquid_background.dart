import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo con manchas de color desenfocadas que el vidrio refracta.
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.bgTop, AppColors.bgMiddle, AppColors.bgBottom],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: const Stack(
              children: [
                _Blob(alignment: Alignment(-0.9, -0.8), color: AppColors.purple, size: 420),
                _Blob(alignment: Alignment(0.95, -0.4), color: AppColors.magenta, size: 360),
                _Blob(alignment: Alignment(0.3, 1.1), color: AppColors.orange, size: 400),
              ],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.alignment, required this.color, required this.size});

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}
