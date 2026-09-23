import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/candidate.dart';
import '../../../data/models/pipeline_stage.dart';

/// Línea de tiempo con todo el feedback del proceso, etapa por etapa.
class ProcessHistory extends StatelessWidget {
  const ProcessHistory({super.key, required this.candidate, required this.selectedStage, required this.onSelect});

  final Candidate candidate;
  final int selectedStage;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = candidate.feedbackPorEtapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial del proceso', style: AppTypography.headline),
          Text('Trazabilidad de cada etapa', style: AppTypography.caption),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Text('Aún no hay feedback registrado.', style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
          for (var i = 0; i < entries.length; i++)
            _TimelineItem(
              stage: entries[i].key,
              feedback: entries[i].value,
              isLast: i == entries.length - 1,
              selected: entries[i].key == selectedStage,
              onTap: () => onSelect(entries[i].key),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.stage,
    required this.feedback,
    required this.isLast,
    required this.selected,
    required this.onTap,
  });

  final int stage;
  final StageFeedback feedback;
  final bool isLast;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                      border: Border.all(color: Colors.white, width: selected ? 3 : 0),
                      boxShadow: selected
                          ? [BoxShadow(color: AppColors.magenta.withValues(alpha: 0.4), blurRadius: 12)]
                          : null,
                    ),
                    child: Text('$stage', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppColors.magenta.withValues(alpha: 0.25)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: selected ? 0.85 : 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? AppColors.magenta.withValues(alpha: 0.4) : Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${PipelineStage.fromNumber(stage).label} · ${feedback.autor}',
                            style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        StatusPill(label: feedback.veredicto.label, color: feedback.veredicto.color),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${feedback.rol} · ${feedback.fecha}', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    Text(feedback.nota, style: AppTypography.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
