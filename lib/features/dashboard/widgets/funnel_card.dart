import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/pipeline_stage.dart';
import 'card_header.dart';

/// Embudo centrado: cada barra es la cantidad de candidatos que llegó a la etapa.
class FunnelCard extends StatelessWidget {
  const FunnelCard({super.key, required this.funnel});

  final Map<int, int> funnel;

  @override
  Widget build(BuildContext context) {
    final max = funnel.values.fold<int>(1, (m, v) => v > m ? v : m);
    final last = funnel[PipelineStage.values.length] ?? 0;
    final first = funnel[1] ?? 0;
    final conversion = first == 0 ? 0 : (funnel[5] ?? 0) / first * 100;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Embudo de candidatos',
            subtitle: 'Conversión a selección ${conversion.round()}% · $last en oferta',
          ),
          for (final s in PipelineStage.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('${s.number}  ${s.label}', style: AppTypography.label.copyWith(color: AppColors.inkSoft)),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final value = funnel[s.number] ?? 0;
                        final width = value == 0 ? 6.0 : box.maxWidth * value / max;
                        return Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: width),
                            duration: Duration(milliseconds: 500 + s.index * 120),
                            curve: Curves.easeOutCubic,
                            builder: (context, w, _) => Container(
                              width: w,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: value == 0 ? null : AppColors.brandGradientHorizontal,
                                color: value == 0 ? AppColors.ink.withValues(alpha: 0.08) : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${funnel[s.number] ?? 0}',
                      textAlign: TextAlign.right,
                      style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
