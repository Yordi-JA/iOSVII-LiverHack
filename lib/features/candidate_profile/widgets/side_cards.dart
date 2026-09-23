import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/candidate.dart';

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.headline),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class CompensationCard extends StatelessWidget {
  const CompensationCard({super.key, required this.candidate, required this.bandaMax});

  final Candidate candidate;
  final int bandaMax;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final increase = ((c.compensacionDeseada - c.compensacionActual) / c.compensacionActual * 100).round();
    final inBand = c.compensacionDeseada <= bandaMax;
    return _Section(
      title: 'Compensación',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: InfoTile(label: 'Actual', value: formatMoney(c.compensacionActual))),
              const SizedBox(width: 10),
              Expanded(child: InfoTile(label: 'Deseada', value: formatMoney(c.compensacionDeseada), footnote: '+$increase%')),
            ],
          ),
          const SizedBox(height: 10),
          InfoTile(
            label: 'Banda de la vacante',
            value: 'Hasta ${formatMoney(bandaMax)}',
            footnote: inBand ? 'Dentro de banda' : 'Fuera de banda · revisar con HRBP',
            footnoteColor: inBand ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class AssessFirstCard extends StatelessWidget {
  const AssessFirstCard({super.key, required this.assessFirst});

  final AssessFirst assessFirst;

  @override
  Widget build(BuildContext context) {
    final a = assessFirst;
    List<String> split(String s) =>
        s.replaceAll('.', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return _Section(
      title: 'Evaluación AssessFirst',
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.descripcion, style: AppTypography.body),
          const SizedBox(height: 12),
          Text('Fortalezas', style: AppTypography.caption),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final f in split(a.fortalezas)) StatusPill(label: f, color: AppColors.success)],
          ),
          const SizedBox(height: 10),
          Text('Áreas de oportunidad', style: AppTypography.caption),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final f in split(a.areasOportunidad)) StatusPill(label: f, color: AppColors.warning)],
          ),
          if (a.estiloLiderazgo != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: InfoTile(label: 'Liderazgo', value: a.estiloLiderazgo!)),
                const SizedBox(width: 8),
                Expanded(child: InfoTile(label: 'Visión estratégica', value: a.visionEstrategica ?? '—')),
              ],
            ),
            const SizedBox(height: 8),
            InfoTile(label: 'Toma de decisiones', value: a.tomaDecisiones ?? '—'),
          ],
          const SizedBox(height: 12),
          TileFrame(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(a.recomendaciones, style: AppTypography.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExperienceCard extends StatelessWidget {
  const ExperienceCard({super.key, required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    return _Section(
      title: 'Experiencia',
      icon: Icons.work_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: InfoTile(label: 'Puesto actual', value: c.puestoActual)),
              const SizedBox(width: 10),
              Expanded(child: InfoTile(label: 'Empresa', value: c.empresaActual)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Resumen profesional', style: AppTypography.caption),
          const SizedBox(height: 6),
          Text(c.resumenProfesional, style: AppTypography.body),
        ],
      ),
    );
  }
}

class EducationCard extends StatelessWidget {
  const EducationCard({super.key, required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    return _Section(
      title: 'Formación e idiomas',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          InfoTile(label: 'Escolaridad', value: c.escolaridad),
          const SizedBox(height: 8),
          InfoTile(label: 'Otros estudios', value: c.otrosEstudios),
          const SizedBox(height: 8),
          InfoTile(label: 'Idiomas', value: c.idiomas, footnote: 'Inglés ${c.nivelIngles}'),
        ],
      ),
    );
  }
}
