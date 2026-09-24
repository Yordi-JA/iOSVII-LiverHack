import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/candidatos/rules.dart';
import '../../../backend/models/app_alert.dart';
import '../../../backend/models/person.dart';
import '../../../backend/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../candidatos/widgets/ui_kit.dart' show CColors;
import '../session/role_provider.dart';
import 'attraction_metrics.dart';
import 'dashboard_controller.dart';
import 'dashboard_metrics.dart';
import 'widgets/attention_card.dart';
import 'widgets/funnel_card.dart';
import 'widgets/kpi_tile.dart';
import 'widgets/monthly_hires_chart.dart';
import 'widgets/my_issues_card.dart';
import 'widgets/recruiter_ranking_card.dart';
import 'widgets/sla_stages_card.dart';
import 'widgets/team_insights.dart';

/// "Mis asuntos": el reclutador ve solo lo suyo; los líderes, todo el área
/// y, al inicio, un aviso si el área va abajo del ritmo de la meta.
List<Asunto> misAsuntos({
  required UserRole role,
  required String nombre,
  required AttractionMetrics m,
  required List<AppAlert> alertas,
}) {
  final propio = isAt(role);
  bool mia(String reclutador) => !propio || reclutador == nombre;
  String quien(String reclutador) => propio ? '' : '$reclutador · ';

  return [
    if (!propio && m.ritmoMeta < 0)
      (
        icon: Icons.trending_down_rounded,
        color: AppColors.danger,
        titulo: 'El área va ${-m.ritmoMeta} vacantes abajo del ritmo de la meta',
        detalle: '${m.cubiertasDelAnio.length} cubiertas de ${m.metaALaFecha} esperadas a la fecha',
      ),
    for (final r in m.tardias.where((r) => mia(r.reclutador)).take(3))
      (
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        titulo: r.puesto,
        detalle: '${quien(r.reclutador)}${m.retraso(r)} días de retraso sobre su SLA',
      ),
    for (final r in m.vencenEstaSemana.where((r) => mia(r.reclutador)))
      (
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
        titulo: r.puesto,
        detalle: switch (r.diasSla - r.diasAbierta(m.hoy)) {
          0 => '${quien(r.reclutador)}Vence hoy',
          1 => '${quien(r.reclutador)}Vence mañana',
          final d => '${quien(r.reclutador)}Vence en $d días',
        },
      ),
    for (final r in m.standby.where((r) => mia(r.reclutador)))
      (
        icon: Icons.pause_circle_outline_rounded,
        color: AppColors.inkSoft,
        titulo: r.puesto,
        detalle: '${quien(r.reclutador)}En stand-by: ${r.motivoStandby ?? 'sin motivo'}',
      ),
    for (final a in alertas.where((a) => a.tipo == AlertType.feedback || a.tipo == AlertType.agenda))
      (
        icon: a.tipo.icon,
        color: a.tipo == AlertType.feedback ? AppColors.warning : AppColors.flowDone,
        titulo: a.mensaje,
        detalle: a.accion,
      ),
  ];
}

/// Dashboard de Atracción de Talento. Va dentro del área principal del
/// módulo (a la derecha del menú lateral), que ya hace el scroll.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final periodo = ref.watch(periodoProvider);
    final metrics = ref.watch(attractionMetricsProvider);
    final alertas = ref.watch(alertsProvider).value ?? const <AppAlert>[];

    return metrics.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          GlassCard(child: Text('No se pudo cargar el historial de vacantes.\n$e', style: AppTypography.body)),
      data: (m) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Atracción de Talento',
                style: AppTypography.display.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              _SelectorPeriodo(periodo: periodo, onChanged: ref.read(periodoProvider.notifier).select),
            ],
          ),
          const SizedBox(height: 16),
          _Indicadores(m: m),
          const SizedBox(height: 16),
          _Fila(
            igualarAlto: true,
            children: [
              MonthlyHiresChart(porMes: m.cubiertasPorMes, metaMensual: m.metaMensual, mesActual: m.hoy.month),
              MyIssuesCard(
                asuntos: misAsuntos(role: role, nombre: displayNameFor(role), m: m, alertas: alertas),
                subtitulo: isAt(role) ? 'Tus pendientes de hoy' : 'Pendientes de todo el equipo',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Fila(
            igualarAlto: true,
            children: [
              RecruiterRankingCard(ranking: m.ranking, periodo: periodo),
              AttentionCard(vacantes: m.requierenAtencion),
            ],
          ),
          const SizedBox(height: 16),
          _MetricasEquipo(m: m),
        ],
      ),
    );
  }
}

/// Periodo como pestañas de texto: la activa sobre fondo blanco, igual que
/// la opción activa del menú lateral.
class _SelectorPeriodo extends StatelessWidget {
  const _SelectorPeriodo({required this.periodo, required this.onChanged});

  final Periodo periodo;
  final ValueChanged<Periodo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in Periodo.values)
            Semantics(
              button: true,
              selected: p == periodo,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: p == periodo ? Colors.white : Colors.white.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.label,
                      style: AppTypography.label.copyWith(
                        fontWeight: p == periodo ? FontWeight.w600 : FontWeight.w500,
                        color: p == periodo ? AppColors.ink : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Los seis indicadores en una sola tarjeta, separados por líneas.
class _Indicadores extends StatelessWidget {
  const _Indicadores({required this.m});

  final AttractionMetrics m;

  @override
  Widget build(BuildContext context) {
    final anual = m.periodo == Periodo.anio;
    final cubiertas = m.cubiertas.length;
    final ritmo = m.ritmoMeta;

    final tiles = <Widget>[
      KpiTile(
        label: 'Cubiertas',
        value: '$cubiertas',
        unit: anual ? 'de ${m.metaAnual}' : null,
        footer: anual
            ? GradientProgressBar(value: cubiertas / m.metaAnual, height: 5, color: AppColors.flowDone)
            : null,
        note: anual
            ? ritmo < 0
                  ? '${-ritmo} abajo del ritmo'
                  : ritmo == 0
                  ? 'Al ritmo de la meta'
                  : '$ritmo arriba del ritmo'
            : 'En ${m.periodo.label}',
        noteColor: anual ? (ritmo < 0 ? AppColors.danger : AppColors.success) : null,
      ),
      KpiTile(label: 'Abiertas', value: '${m.abiertas.length}', note: 'Estado actual'),
      KpiTile(
        label: 'Tardías',
        value: '${m.tardias.length}',
        valueColor: m.tardias.isEmpty ? null : AppColors.danger,
        note: 'Fuera de su SLA',
      ),
      KpiTile(label: 'En stand-by', value: '${m.standby.length}', note: 'Pausadas por el negocio'),
      KpiTile(
        label: 'Time to fill',
        value: '${m.timeToFill}',
        unit: 'días',
        note: 'Aceptación de oferta ${(m.aceptacionOferta * 100).round()} %',
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: KpiTile(label: 'En SLA', value: '${(m.enSla * 100).round()} %', note: 'De las cubiertas'),
          ),
          const SizedBox(width: 12),
          GradientDonut(value: m.enSla, size: 52),
        ],
      ),
    ];

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          // En pantallas angostas los indicadores pasan a dos o tres columnas.
          if (box.maxWidth < 900) {
            final columnas = box.maxWidth < 560 ? 2 : 3;
            final ancho = (box.maxWidth - (columnas - 1) * 24) / columnas;
            return Wrap(
              spacing: 24,
              runSpacing: 20,
              children: [for (final t in tiles) SizedBox(width: ancho, child: t)],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, t) in tiles.indexed) ...[
                  if (i > 0) const VerticalDivider(width: 32, thickness: 1, color: CColors.line),
                  Expanded(flex: i == 0 || i == 5 ? 13 : 10, child: t),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dos tarjetas lado a lado (3:2); en pantallas angostas, una debajo de otra.
/// Con [igualarAlto], ambas tarjetas miden lo mismo (sus hijos no deben usar
/// LayoutBuilder, que no calcula altos intrínsecos).
class _Fila extends StatelessWidget {
  const _Fila({required this.children, this.igualarAlto = false});

  final List<Widget> children;
  final bool igualarAlto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [children[0], const SizedBox(height: 16), children[1]],
          );
        }
        final row = Row(
          crossAxisAlignment: igualarAlto ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: children[0]),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: children[1]),
          ],
        );
        return igualarAlto ? IntrinsicHeight(child: row) : row;
      },
    );
  }
}

/// "Métricas para el equipo": plegada por defecto para no saturar la vista.
class _MetricasEquipo extends ConsumerStatefulWidget {
  const _MetricasEquipo({required this.m});

  final AttractionMetrics m;

  @override
  ConsumerState<_MetricasEquipo> createState() => _MetricasEquipoState();
}

class _MetricasEquipoState extends ConsumerState<_MetricasEquipo> {
  var _abiertas = false;

  @override
  Widget build(BuildContext context) {
    final vacancies = ref.watch(vacanciesProvider).value;
    final candidates = ref.watch(allCandidatesProvider).value;
    final pipeline = vacancies == null || candidates == null
        ? null
        : DashboardMetrics(vacancies: vacancies, candidates: candidates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _abiertas = !_abiertas),
            icon: AnimatedRotation(
              turns: _abiertas ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
            label: const Text('Métricas para el equipo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              textStyle: AppTypography.headline.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_abiertas
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Fila(
                        igualarAlto: true,
                        children: [
                          TeamFindingsCard(hallazgos: widget.m.hallazgos),
                          HiringSourcesCard(fuentes: widget.m.fuentes),
                        ],
                      ),
                      if (pipeline != null) ...[
                        const SizedBox(height: 16),
                        _Fila(
                          children: [
                            SlaStagesCard(timings: pipeline.stageTimings),
                            FunnelCard(funnel: pipeline.funnel),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
