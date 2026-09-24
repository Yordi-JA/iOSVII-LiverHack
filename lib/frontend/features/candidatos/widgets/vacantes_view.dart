import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../candidatos_controller.dart';
import 'ui_kit.dart';

/// Vista "Vacantes" del menú lateral: las vacantes que el rol puede ver,
/// con etapa, candidatos y alertas. Elegir una la vuelve la vacante activa y
/// abre su vista por defecto.
class VacantesView extends ConsumerWidget {
  const VacantesView({super.key, required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacantes = state.vacantesVisibles(role);

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelTitle(
            tituloBarraVacantes(role),
            hint: 'Elige una vacante para ver su flujo y sus candidatos.',
          ),
          const SizedBox(height: 14),
          if (vacantes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Sin vacantes con candidatos para ti.',
                style: AppTypography.body.copyWith(color: AppColors.inkMuted),
              ),
            )
          else
            for (final v in vacantes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: VacancyTile(
                  vacante: v,
                  count: state.candidatosDe(v.id, role).length,
                  alerts: state.alertasDe(v.id),
                  sla: state.sla,
                  active: v.id == state.vacanteId,
                  // selectVacante también regresa a la vista por defecto (lista
                  // o la tarjeta de la etapa, según corresponda).
                  onTap: () => ref.read(candidatosProvider.notifier).selectVacante(v.id),
                ),
              ),
        ],
      ),
    );
  }
}

/// Círculo con el número de alertas: rojo si alguna es roja, ámbar si no.
class AlertBadge extends StatelessWidget {
  const AlertBadge({super.key, required this.alerts, required this.sla});

  final List<Candidato> alerts;
  final SlaConfig sla;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final red = alerts.any((c) => slaInfo(c, sla).level == SlaLevel.red);
    return Tooltip(
      message: '${alerts.length} con 3 días o más sin veredicto',
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: red ? AppColors.danger : AppColors.warning, shape: BoxShape.circle),
        child: Text(
          '${alerts.length}',
          style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
    );
  }
}

/// Vacante en la lista: título, alertas, etapa con número de candidatos y
/// la barra de 6 etapas (morado = completada, magenta = actual).
class VacancyTile extends StatelessWidget {
  const VacancyTile({
    super.key,
    required this.vacante,
    required this.count,
    required this.alerts,
    required this.sla,
    required this.active,
    required this.onTap,
  });

  final Vacante vacante;
  final int count;
  final List<Candidato> alerts;
  final SlaConfig sla;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = vacante;

    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? Colors.white.withValues(alpha: 0.7) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: active ? Colors.white : Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (active)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(color: CColors.sel, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            v.titulo,
                            style: AppTypography.label.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (alerts.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          AlertBadge(alerts: alerts, sla: sla),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.etapaNombre}, $count candidato${count == 1 ? '' : 's'}',
                      style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 1; i <= stages.length; i++)
                          Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i == stages.length ? 0 : 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i < v.etapaActual
                                    ? AppColors.flowDone
                                    : i == v.etapaActual
                                    ? AppColors.flowCurrent
                                    : CColors.line,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
