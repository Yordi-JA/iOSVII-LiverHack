import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../hcai_scoring.dart';

/// Barra apilada que muestra cuánto aporta cada factor al puntaje.
class HcaiStackedBar extends StatelessWidget {
  const HcaiStackedBar({super.key, required this.result, this.height = 10});

  final HcaiResult result;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Container(color: AppColors.ink.withValues(alpha: 0.06)),
              Row(
                children: [
                  for (final f in HcaiFactor.values)
                    Tooltip(
                      message: '${f.label}: +${result.contribution(f).toStringAsFixed(1)} pts',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: box.maxWidth * result.contribution(f) / 100,
                        color: f.color,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
