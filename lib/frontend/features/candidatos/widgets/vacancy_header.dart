import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../procesos/widgets/stage_stepper.dart';
import '../../tutorial/spotlight.dart';
import '../candidatos_controller.dart';
import 'vacantes_view.dart';

/// Título de la vacante activa y el flujo de 6 etapas. Tocar una etapa
/// completada lleva toda la pantalla a como estaba en esa etapa. Para cambiar
/// de vacante se usa la vista "Vacantes" del menú lateral.
class VacancyHeader extends ConsumerWidget {
  const VacancyHeader({super.key, required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = state.vacante;
    final sla = state.sla;

    // El tutorial resalta la tarjeta completa del flujo.
    return SpotlightTarget(
      id: 'flujo',
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(18, 16, 22, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    v.titulo,
                    style: AppTypography.display.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AlertBadge(alerts: state.alertasDe(v.id), sla: sla),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, box) {
                const minWidth = 720.0;
                final stepper = StageStepper(
                  currentStep: v.etapaActual,
                  highlightedStep: state.etapaVista,
                  onStepTap: (n) => ref.read(candidatosProvider.notifier).verEtapa(n),
                  showCaptions: false,
                );
                return box.maxWidth >= minWidth
                    ? stepper
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(width: minWidth, child: stepper),
                      );
              },
            ),
            // El tiempo transcurrido es del presente: no aparece en la máquina del tiempo.
            if (!state.viendoPasado) ...[
              const SizedBox(height: 14),
              SpotlightTarget(
                id: 'tiempo',
                child: TiempoDelProceso(dias: diasDelProceso(v, sla), estimados: diasEstimadosProceso(v, sla)),
              ),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

/// Cuánto lleva el proceso de la vacante contra los días estimados de las 6
/// etapas: una línea de texto y una barra delgada bajo el flujo.
class TiempoDelProceso extends StatelessWidget {
  const TiempoDelProceso({super.key, required this.dias, required this.estimados});

  final int dias;
  final int estimados;

  @override
  Widget build(BuildContext context) {
    final excedido = dias > estimados;
    final restantes = estimados - dias;
    final color = excedido ? AppColors.danger : AppColors.flowDone;

    return Semantics(
      label: 'El proceso lleva $dias días de $estimados estimados',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$dias ${dias == 1 ? 'día' : 'días'}',
                        style: AppTypography.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const TextSpan(text: ' en proceso'),
                    ],
                  ),
                  style: AppTypography.label.copyWith(color: AppColors.inkSoft),
                ),
                const Spacer(),
                Text(
                  excedido
                      ? '${-restantes} ${-restantes == 1 ? 'día' : 'días'} sobre los $estimados estimados'
                      : restantes == 0
                      ? 'Hoy se cumplen los $estimados días estimados'
                      : 'Faltan $restantes de $estimados días estimados',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12.5,
                    color: excedido ? AppColors.danger : AppColors.inkSoft,
                    fontWeight: excedido ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GradientProgressBar(value: estimados == 0 ? 0 : dias / estimados, height: 4, color: color),
          ],
        ),
      ),
    );
  }
}
