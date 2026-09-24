import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../../backend/models/pipeline_stage.dart';
import 'card_header.dart';

/// Días reales promedio contra el SLA de cada etapa. La línea vertical es el SLA.
class SlaStagesCard extends StatelessWidget {
  const SlaStagesCard({super.key, required this.timings});

  final List<({PipelineStage stage, double dias, double sla})> timings;

  @override
  Widget build(BuildContext context) {
    final scale = timings.fold<double>(1, (m, t) => [m, t.dias, t.sla].reduce((a, b) => a > b ? a : b)) * 1.15;
    final bottleneck = timings
        .where((t) => t.sla > 0)
        .fold<({PipelineStage stage, double dias, double sla})?>(
          null,
          (worst, t) => worst == null || t.dias / t.sla > worst.dias / worst.sla ? t : worst,
        );

    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Días reales vs SLA por etapa',
            subtitle: bottleneck == null || bottleneck.dias <= bottleneck.sla
                ? 'Todas las etapas dentro de SLA'
                : 'Cuello de botella: ${bottleneck.stage.label}',
          ),
          for (final t in timings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(t.stage.label, style: AppTypography.label.copyWith(color: AppColors.inkSoft)),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final color = t.dias <= t.sla
                            ? AppColors.success
                            : t.dias <= t.sla * 1.3
                            ? AppColors.warning
                            : AppColors.danger;
                        return SizedBox(
                          height: 18,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.ink.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Container(
                                width: box.maxWidth * t.dias / scale,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              if (t.sla > 0)
                                Positioned(
                                  left: box.maxWidth * t.sla / scale - 1,
                                  top: -2,
                                  bottom: -2,
                                  child: Container(width: 2, color: AppColors.ink),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      t.sla == 0 ? '—' : '${t.dias.toStringAsFixed(1)}/${t.sla.round()} d',
                      textAlign: TextAlign.right,
                      style: AppTypography.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
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
