import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/progress_bar.dart';
import 'card_header.dart';

/// Carga de vacantes por reclutador y compensación contra banda.
class TeamCard extends StatelessWidget {
  const TeamCard({super.key, required this.load, required this.dentroBanda, required this.fueraBanda});

  final Map<String, int> load;
  final int dentroBanda;
  final int fueraBanda;

  static const _capacity = 4;

  @override
  Widget build(BuildContext context) {
    final totalBand = dentroBanda + fueraBanda;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Equipo de reclutamiento', subtitle: 'Vacantes activas por persona'),
          for (final entry in load.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  GradientAvatar(initials: initialsOf(entry.key), size: 34, ringWidth: 1.5, tintIndex: entry.key.length),
                  const SizedBox(width: 10),
                  SizedBox(width: 120, child: Text(entry.key, style: AppTypography.label)),
                  Expanded(
                    child: GradientProgressBar(
                      value: entry.value / _capacity,
                      color: entry.value >= _capacity - 1 ? AppColors.warning : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${entry.value}/$_capacity', style: AppTypography.caption),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text('Compensación deseada vs banda', style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: dentroBanda, child: Container(color: AppColors.success)),
                  Expanded(flex: fueraBanda, child: Container(color: AppColors.danger)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$dentroBanda de $totalBand dentro de banda · $fueraBanda fuera',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
