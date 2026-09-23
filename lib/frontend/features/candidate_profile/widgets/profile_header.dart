import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../../backend/models/candidate.dart';
import '../../../../backend/models/pipeline_stage.dart';
import 'contact_card.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final stage = PipelineStage.fromNumber(c.etapaActual);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GradientAvatar(initials: c.initials, size: 104, ringWidth: 4, tintIndex: int.tryParse(c.id) ?? 0, photoUrl: c.fotoUrl),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nombre, style: AppTypography.display.copyWith(fontSize: 34)),
                const SizedBox(height: 4),
                Text('${c.puestoActual} · ${c.empresaActual}', style: AppTypography.body.copyWith(color: AppColors.inkSoft, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(label: c.status.label, color: c.status.color),
                    StatusPill(label: 'Etapa ${c.etapaActual} · ${stage.label}', color: AppColors.purple, icon: stage.icon),
                    StatusPill(label: '${c.diasEnProceso} días en proceso', color: AppColors.inkSoft, icon: Icons.schedule_rounded),
                    StatusPill(label: c.idiomas, color: AppColors.info, icon: Icons.translate_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                ContactQuickBar(contact: c.contacto),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Score(label: 'Match AIRA', value: c.airaScore),
          const SizedBox(width: 20),
          _Score(label: 'AssessFirst', value: c.assessFirst.compatibilidad),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientDonut(value: value / 100, size: 88),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
