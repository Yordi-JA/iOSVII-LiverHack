import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({super.key, required this.value, this.height = 8, this.color});

  /// Valor entre 0 y 1.
  final double value;
  final double height;

  /// Si se indica, usa un color sólido en lugar del gradiente de marca.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: AppColors.ink.withValues(alpha: 0.06)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  gradient: color == null ? AppColors.brandGradientHorizontal : null,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
