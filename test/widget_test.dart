import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/data/seed/seed_data.dart';
import 'package:pulso/features/dashboard/dashboard_metrics.dart';

void main() {
  test('el embudo refleja la distribución de la demo', () {
    final m = DashboardMetrics(vacancies: seedVacancies, candidates: seedCandidates);
    expect(m.funnel[1], 10);
    expect(m.funnel[3], 6);
    expect(m.funnel[5], 3);
    expect(m.funnel[6], 0);
  });

  test('el semáforo de SLA detecta vacantes vencidas y en riesgo', () {
    final byId = {for (final v in seedVacancies) v.id: v.slaStatus.label};
    expect(byId['v1'], 'A tiempo');
    expect(byId['v2'], 'En riesgo');
    expect(byId['v3'], 'SLA vencido');
    expect(byId['v4'], 'Cerrada');
  });
}
