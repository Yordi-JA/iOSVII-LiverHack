import '../../../backend/models/candidate.dart';
import '../../../backend/models/pipeline_stage.dart';
import '../../../backend/models/vacancy.dart';

/// Cálculos del dashboard, separados de la UI para poder probarlos.
class DashboardMetrics {
  DashboardMetrics({required this.vacancies, required this.candidates});

  final List<Vacancy> vacancies;
  final List<Candidate> candidates;

  int get activeVacancies => vacancies.where((v) => !v.cerrada).length;
  int get closedVacancies => vacancies.where((v) => v.cerrada).length;

  /// Candidatos que alcanzaron cada etapa (embudo acumulado).
  Map<int, int> get funnel => {
        for (final s in PipelineStage.values)
          s.number: candidates.where((c) => c.etapaActual >= s.number).length,
      };

  /// Porcentaje de etapas terminadas dentro de su SLA.
  double get slaCompliance {
    var total = 0;
    var ok = 0;
    for (final v in vacancies) {
      for (final t in v.tiempos) {
        if (t.dias == null) continue;
        total++;
        if (t.dias! <= t.sla) ok++;
      }
    }
    return total == 0 ? 1 : ok / total;
  }

  /// Días promedio de las vacantes cerradas, de la requisición a la oferta.
  int get avgDaysToOffer {
    final closed = vacancies.where((v) => v.cerrada).toList();
    if (closed.isEmpty) return 0;
    final total = closed.fold<int>(0, (sum, v) => sum + v.tiempos.fold<int>(0, (s, t) => s + (t.dias ?? 0)));
    return (total / closed.length).round();
  }

  /// Promedio de días reales y de SLA por etapa, solo con etapas ya iniciadas.
  List<({PipelineStage stage, double dias, double sla})> get stageTimings {
    return [
      for (final s in PipelineStage.values)
        () {
          final timings = vacancies
              .map((v) => v.tiempos.length >= s.number ? v.tiempos[s.number - 1] : null)
              .whereType<StageTiming>()
              .where((t) => t.dias != null)
              .toList();
          if (timings.isEmpty) return (stage: s, dias: 0.0, sla: 0.0);
          final dias = timings.fold<int>(0, (sum, t) => sum + t.dias!) / timings.length;
          final sla = timings.fold<int>(0, (sum, t) => sum + t.sla) / timings.length;
          return (stage: s, dias: dias, sla: sla);
        }(),
    ];
  }

  /// Vacantes activas por reclutador.
  Map<String, int> get recruiterLoad {
    final load = <String, int>{};
    for (final v in vacancies.where((v) => !v.cerrada)) {
      load[v.reclutador] = (load[v.reclutador] ?? 0) + 1;
    }
    return load;
  }

  /// Candidatos cuya compensación deseada está dentro y fuera de la banda de su vacante.
  ({int dentro, int fuera}) get compensationBand {
    var dentro = 0;
    var fuera = 0;
    for (final c in candidates) {
      final v = vacancies.where((v) => v.id == c.vacanteId).firstOrNull;
      if (v == null) continue;
      c.compensacionDeseada <= v.bandaMax ? dentro++ : fuera++;
    }
    return (dentro: dentro, fuera: fuera);
  }
}
