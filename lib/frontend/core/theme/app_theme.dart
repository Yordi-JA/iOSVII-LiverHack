import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.magenta,
      tertiary: AppColors.orange,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgTop,
      textTheme: AppTypography.textTheme(),
      splashFactory: InkSparkle.splashFactory,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: AppTypography.caption.copyWith(color: Colors.white),
      ),
    );
  }
}
