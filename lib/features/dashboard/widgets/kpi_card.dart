import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.footnote,
    this.footnoteColor,
    this.trailing,
  });

  final String label;
  final String value;
  final String footnote;
  final Color? footnoteColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.label.copyWith(color: AppColors.inkSoft)),
                const SizedBox(height: 10),
                Text(value, style: AppTypography.metric),
                const SizedBox(height: 8),
                Text(
                  footnote,
                  style: AppTypography.caption.copyWith(
                    color: footnoteColor ?? AppColors.inkSoft,
                    fontWeight: footnoteColor != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
