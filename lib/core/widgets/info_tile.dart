import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'gradient_text.dart';
import 'progress_bar.dart';

/// Recuadro de vidrio claro para datos dentro de una tarjeta.
class TileFrame extends StatelessWidget {
  const TileFrame({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: child,
    );
  }
}

/// Porcentaje con barra de progreso (Match AIRA, AssessFirst).
class ScoreTile extends StatelessWidget {
  const ScoreTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TileFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientMask(child: Icon(icon, size: 16)),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text('$value%', style: AppTypography.title.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          GradientProgressBar(value: value / 100, height: 6),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value, this.footnote, this.footnoteColor});

  final String label;
  final String value;
  final String? footnote;
  final Color? footnoteColor;

  @override
  Widget build(BuildContext context) {
    return TileFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
          if (footnote != null) ...[
            const SizedBox(height: 4),
            Text(
              footnote!,
              style: AppTypography.caption.copyWith(
                color: footnoteColor ?? AppColors.inkSoft,
                fontWeight: footnoteColor != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
