import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/progress_bar.dart';
import 'card_header.dart';

/// Frases generadas a partir de los datos del periodo.
class TeamFindingsCard extends StatelessWidget {
  const TeamFindingsCard({super.key, required this.hallazgos});

  final List<String> hallazgos;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Hallazgos para el equipo', subtitle: 'Qué funciona y dónde mejorar'),
          for (final h in hallazgos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    decoration: const BoxDecoration(color: AppColors.flowDone, shape: BoxShape.circle),
                  ),
                  Expanded(child: Text(h, style: AppTypography.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Contrataciones del periodo por fuente.
class HiringSourcesCard extends StatelessWidget {
  const HiringSourcesCard({super.key, required this.fuentes});

  final List<(String, int)> fuentes;

  @override
  Widget build(BuildContext context) {
    final total = fuentes.fold(0, (s, f) => s + f.$2);
    final maximo = fuentes.isEmpty ? 1 : fuentes.first.$2;
    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'Fuentes de contratación', subtitle: '$total contrataciones en el periodo'),
          if (fuentes.isEmpty)
            Text('Sin contrataciones en el periodo.', style: AppTypography.body.copyWith(color: AppColors.inkMuted)),
          for (final (fuente, n) in fuentes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(fuente, style: AppTypography.label)),
                      Text(
                        '$n · ${(n / total * 100).round()} %',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.5,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GradientProgressBar(value: n / maximo, height: 6, color: AppColors.flowDone),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
