import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../../backend/models/candidate.dart';
import '../../../../backend/models/pipeline_stage.dart';

/// Ventana emergente pequeña con el resumen del postulante.
/// Al tocarla abre el perfil completo.
class CandidatePopover extends StatelessWidget {
  const CandidatePopover({super.key, required this.candidate, required this.onOpenProfile});

  final Candidate candidate;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final lastFeedback = c.feedbackPorEtapa[c.latestFeedbackStage];
    final stage = PipelineStage.fromNumber(c.etapaActual);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: 300,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          opacity: 0.75,
          onTap: onOpenProfile,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GradientAvatar(initials: c.initials, size: 46, tintIndex: int.tryParse(c.id) ?? 0, photoUrl: c.fotoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nombre, style: AppTypography.headline),
                        Text(c.puestoActual, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Metric(label: 'AIRA', value: '${c.airaScore}%'),
                  _Metric(label: 'AssessFirst', value: '${c.assessFirst.compatibilidad}%'),
                  _Metric(label: 'Etapa', value: '${c.etapaActual}/6'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusPill(label: c.status.label, color: c.status.color),
                  StatusPill(label: stage.label, color: AppColors.purple, icon: stage.icon),
                ],
              ),
              if (lastFeedback != null) ...[
                const SizedBox(height: 12),
                Text(
                  '“${lastFeedback.nota}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: AppColors.ink, height: 1.4),
                ),
                const SizedBox(height: 2),
                Text('— ${lastFeedback.autor}', style: AppTypography.caption),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  GradientMask(
                    child: Text('Ver perfil completo', style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  const GradientMask(child: Icon(Icons.arrow_forward_rounded, size: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
          Text(value, style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
