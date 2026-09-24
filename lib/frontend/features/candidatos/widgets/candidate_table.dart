import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../candidatos_controller.dart';
import 'candidate_detail.dart';
import 'ui_kit.dart';

/// Lista de candidatos: solo la tabla. Las acciones sobre la selección
/// aparecen en una barra arriba de la tabla únicamente cuando hay casillas
/// marcadas; la ficha se despliega en acordeón bajo cada fila.
class CandidateListPanel extends ConsumerWidget {
  const CandidateListPanel({super.key, required this.state, required this.role, this.instantanea});

  final CandidatosState state;
  final UserRole role;

  /// Candidatos de una etapa pasada (vista histórica). Si se indica, la
  /// lista es de solo lectura: sin casillas ni acciones.
  final List<Candidato>? instantanea;

  bool get soloLectura => instantanea != null;

  static const minWidth = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = instantanea ?? state.visibles(role);

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (soloLectura)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.inkMuted),
                  const SizedBox(width: 6),
                  Text('Solo lectura', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else if (state.pick.isNotEmpty)
            _BarraSeleccion(state: state, role: role),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                soloLectura
                    ? 'En esta etapa no había candidatos visibles para tu rol.'
                    : 'Aún no hay candidatos enviados a ti en esta vacante. Cuando Reclutamiento te envíe perfiles, aparecerán aquí.',
                style: AppTypography.body.copyWith(color: AppColors.inkMuted),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth < minWidth ? minWidth : box.maxWidth;
                final table = SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      const _HeaderRow(),
                      for (final (i, c) in list.indexed)
                        _CandidateRow(
                          key: ValueKey(c.id),
                          candidato: c,
                          state: state,
                          role: role,
                          open: state.openId == c.id,
                          picked: state.pick.contains(c.id),
                          soloLectura: soloLectura,
                          ultima: i == list.length - 1,
                        ),
                    ],
                  ),
                );
                return box.maxWidth < minWidth
                    ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table)
                    : table;
              },
            ),
        ],
      ),
    );
  }
}

/// Acciones sobre los candidatos marcados: cuántos hay y qué se puede hacer.
class _BarraSeleccion extends ConsumerWidget {
  const _BarraSeleccion({required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(candidatosProvider.notifier);
    final n = state.pick.length;
    final comparar = veComparativa(role, state.vacante.etapaActual);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '$n seleccionado${n == 1 ? '' : 's'}',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (isAt(role)) ...[
            if (comparar)
              ToneButton(
                label: 'Comparar ($n)',
                icon: Icons.view_column_outlined,
                onTap: n >= 2 ? () => notifier.setView(CandidatosView.comparativa) : null,
              ),
            ToneButton(
              label: 'Mover seleccionados a Entrevista con HM (${state.movibles.length})',
              icon: Icons.send_rounded,
              color: AppColors.flowDone,
              onTap: state.movibles.isEmpty
                  ? null
                  : () => notifier.moverAEntrevistaHm([for (final c in state.movibles) c.id]),
            ),
          ] else if (comparar)
            ToneButton(
              label: 'Comparar seleccionados ($n)',
              icon: Icons.view_column_outlined,
              color: AppColors.flowDone,
              onTap: n >= 2 ? () => notifier.setView(CandidatosView.comparativa) : null,
            ),
        ],
      ),
    );
  }
}

// Anchos de columna (flex) compartidos por el encabezado y las filas.
const _flex = [0, 36, 13, 14, 20, 17];
const _checkWidth = 40.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  static const _labels = ['Candidato', 'Compatibilidad', 'Entrevistas', 'Estatus', 'Espera del HM'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CColors.line))),
      child: Row(
        children: [
          const SizedBox(width: _checkWidth),
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              flex: _flex[i + 1],
              child: Text(
                _labels[i],
                style: AppTypography.caption.copyWith(fontSize: 12, color: AppColors.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateRow extends ConsumerWidget {
  const _CandidateRow({
    super.key,
    required this.candidato,
    required this.state,
    required this.role,
    required this.open,
    required this.picked,
    this.soloLectura = false,
    this.ultima = false,
  });

  final Candidato candidato;
  final CandidatosState state;
  final UserRole role;
  final bool open;
  final bool picked;
  final bool soloLectura;

  /// Última fila: sin línea divisoria abajo.
  final bool ultima;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = candidato;
    final vacante = state.vacante;
    final notifier = ref.read(candidatosProvider.notifier);
    final sla = slaInfo(c, state.sla);

    final row = Row(
      children: [
        SizedBox(
          width: _checkWidth,
          child: Checkbox(
            value: picked,
            onChanged: soloLectura ? null : (_) => notifier.togglePick(c.id),
            activeColor: AppColors.flowDone,
            side: const BorderSide(color: AppColors.inkMuted, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            semanticLabel: 'Comparar a ${c.nombre}',
          ),
        ),
        Expanded(
          flex: _flex[1],
          child: Row(
            children: [
              _Iniciales(nombre: c.nombre),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nombre, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      '${c.puestoActual}, ${c.empresaActual}',
                      style: AppTypography.caption.copyWith(fontSize: 12.5, color: AppColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: _flex[2],
          child: Text(
            '${c.assessFirst.compatibilidad}%',
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Expanded(flex: _flex[3], child: _InterviewDots(entrevistas: c.entrevistas)),
        Expanded(flex: _flex[4], child: _Estatus(candidato: c)),
        Expanded(
          flex: _flex[5],
          child: sla.level == SlaLevel.none
              ? Text('—', style: AppTypography.caption.copyWith(color: AppColors.inkMuted))
              : Text(
                  sla.text,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12.5,
                    color: slaColor(sla.level),
                    fontWeight: sla.level == SlaLevel.red ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: picked
            ? AppColors.flowDone.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: open ? 0.55 : 0),
        borderRadius: BorderRadius.circular(open ? 12 : 0),
        border: ultima || open ? null : const Border(bottom: BorderSide(color: CColors.line)),
      ),
      child: Column(
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => notifier.toggleOpen(c.id),
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
                    notifier.toggleOpen(c.id);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: row),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                    child: Column(
                      children: [
                        const Divider(color: CColors.line, height: 1),
                        const SizedBox(height: 16),
                        CandidateDetail(
                          candidato: c,
                          vacante: vacante,
                          role: role,
                          picked: picked,
                          soloLectura: soloLectura ? state.etapaVista : null,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _InterviewDots extends StatelessWidget {
  const _InterviewDots({required this.entrevistas});

  final List<Entrevista> entrevistas;

  @override
  Widget build(BuildContext context) {
    if (entrevistas.isEmpty) {
      return Text('Sin entrevistas', style: AppTypography.caption.copyWith(color: AppColors.inkMuted));
    }
    return Tooltip(
      message: entrevistas.map((e) => veredictoLabel(e.veredicto, pending: 'Pendiente')).join('\n'),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final e in entrevistas)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: veredictoColor(e.veredicto), shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

/// Estatus del candidato como texto con un punto de color, sin cápsula.
class _Estatus extends StatelessWidget {
  const _Estatus({required this.candidato});

  final Candidato candidato;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (candidato) {
      Candidato(status: StatusProceso.finalista) => ('Finalista', AppColors.success),
      Candidato(status: StatusProceso.oferta) => ('En oferta', AppColors.flowDone),
      Candidato(status: StatusProceso.descartado) => ('Descartado', AppColors.inkMuted),
      Candidato(enviadoHm: true) => ('Con Hiring manager', AppColors.flowCurrent),
      _ => ('Filtro de reclutamiento', AppColors.info),
    };
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 12.5, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

/// Iniciales del candidato en un círculo tenue, sin anillo de degradado.
class _Iniciales extends StatelessWidget {
  const _Iniciales({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.flowDone.withValues(alpha: 0.08), shape: BoxShape.circle),
      child: Text(
        initialsOf(nombre),
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.flowDone),
      ),
    );
  }
}
