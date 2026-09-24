import 'package:flutter/material.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_pill.dart';
import 'ui_kit.dart';

/// Resumen de AssessFirst con los 6 campos obligatorios.
class AssessFirstCard extends StatelessWidget {
  const AssessFirstCard({super.key, required this.evaluacion});

  final EvaluacionAssessFirst evaluacion;

  @override
  Widget build(BuildContext context) {
    final a = evaluacion;
    final fields = <(String, Widget)>[
      ('Fortalezas', _pills(a.fortalezas, AppColors.success)),
      ('Áreas de oportunidad', _pills(a.areasOportunidad, AppColors.warning)),
      ('Estilo de liderazgo', _text(a.estiloLiderazgo)),
      (
        'Visión estratégica',
        Row(
          children: [
            Flexible(child: _text(a.visionEstrategica)),
            const SizedBox(width: 8),
            VisionMeter(vision: a.visionEstrategica),
          ],
        ),
      ),
      ('Toma de decisiones', _text(a.tomaDecisiones)),
      ('Recomendaciones', _text(a.recomendaciones)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple.withValues(alpha: 0.08), AppColors.magenta.withValues(alpha: 0.06)],
        ),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompatRing(value: a.compatibilidad),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen AssessFirst', style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(a.descripcion, style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final colWidth = box.maxWidth >= 420 ? (box.maxWidth - 14) / 2 : box.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final (label, value) in fields)
                    SizedBox(
                      width: colWidth,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(label), value]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _text(String value) => Text(value.isEmpty ? 'Sin dato' : value, style: AppTypography.body);

  static Widget _pills(List<String> items, Color color) => items.isEmpty
      ? _text('')
      : Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final i in items) StatusPill(label: i, color: color)],
        );
}
