import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../../backend/models/candidate.dart';
import '../../../../backend/models/pipeline_stage.dart';

/// Feedback de una etapa específica del candidato.
class StageFeedbackCard extends StatelessWidget {
  const StageFeedbackCard({super.key, required this.candidate, required this.stage});

  final Candidate candidate;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final feedback = candidate.feedbackPorEtapa[stage];
    final stageInfo = PipelineStage.fromNumber(stage);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey('${candidate.id}-$stage'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Etapa $stage · ${stageInfo.label}', style: AppTypography.caption),
            const SizedBox(height: 10),
            if (feedback == null)
              Text(
                stage > candidate.etapaActual
                    ? 'El candidato aún no llega a esta etapa.'
                    : 'Sin feedback registrado en esta etapa.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              )
            else ...[
              Row(
                children: [
                  GradientAvatar(initials: initialsOf(feedback.autor), size: 34, tintIndex: 2, ringWidth: 1.5),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(feedback.autor, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                        Text('${feedback.rol} · ${feedback.fecha}', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StatusPill(label: feedback.veredicto.label, color: feedback.veredicto.color),
              const SizedBox(height: 10),
              Text('“${feedback.nota}”', style: AppTypography.body),
            ],
          ],
        ),
      ),
    );
  }
}
