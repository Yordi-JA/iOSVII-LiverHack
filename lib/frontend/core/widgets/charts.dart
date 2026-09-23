import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Dona con gradiente de marca, como el indicador de "Task progress".
class GradientDonut extends StatelessWidget {
  const GradientDonut({super.key, required this.value, this.size = 76});

  /// Valor entre 0 y 1.
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(v),
          child: Center(
            child: Text('${(v * 100).round()}%', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.ink.withValues(alpha: 0.07),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [AppColors.purple, AppColors.magenta, AppColors.orange, AppColors.purple],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.value != value;
}

/// Barras pequeñas con gradiente, para tendencias en tarjetas KPI.
class MiniBars extends StatelessWidget {
  const MiniBars({super.key, required this.values, this.height = 44});

  final List<num> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = values.reduce(math.max).toDouble();
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Container(
              width: 6,
              height: height * (v / max),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.purple, AppColors.magenta],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
