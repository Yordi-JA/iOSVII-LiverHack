import 'package:flutter/material.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../candidatos_controller.dart';
import 'candidate_table.dart';
import 'stage_gate.dart';
import 'ui_kit.dart';

/// Vista "máquina del tiempo": toda la pantalla se ve como estaba al cerrar
/// la etapa pasada [CandidatosState.etapaVista], sin datos del futuro y en
/// solo lectura.
class TimeMachineView extends StatelessWidget {
  const TimeMachineView({super.key, required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final etapa = state.etapaVista!;
    final v = state.vacanteEnEtapa(etapa);
    final eventos = state.eventosDe(v.id, etapa);
    final cierre = _CierreEtapa(eventos: eventos);

    // Para regresar al presente se toca la etapa actual en el flujo.
    if (!veDetalleEtapa(role, etapa)) return const _TareaCompletada();
    return switch (etapa) {
      1 || 2 || 3 => StageGate.historico(state: state, role: role, etapa: etapa, vacante: v, cierre: cierre),
      _ => _ListaHistorica(state: state, role: role, etapa: etapa, cierre: cierre),
    };
  }
}

/// Etapa pasada que el rol no puede ver a detalle: solo se indica que se
/// completó, sin cifras ni directorio.
class _TareaCompletada extends StatelessWidget {
  const _TareaCompletada();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
              const SizedBox(height: 14),
              Text(
                'Tarea completada',
                style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta etapa fue gestionada y aprobada por el HRBP y el Hiring Manager.',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etapas 4 y 5: la lista como estaba entonces, en solo lectura.
class _ListaHistorica extends StatelessWidget {
  const _ListaHistorica({required this.state, required this.role, required this.etapa, required this.cierre});

  final CandidatosState state;
  final UserRole role;
  final int etapa;
  final Widget cierre;

  @override
  Widget build(BuildContext context) {
    final lista = state.candidatosEnEtapa(etapa, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CandidateListPanel(state: state, role: role, instantanea: lista),
        const SizedBox(height: 16),
        GlassCard(radius: 22, padding: const EdgeInsets.all(20), child: cierre),
      ],
    );
  }
}

/// Pie de la etapa: quién la completó y cuándo, según la bitácora.
class _CierreEtapa extends StatelessWidget {
  const _CierreEtapa({required this.eventos});

  /// Del más reciente al más antiguo.
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    return SoftBox(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.flowDone.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.flowDone, size: 20),
              const SizedBox(width: 8),
              Text('Etapa completada', style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          if (eventos.isEmpty)
            Text(
              'Se completó antes de registrar acciones en Puerta Liverpool.',
              style: AppTypography.body.copyWith(color: AppColors.inkMuted),
            )
          else
            for (final e in eventos.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.texto, style: AppTypography.body),
                    Text('${e.actor} · ${fechaRelativa(e.fecha)}', style: AppTypography.caption),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
