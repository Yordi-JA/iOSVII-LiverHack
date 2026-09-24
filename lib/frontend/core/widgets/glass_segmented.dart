import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Control segmentado en pastilla de vidrio. La opción activa va sobre fondo
/// blanco, igual que la opción activa del menú lateral.
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
                    color: value == selected ? Colors.white : Colors.white.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: value == selected
                        ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: value == selected ? AppColors.flowDone : AppColors.inkSoft),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          color: value == selected ? AppColors.ink : AppColors.inkSoft,
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
