import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/charts.dart';
import '../../../backend/models/app_alert.dart';
import '../../../backend/providers.dart';
import 'dashboard_metrics.dart';
import 'widgets/alerts_card.dart';
import 'widgets/funnel_card.dart';
import 'widgets/kpi_card.dart';
import 'widgets/sla_stages_card.dart';
import 'widgets/team_card.dart';
import 'widgets/vacancies_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacancies = ref.watch(vacanciesProvider).value;
    final candidates = ref.watch(allCandidatesProvider).value;
    final alerts = ref.watch(alertsProvider).value ?? const [];

    if (vacancies == null || candidates == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final m = DashboardMetrics(vacancies: vacancies, candidates: candidates);
    final compliance = m.slaCompliance;
    final pendingFeedback = alerts.where((a) => a.tipo == AlertType.feedback).length;
    final band = m.compensationBand;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dashboard de atracción de talento', style: AppTypography.display),
          const SizedBox(height: 4),
          Text('Así va cada vacante contra su acuerdo de servicios.', style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 20),
          _Row(children: [
            KpiCard(
              label: 'Vacantes activas',
              value: '${m.activeVacancies}',
              footnote: '${m.closedVacancies} cerrada este mes',
              trailing: const MiniBars(values: [3, 5, 4, 6, 5, 8, 7, 9]),
            ),
            KpiCard(
              label: 'Tiempo a oferta',
              value: '${m.avgDaysToOffer} días',
              footnote: '−5 días vs mes anterior',
              footnoteColor: AppColors.success,
            ),
            KpiCard(
              label: 'Cumplimiento SLA',
              value: '${(compliance * 100).round()}%',
              footnote: 'Meta 85%',
              footnoteColor: compliance >= 0.85 ? AppColors.success : AppColors.warning,
              trailing: GradientDonut(value: compliance),
            ),
            KpiCard(
              label: 'Candidatos en proceso',
              value: '${candidates.length}',
              footnote: '$pendingFeedback feedback pendiente',
              footnoteColor: pendingFeedback > 0 ? AppColors.danger : null,
            ),
          ]),
          const SizedBox(height: 16),
          _Row(flex: const [3, 2], children: [
            FunnelCard(funnel: m.funnel),
            VacanciesCard(vacancies: vacancies),
          ]),
          const SizedBox(height: 16),
          _Row(flex: const [3, 2], children: [
            SlaStagesCard(timings: m.stageTimings),
            TeamCard(load: m.recruiterLoad, dentroBanda: band.dentro, fueraBanda: band.fuera),
          ]),
          const SizedBox(height: 16),
          AlertsCard(alerts: alerts),
        ],
      ),
    );
  }
}

/// Fila de tarjetas con proporciones configurables.
class _Row extends StatelessWidget {
  const _Row({required this.children, this.flex});

  final List<Widget> children;
  final List<int>? flex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(flex: flex?[i] ?? 1, child: children[i]),
        ],
      ],
    );
  }
}
