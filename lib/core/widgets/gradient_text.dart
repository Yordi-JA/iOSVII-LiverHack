import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pinta cualquier widget (texto o ícono) con el gradiente de marca.
class GradientMask extends StatelessWidget {
  const GradientMask({super.key, required this.child, this.gradient = AppColors.brandGradient});

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: child,
    );
  }
}
