import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../workspace/workspace_style.dart';
import '../candidatos_controller.dart';
import 'ui_kit.dart';

/// El HM puede elegir para la oferta a un candidato que tiene enviado y
/// sigue activo, mientras la vacante no tenga ya un candidato en oferta.
bool puedeSeleccionarParaOferta(CandidatosState s, Candidato c, UserRole role) =>
    isHm(role) &&
    c.enviadoHm &&
    (c.status == StatusProceso.enProceso || c.status == StatusProceso.finalista) &&
    s.ofertaDe(c.vacanteId) == null;

/// Candidatos activos de la vacante que se descartarían si [c] gana.
int descartablesPara(CandidatosState s, Candidato c) => s.candidatos
    .where(
      (o) =>
          o.vacanteId == c.vacanteId &&
          o.id != c.id &&
          (o.status == StatusProceso.enProceso || o.status == StatusProceso.finalista),
    )
    .length;

/// Recuadro que aparece al marcar finalista: deja claro que el cierre del
/// proceso (pasar a Oferta) es un paso aparte.
class SiguientePasoOferta extends StatelessWidget {
  const SiguientePasoOferta({super.key, required this.candidato, required this.descartables});

  final Candidato candidato;
  final int descartables;

  @override
  Widget build(BuildContext context) {
    return SoftBox(
      padding: const EdgeInsets.all(16),
      color: GColors.surfaceBlue.withValues(alpha: 0.7),
      borderColor: GColors.blue.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: GColors.blue, size: 20),
              const SizedBox(width: 8),
              Text('Siguiente paso: oferta final', style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${candidato.firstName} ya es finalista. Selecciónalo para la oferta: '
            '${descartables == 0 ? 'no hay otros candidatos activos' : 'los otros $descartables candidatos activos se descartan con correo automático'} '
            'y la vacante pasa a la etapa 6 (Oferta) para que el HRBP apruebe el presupuesto.',
            style: AppTypography.body.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          SeleccionarOfertaButton(candidato: candidato, descartables: descartables),
        ],
      ),
    );
  }
}

/// Botón principal (azul) del HM para cerrar la selección.
class SeleccionarOfertaButton extends ConsumerWidget {
  const SeleccionarOfertaButton({super.key, required this.candidato, required this.descartables});

  final Candidato candidato;

  /// Candidatos activos de la vacante que se descartarán al confirmar.
  final int descartables;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () async {
        final justificacion = await showDialog<String>(
          context: context,
          builder: (_) => _SeleccionOfertaDialog(candidato: candidato, descartables: descartables),
        );
        if (justificacion != null) {
          ref.read(candidatosProvider.notifier).seleccionarFinalista(candidato.id, justificacion);
        }
      },
      icon: const Icon(Icons.workspace_premium_outlined),
      label: const Text('Seleccionar para Oferta'),
      style: FilledButton.styleFrom(
        backgroundColor: GColors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: const StadiumBorder(),
        textStyle: gText(size: 15, weight: FontWeight.w500),
      ),
    );
  }
}

class _SeleccionOfertaDialog extends StatefulWidget {
  const _SeleccionOfertaDialog({required this.candidato, required this.descartables});

  final Candidato candidato;
  final int descartables;

  static const minChars = 20;

  @override
  State<_SeleccionOfertaDialog> createState() => _SeleccionOfertaDialogState();
}

class _SeleccionOfertaDialogState extends State<_SeleccionOfertaDialog> {
  final _justificacion = TextEditingController();

  @override
  void dispose() {
    _justificacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.descartables;
    return ValueListenableBuilder(
      valueListenable: _justificacion,
      builder: (context, value, _) {
        final chars = value.text.trim().length;
        final ready = chars >= _SeleccionOfertaDialog.minChars;
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.workspace_premium_outlined, color: GColors.blue),
          title: Text('Seleccionar para oferta', style: gText(size: 24)),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de seleccionar a ${widget.candidato.nombre} para la oferta final? '
                  'Los demás candidatos en este proceso serán descartados automáticamente.',
                  style: gText(color: GColors.textSoft),
                ),
                if (n > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$n candidato${n == 1 ? '' : 's'} recibirá${n == 1 ? '' : 'n'} un correo de agradecimiento.',
                    style: gText(size: 13, color: GColors.textSoft),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _justificacion,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 5,
                  style: gText(),
                  decoration: InputDecoration(
                    labelText: 'Justificación de selección',
                    helperText: '$chars / ${_SeleccionOfertaDialog.minChars} caracteres mínimos (obligatoria)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: GColors.blue, width: 2),
                    ),
                    floatingLabelStyle: gText(color: GColors.blue),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: GColors.blue, textStyle: gText(weight: FontWeight.w500)),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: ready ? () => Navigator.of(context).pop(_justificacion.text.trim()) : null,
              style: FilledButton.styleFrom(
                backgroundColor: GColors.blue,
                shape: const StadiumBorder(),
                textStyle: gText(weight: FontWeight.w500),
              ),
              child: const Text('Confirmar selección'),
            ),
          ],
        );
      },
    );
  }
}

/// Etapa 6: resumen de la oferta. El HRBP aprueba el presupuesto y con eso
/// arrancan los trámites de contratación; los demás roles ven el estado.
class OfertaCard extends ConsumerWidget {
  const OfertaCard({super.key, required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = state.vacante;
    final c = state.ofertaDe(v.id);
    if (c == null) return const SizedBox.shrink();
    final budget = budgetInfo(c, v);
    final aprobada = v.ofertaAprobada;

    Widget fact(String label, Widget child) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      child: SoftBox(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(label), child]),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelTitle(
              'Oferta final',
              hint: aprobada
                  ? 'El HRBP aprobó el paquete. AT confirma la aceptación con el candidato.'
                  : 'El HM eligió al candidato. Falta que el HRBP apruebe el paquete de compensación.',
              trailing: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: StatusPill(
                  label: aprobada ? 'Contratación en trámite' : 'Pendiente de aprobación HRBP',
                  color: aprobada ? AppColors.success : AppColors.warning,
                  icon: aprobada ? Icons.verified_outlined : Icons.hourglass_top_rounded,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CandidatoAvatar(candidato: c, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nombre, style: AppTypography.title.copyWith(fontWeight: FontWeight.w700)),
                      Text('${c.puestoActual}, ${c.empresaActual}', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                fact(
                  'Expectativa del candidato',
                  Text(formatMoneyShort(c.compensacionDeseada), style: AppTypography.metric.copyWith(fontSize: 26)),
                ),
                if (vePresupuesto(role))
                  fact(
                    'Presupuesto de la vacante',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatMoneyShort(v.presupuestoMax), style: AppTypography.metric.copyWith(fontSize: 26)),
                        const SizedBox(height: 6),
                        TonePill(label: budget.text, tone: budget.tone),
                      ],
                    ),
                  ),
                if (c.statusJustificacion.isNotEmpty)
                  fact('Justificación del HM', Text(c.statusJustificacion, style: AppTypography.body)),
              ],
            ),
            const SizedBox(height: 18),
            if (aprobada)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trámites de contratación iniciados.',
                      style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            else if (role == UserRole.hrbp)
              FilledButton.icon(
                onPressed: () => ref.read(candidatosProvider.notifier).aprobarOferta(v.id),
                icon: const Icon(Icons.price_check_rounded),
                label: const Text('Aprobar Presupuesto'),
                style: FilledButton.styleFrom(
                  backgroundColor: GColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: const StadiumBorder(),
                  textStyle: gText(size: 15, weight: FontWeight.w500),
                ),
              )
            else
              Text(
                'Esperando la aprobación de ${v.hrbp} (HRBP).',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
          ],
        ),
      ),
    );
  }
}
