import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                if (subtitle != null) Text(subtitle!, style: AppTypography.caption),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.more_horiz_rounded, color: AppColors.inkSoft),
        ],
      ),
    );
  }
}
