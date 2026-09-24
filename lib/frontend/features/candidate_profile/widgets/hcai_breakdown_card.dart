import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../comparativa/hcai_scoring.dart';

/// Explica de dónde sale el potencial HCAI del candidato.
class HcaiBreakdownCard extends StatelessWidget {
  const HcaiBreakdownCard({super.key, required this.result});

  final HcaiResult result;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientMask(child: Icon(Icons.auto_awesome, size: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text('Potencial HCAI', style: AppTypography.headline)),
              GradientMask(child: Text('${result.score.round()}', style: AppTypography.metric)),
              Text(' / 100', style: AppTypography.caption),
            ],
          ),
          Text('Por qué la IA sugiere este puntaje', style: AppTypography.caption),
          const SizedBox(height: 14),
          for (final f in HcaiFactor.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: f.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(f.label, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        '${((result.values[f] ?? 0) * 100).round()}% · +${result.contribution(f).toStringAsFixed(1)} pts',
                        style: AppTypography.caption.copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GradientProgressBar(value: result.values[f] ?? 0, height: 6, color: f.color),
                  const SizedBox(height: 2),
                  Text(f.description, style: AppTypography.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
          Text(
            'La IA sugiere; la decisión final es del HM.',
            style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
