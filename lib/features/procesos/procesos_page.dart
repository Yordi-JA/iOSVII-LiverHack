import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/candidate.dart';
import '../../data/models/pipeline_stage.dart';
import '../../data/models/vacancy.dart';
import '../../data/providers.dart';
import 'procesos_controller.dart';
import 'widgets/candidate_track_row.dart';
import 'widgets/stage_stepper.dart';

/// Procesos: flujo de 6 pasos arriba y, abajo, una sola ventana con un
/// carril por postulante alineado a esos pasos.
class ProcesosPage extends ConsumerWidget {
  const ProcesosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(candidatesByVacancyProvider(procesosVacancyId));
    final vacancies = ref.watch(vacanciesProvider).value ?? const [];
    final vacancy = vacancies.where((v) => v.id == procesosVacancyId).firstOrNull;

    return candidatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No se pudieron cargar los candidatos: $e')),
      data: (candidates) => _ProcesosView(candidates: candidates, vacancy: vacancy),
    );
  }
}

/// Padding horizontal compartido por el flujo y los carriles para que
/// los rostros queden exactamente debajo de su círculo.
const _hPad = 28.0;

class _ProcesosView extends ConsumerWidget {
  const _ProcesosView({required this.candidates, required this.vacancy});

  final List<Candidate> candidates;
  final Vacancy? vacancy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedCandidateProvider);
    final filter = ref.watch(stageFilterProvider);
    final selected = candidates.where((c) => c.id == selectedId).firstOrNull;

    final counts = {
      for (final s in PipelineStage.values) s.number: candidates.where((c) => c.etapaActual == s.number).length,
    };
    final visible = candidates.where((c) => filter == null || c.etapaActual == filter).toList()
      ..sort((a, b) {
        final byStage = b.etapaActual.compareTo(a.etapaActual);
        return byStage != 0 ? byStage : b.airaScore.compareTo(a.airaScore);
      });

    final selection = ref.read(selectedCandidateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(vacancy: vacancy, total: candidates.length),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    selected == null ? 'Flujo de la vacante' : 'Proceso de ${selected.nombre}',
                    style: AppTypography.headline,
                  ),
                  const Spacer(),
                  Text(
                    selected == null ? 'Toca un círculo para filtrar' : 'Toca su popup para ver el perfil',
                    style: AppTypography.caption,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StageStepper(
                currentStep: selected?.etapaActual ?? vacancy?.etapaActual ?? 1,
                counts: selected == null ? counts : null,
                highlightedStep: filter,
                onStepTap: (s) => ref.read(stageFilterProvider.notifier).toggle(s),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Postulantes', style: AppTypography.headline),
                    const SizedBox(width: 8),
                    StatusPill(label: '${visible.length}', color: AppColors.purple),
                    if (filter != null) ...[
                      const SizedBox(width: 8),
                      InputChip(
                        label: Text('Etapa $filter · ${PipelineStage.fromNumber(filter).label}', style: AppTypography.caption),
                        onDeleted: () => ref.read(stageFilterProvider.notifier).clear(),
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                        side: const BorderSide(color: Colors.white),
                        shape: const StadiumBorder(),
                      ),
                    ],
                    const Spacer(),
                    const _Legend(),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: visible.isEmpty
                      ? Center(child: Text('Nadie en esta etapa todavía.', style: AppTypography.body))
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.7)),
                          itemBuilder: (context, i) {
                            final c = visible[i];
                            return CandidateTrackRow(
                              key: ValueKey(c.id),
                              candidate: c,
                              selected: c.id == selectedId,
                              onSelect: () => selection.select(c.id),
                              onDismiss: () {
                                if (ref.read(selectedCandidateProvider) == c.id) selection.select(null);
                              },
                              onOpenProfile: () {
                                selection.select(null);
                                context.go('/procesos/candidato/${c.id}');
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    return Row(
      children: [
        dot(AppColors.magenta),
        const SizedBox(width: 4),
        Text('En proceso', style: AppTypography.caption),
        const SizedBox(width: 12),
        dot(AppColors.danger),
        const SizedBox(width: 4),
        Text('Descartado', style: AppTypography.caption),
        const SizedBox(width: 12),
        const Icon(Icons.auto_awesome, size: 12, color: AppColors.magenta),
        const SizedBox(width: 4),
        Text('Puntaje AIRA', style: AppTypography.caption),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vacancy, required this.total});

  final Vacancy? vacancy;
  final int total;

  @override
  Widget build(BuildContext context) {
    final v = vacancy;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v?.titulo ?? 'Procesos', style: AppTypography.display),
              const SizedBox(height: 4),
              if (v != null)
                Text(
                  'Nivel ${v.nivel.label.toLowerCase()} · SLA ${v.slaTotal} días · HM ${v.hiringManager} · HRBP ${v.hrbp}',
                  style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                ),
            ],
          ),
        ),
        if (v != null) ...[
          StatusPill(label: v.slaStatus.label, color: v.slaStatus.color, icon: Icons.timer_outlined),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradientHorizontal,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: AppColors.magenta.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                '$total filtrados por AIRA',
                style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
