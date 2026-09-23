import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/vacancy.dart';
import 'card_header.dart';

/// Semáforo de SLA por vacante.
class VacanciesCard extends StatelessWidget {
  const VacanciesCard({super.key, required this.vacancies});

  final List<Vacancy> vacancies;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Vacantes', subtitle: 'Semáforo de SLA'),
          for (final v in vacancies)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/procesos'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        color: v.slaStatus.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.titulo, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          GradientProgressBar(value: v.etapaActual / 6, height: 5),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          v.slaStatus.label,
                          style: AppTypography.caption.copyWith(color: v.slaStatus.color, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          v.slaStatus == SlaStatus.cerrada
                              ? 'Nivel ${v.nivel.label.toLowerCase()}'
                              : 'Etapa ${v.etapaActual}/6${v.proyeccionRetraso > 0 ? ' · +${v.proyeccionRetraso} d' : ''}',
                          style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
