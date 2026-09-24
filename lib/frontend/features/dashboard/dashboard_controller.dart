import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../backend/providers.dart';
import '../../../backend/seed/seed_history.dart';
import 'attraction_metrics.dart';

/// Periodo elegido en el dashboard.
class PeriodoNotifier extends Notifier<Periodo> {
  @override
  Periodo build() => Periodo.anio;

  void select(Periodo periodo) => state = periodo;
}

final periodoProvider = NotifierProvider<PeriodoNotifier, Periodo>(PeriodoNotifier.new);

/// Indicadores del historial para el periodo elegido.
final attractionMetricsProvider = Provider<AsyncValue<AttractionMetrics>>(
  (ref) => ref
      .watch(hiringHistoryProvider)
      .whenData(
        (records) => AttractionMetrics(
          records: records,
          hoy: demoToday,
          metaAnual: metaAnual,
          periodo: ref.watch(periodoProvider),
        ),
      ),
);
