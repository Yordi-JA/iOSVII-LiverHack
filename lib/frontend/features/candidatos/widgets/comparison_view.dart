import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/candidatos/models.dart';
import '../../../../backend/candidatos/rules.dart';
import '../../../../backend/models/person.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_segmented.dart';
import '../../../core/widgets/status_pill.dart';
import '../candidatos_controller.dart';
import 'cv_viewer.dart';
import 'decision_box.dart';
import 'ui_kit.dart';

/// Colores de los candidatos en el radar, en orden de selección.
/// Un color por candidato, bien distintos entre sí para leer el radar.
const radarColors = [AppColors.flowDone, AppColors.info, AppColors.orange, AppColors.success];

class ComparisonView extends ConsumerWidget {
  const ComparisonView({super.key, required this.state, required this.role});

  final CandidatosState state;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(candidatosProvider.notifier);
    final picked = state.picked;

    if (picked.length < 2) {
      return GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Text(
                'Selecciona al menos 2 candidatos en la lista para ver la comparativa.',
                style: AppTypography.body.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ToneButton(
                label: 'Ir a la lista de candidatos',
                icon: Icons.arrow_back_rounded,
                color: AppColors.flowDone,
                onTap: () => notifier.setView(CandidatosView.lista),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            'Comparativa lado a lado',
            hint: state.cmpMode == CmpMode.tabla
                ? '${picked.length} candidatos de ${state.vacante.titulo}. Estructura del archivo de comparación; '
                      'el fondo verde marca el mejor valor.'
                : '${picked.length} candidatos de ${state.vacante.titulo} en 6 ejes de 0 a 10.',
            trailing: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GlassSegmented<CmpMode>(
                segments: const [
                  (CmpMode.tabla, 'Tabla', Icons.table_chart_outlined),
                  (CmpMode.radar, 'Radar', Icons.radar_rounded),
                ],
                selected: state.cmpMode,
                onChanged: notifier.setCmpMode,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.cmpMode == CmpMode.tabla)
            _ComparisonTable(candidatos: picked, vacante: state.vacante, sla: state.sla, role: role)
          else
            _ComparisonRadar(candidatos: picked, vacante: state.vacante, role: role),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabla con la estructura del Excel de los organizadores.

class _Aspect {
  const _Aspect(this.label, this.cell, {this.best, this.intrinsic = true});

  final String label;
  final Widget Function(Candidato c) cell;

  /// Candidatos con el mejor valor de la fila (fondo verde).
  final Set<int>? best;

  /// Las filas con CV o con la caja de decisión no igualan alturas.
  final bool intrinsic;
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.candidatos, required this.vacante, required this.sla, required this.role});

  final List<Candidato> candidatos;
  final Vacante vacante;
  final SlaConfig sla;
  final UserRole role;

  static const _groupWidth = 34.0;
  static const _aspectWidth = 190.0;
  static const _minCol = 220.0;

  @override
  Widget build(BuildContext context) {
    final minDeseada = candidatos.map((c) => c.compensacionDeseada).reduce((a, b) => a < b ? a : b);
    final maxFit = candidatos.map((c) => c.assessFirst.compatibilidad).reduce((a, b) => a > b ? a : b);
    Widget text(String s) => Text(s.isEmpty ? 'Sin dato' : s, style: AppTypography.body.copyWith(fontSize: 13.5));
    Widget pills(List<String> items, Color color) => Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [for (final i in items) StatusPill(label: i, color: color)],
    );

    final groups = <(String, List<_Aspect>)>[
      (
        'Perfil',
        [
          _Aspect('Escolaridad', (c) => text(c.escolaridad)),
          _Aspect('Otros estudios', (c) => text(c.otrosEstudios)),
          _Aspect('Idiomas', (c) => text(c.idiomas.map((i) => '${i.idioma}: ${i.nivel}').join('\n'))),
          if (veCompensacionActual(role))
            _Aspect('Compensación actual', (c) => text(formatMoneyShort(c.compensacionActual))),
          _Aspect(
            'Compensación deseada',
            (c) {
              final b = budgetInfo(c, vacante);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMoneyShort(c.compensacionDeseada),
                    style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (vePresupuesto(role)) ...[const SizedBox(height: 5), TonePill(label: b.text, tone: b.tone)],
                ],
              );
            },
            best: {
              for (final c in candidatos)
                if (c.compensacionDeseada == minDeseada) c.id,
            },
          ),
        ],
      ),
      (
        'AssessFirst',
        [
          _Aspect(
            '% de compatibilidad (potencial global)',
            (c) => FitBar(value: c.assessFirst.compatibilidad, width: 80),
            best: {
              for (final c in candidatos)
                if (c.assessFirst.compatibilidad == maxFit) c.id,
            },
          ),
          _Aspect('Descripción del candidato', (c) => text(c.assessFirst.descripcion)),
          _Aspect('Fortalezas', (c) => pills(c.assessFirst.fortalezas, AppColors.success)),
          _Aspect('Áreas de oportunidad', (c) => pills(c.assessFirst.areasOportunidad, AppColors.warning)),
          _Aspect('Estilo de liderazgo', (c) => text(c.assessFirst.estiloLiderazgo)),
          _Aspect(
            'Visión estratégica',
            (c) => Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                text(c.assessFirst.visionEstrategica),
                VisionMeter(vision: c.assessFirst.visionEstrategica),
              ],
            ),
          ),
          _Aspect('Análisis y toma de decisiones', (c) => text(c.assessFirst.tomaDecisiones)),
          _Aspect('Recomendaciones', (c) => text(c.assessFirst.recomendaciones)),
        ],
      ),
      (
        'Proceso',
        [
          _Aspect(
            'Entrevistas',
            (c) => c.entrevistas.isEmpty
                ? text('Sin entrevistas')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in c.entrevistas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusPill(
                                label: veredictoLabel(e.veredicto, pending: 'Pendiente'),
                                color: veredictoColor(e.veredicto)!,
                              ),
                              if (e.entrevistadores.isNotEmpty)
                                Text(e.entrevistadores.first.split(' (').first, style: AppTypography.caption),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          _Aspect(
            'Estatus y SLA',
            (c) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                EstatusPill(candidato: c),
                SlaPill(info: slaInfo(c, sla)),
              ],
            ),
          ),
          _Aspect('Currículum', (c) => CvViewer(candidato: c, height: 440), intrinsic: false),
          if (puedeDecidir(role))
            _Aspect(
              'Decisión final',
              (c) => DecisionBox(key: ValueKey('cmp-decision-${c.id}'), candidato: c),
              intrinsic: false,
            ),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final minWidth = _groupWidth + _aspectWidth + _minCol * candidatos.length;
        final width = box.maxWidth < minWidth ? minWidth : box.maxWidth;
        final table = SizedBox(
          width: width,
          child: Column(children: [_headerRow(), for (final (name, aspects) in groups) _group(name, aspects)]),
        );
        return box.maxWidth < minWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table) : table;
      },
    );
  }

  Widget _headerRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const SizedBox(width: _groupWidth),
          SizedBox(
            width: _aspectWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('Aspecto a evaluar', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          for (final c in candidatos)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    CandidatoAvatar(candidato: c, size: 36),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nombre, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            '${c.puestoActual}, ${c.empresaActual}',
                            style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Grupo con la etiqueta vertical ocupando todas sus filas (rowspan).
  Widget _group(String name, List<_Aspect> aspects) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _groupWidth - 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.purple.withValues(alpha: 0.14), AppColors.magenta.withValues(alpha: 0.12)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    name,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _groupWidth),
            child: Column(children: [for (final a in aspects) _row(a)]),
          ),
        ],
      ),
    );
  }

  Widget _row(_Aspect a) {
    final row = Row(
      crossAxisAlignment: a.intrinsic ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        Container(
          width: _aspectWidth,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: CColors.glass2,
            border: Border(bottom: BorderSide(color: CColors.line)),
          ),
          child: Text(a.label, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
        ),
        for (final c in candidatos)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (a.best?.contains(c.id) ?? false)
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.35),
                border: const Border(
                  bottom: BorderSide(color: CColors.line),
                  left: BorderSide(color: CColors.line),
                ),
              ),
              child: a.cell(c),
            ),
          ),
      ],
    );
    return a.intrinsic ? IntrinsicHeight(child: row) : row;
  }
}

// ---------------------------------------------------------------------------
// Radar con los 6 ejes normalizados de 0 a 10.

class _ComparisonRadar extends StatefulWidget {
  const _ComparisonRadar({required this.candidatos, required this.vacante, required this.role});

  final List<Candidato> candidatos;
  final Vacante vacante;
  final UserRole role;

  @override
  State<_ComparisonRadar> createState() => _ComparisonRadarState();
}

class _ComparisonRadarState extends State<_ComparisonRadar> {
  var _metodo = false;

  @override
  Widget build(BuildContext context) {
    final candidatos = widget.candidatos;
    RadarDataSet frame(double value) => RadarDataSet(
      dataEntries: [for (final _ in radarAxes) RadarEntry(value: value)],
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      entryRadius: 0,
    );

    // El margen deja lugar a las etiquetas de los ejes: fl_chart las dibuja
    // fuera del polígono sin reservarles espacio.
    final chart = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 28),
      child: SizedBox(
        height: 320,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 5,
            ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
            tickBorderData: const BorderSide(color: CColors.line),
            gridBorderData: const BorderSide(color: CColors.line),
            radarBorderData: BorderSide(color: AppColors.ink.withValues(alpha: 0.15)),
            titleTextStyle: AppTypography.caption.copyWith(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
            titlePositionPercentageOffset: 0.22,
            // Las etiquetas de varias palabras van en dos líneas para no encimarse.
            getTitle: (index, _) => RadarChartTitle(text: radarAxes[index].replaceFirst(' ', '\n')),
            radarTouchData: RadarTouchData(enabled: false),
            dataSets: [
              // Fijan la escala de 0 a 10 aunque ningún candidato llegue al máximo.
              frame(10),
              frame(0),
              for (var i = 0; i < candidatos.length; i++)
                RadarDataSet(
                  dataEntries: [for (final v in radarScore(candidatos[i], widget.vacante)) RadarEntry(value: v)],
                  // Relleno tenue para que los polígonos encimados se sigan distinguiendo.
                  fillColor: radarColors[i].withValues(alpha: 0.06),
                  borderColor: radarColors[i],
                  borderWidth: 2,
                  entryRadius: 3,
                ),
            ],
          ),
        ),
      ),
    );

    // La tabla es también la leyenda: cada fila lleva el color del candidato.
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RadarTable(candidatos: candidatos, vacante: widget.vacante, role: widget.role),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _metodo = !_metodo),
          icon: AnimatedRotation(
            turns: _metodo ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right_rounded, size: 18),
          ),
          label: const Text('¿Cómo se calcula cada eje?'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.inkSoft,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: !_metodo
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                  child: Text(
                    'Cada eje va de 0 a 10. Compatibilidad es el % de AssessFirst entre 10; experiencia son los '
                    'años (tope 10); inglés convierte el nivel MCER (C1 = 8); liderazgo y visión traducen el estilo '
                    'y el nivel a puntos; ajuste a presupuesto es 10 si la compensación deseada cabe en la banda y '
                    'baja conforme la excede.',
                    style: AppTypography.caption.copyWith(fontSize: 13, color: AppColors.inkSoft, height: 1.45),
                  ),
                ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 900
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: chart),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: side),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chart, const SizedBox(height: 8), side]),
    );
  }
}

class _RadarTable extends StatelessWidget {
  const _RadarTable({required this.candidatos, required this.vacante, required this.role});

  final List<Candidato> candidatos;
  final Vacante vacante;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final head = AppTypography.caption.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w600);
    final cell = AppTypography.label;
    Widget pad(Widget w) => Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: w);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(0.9),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(0.9),
        4: FlexColumnWidth(1.8),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(horizontalInside: BorderSide(color: CColors.line)),
      children: [
        TableRow(
          children: [
            for (final h in ['Candidato', 'Fit', 'Liderazgo', 'Visión', 'Presupuesto'])
              pad(Text(h, style: head, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        for (var i = 0; i < candidatos.length; i++)
          TableRow(
            children: [
              pad(
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: radarColors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(candidatos[i].nombre, style: cell.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              pad(Text('${candidatos[i].assessFirst.compatibilidad}%', style: cell)),
              pad(Text(candidatos[i].assessFirst.estiloLiderazgo, style: cell)),
              pad(Text(candidatos[i].assessFirst.visionEstrategica, style: cell)),
              pad(
                isHm(role)
                    ? Text(formatMoneyShort(candidatos[i].compensacionDeseada), style: cell)
                    : Text(
                        budgetInfo(candidatos[i], vacante).text,
                        style: cell.copyWith(
                          color: toneColor(budgetInfo(candidatos[i], vacante).tone),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
