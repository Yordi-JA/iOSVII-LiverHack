import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Control segmentado en pastilla de vidrio, estilo iOS.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({super.key, required this.segments, required this.selected, required this.onChanged});

  final List<(T value, String label, IconData icon)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label, icon) in segments)
            GestureDetector(
              onTap: () => onChanged(value),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: value == selected ? AppColors.brandGradientHorizontal : null,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: value == selected
                        ? [BoxShadow(color: AppColors.magenta.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: value == selected ? Colors.white : AppColors.inkSoft),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          color: value == selected ? Colors.white : AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
