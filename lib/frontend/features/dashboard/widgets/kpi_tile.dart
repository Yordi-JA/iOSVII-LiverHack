import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Indicador del dashboard: etiqueta pequeña, cifra grande y una nota
/// opcional debajo. Sin caja propia: los indicadores comparten una sola
/// tarjeta y se separan con líneas verticales.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.note,
    this.noteColor,
    this.footer,
  });

  final String label;
  final String value;

  /// Texto pequeño junto a la cifra ("de 72", "días").
  final String? unit;
  final Color? valueColor;
  final String? note;
  final Color? noteColor;

  /// Elemento extra bajo la cifra (por ejemplo, la barra de avance).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: AppTypography.label.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          style: AppTypography.display.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1,
            color: valueColor ?? AppColors.ink,
          ),
        ),
        if (footer != null) ...[const SizedBox(height: 10), footer!],
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: noteColor ?? AppColors.inkSoft,
              fontWeight: noteColor == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
