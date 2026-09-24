import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_pill.dart';
import '../../workspace/workspace_hub.dart';
import '../candidatos_controller.dart';
import 'assessfirst_card.dart';
import 'collaborative_canvas.dart';
import 'cv_viewer.dart';
import 'decision_box.dart';
import 'interview_timeline.dart';
import 'oferta.dart';
import 'ui_kit.dart';

/// Ficha desplegable del candidato: datos a la izquierda y CV a la derecha.
class CandidateDetail extends ConsumerWidget {
  const CandidateDetail({
    super.key,
    required this.candidato,
    required this.vacante,
    required this.role,
    required this.picked,
    this.soloLectura,
  });

  final Candidato candidato;
  final Vacante vacante;
  final UserRole role;
  final bool picked;

  /// Etapa de la instantánea histórica: sin acciones ni comunicación.
  final int? soloLectura;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(candidatosProvider).value;
    final c = candidato;
    final notifier = ref.read(candidatosProvider.notifier);
    final budget = budgetInfo(c, vacante);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
    );

    final compensacion = SoftBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Compensación'),
          if (veCompensacionActual(role))
            Text('Actual ${formatMoneyShort(c.compensacionActual)}', style: AppTypography.caption),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatMoneyShort(c.compensacionDeseada), style: AppTypography.metric.copyWith(fontSize: 26)),
              const SizedBox(width: 6),
              Text('deseada', style: AppTypography.caption),
            ],
          ),
          if (vePresupuesto(role)) ...[const SizedBox(height: 8), TonePill(label: budget.text, tone: budget.tone)],
        ],
      ),
    );

    final formacion = SoftBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Formación e idiomas'),
          Text(c.escolaridad, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
          if (c.otrosEstudios.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(c.otrosEstudios, style: AppTypography.caption.copyWith(color: AppColors.inkSoft, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final i in c.idiomas) MutePill(label: '${i.idioma} ${i.nivel}')],
          ),
        ],
      ),
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Resumen profesional'),
        Text(c.resumenProfesional, style: AppTypography.body.copyWith(fontSize: 15)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 460
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: compensacion),
                      const SizedBox(width: 12),
                      Expanded(child: formacion),
                    ],
                  ),
                )
              : Column(children: [compensacion, const SizedBox(height: 12), formacion]),
        ),
        const SizedBox(height: 14),
        AssessFirstCard(evaluacion: c.assessFirst),
        const SizedBox(height: 18),
        heading('Historial de entrevistas'),
        InterviewTimeline(entrevistas: c.entrevistas),
        // Etapa 5 (Selección): notas en tiempo real entre Reclutamiento y el HM.
        if (vacante.etapaActual == 5 && soloLectura == null) ...[
          const SizedBox(height: 14),
          CollaborativeCanvas(key: ValueKey('lienzo-${c.id}'), candidatoId: c.id),
        ],
        if (c.status != StatusProceso.enProceso && c.statusJustificacion.isNotEmpty) ...[
          const SizedBox(height: 14),
          SoftBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Justificación del estatus'),
                Text(c.statusJustificacion, style: AppTypography.body),
              ],
            ),
          ),
        ],
        if (isAt(role) && soloLectura == null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!c.enviadoHm && c.status == StatusProceso.enProceso)
                ToneButton(
                  label: 'Enviar a ${vacante.hiringManager}',
                  icon: Icons.send_rounded,
                  color: AppColors.flowDone,
                  onTap: () => notifier.enviarAHm(c.id),
                ),
              ToneButton(
                label: picked ? 'Quitar de la comparativa' : 'Agregar a la comparativa',
                icon: picked ? Icons.remove_rounded : Icons.add_rounded,
                onTap: () => notifier.togglePick(c.id),
              ),
            ],
          ),
        ],
        if (puedeDecidir(role) && soloLectura == null) ...[
          const SizedBox(height: 18),
          heading('Decisión del HM'),
          if (estado != null && puedeSeleccionarParaOferta(estado, c, role)) ...[
            if (c.status == StatusProceso.finalista)
              SiguientePasoOferta(candidato: c, descartables: descartablesPara(estado, c))
            else
              SeleccionarOfertaButton(candidato: c, descartables: descartablesPara(estado, c)),
            const SizedBox(height: 14),
          ],
          DecisionBox(key: ValueKey('decision-${c.id}'), candidato: c),
        ],
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Currículum (visor PDF)'),
        CvViewer(candidato: c),
      ],
    );

    // Dos columnas en pantallas de 1100 px o más, si el panel tiene espacio.
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final body = LayoutBuilder(
      builder: (context, box) => wide && box.maxWidth >= 760
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 115, child: left),
                const SizedBox(width: 22),
                Expanded(flex: 100, child: right),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 20), right]),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (soloLectura case final etapa?)
          StatusPill(
            label: 'Solo lectura · instantánea de la Etapa $etapa (${stages[etapa - 1]})',
            color: AppColors.warning,
            icon: Icons.history_rounded,
          )
        else
          WorkspaceActionBar(candidato: c, vacante: vacante, role: role),
        const SizedBox(height: 18),
        body,
      ],
    );
  }
}
