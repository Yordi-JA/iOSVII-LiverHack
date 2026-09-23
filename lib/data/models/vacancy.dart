import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum VacancyLevel {
  bajo('Bajo'),
  medio('Medio'),
  alto('Alto'),
  complejo('Complejo');

  const VacancyLevel(this.label);

  final String label;

  static VacancyLevel fromLabel(String label) =>
      values.firstWhere((l) => l.label.toLowerCase() == label.toLowerCase(), orElse: () => medio);
}

enum SlaStatus {
  aTiempo('A tiempo', AppColors.success),
  enRiesgo('En riesgo', AppColors.warning),
  vencido('SLA vencido', AppColors.danger),
  cerrada('Cerrada', AppColors.inkSoft);

  const SlaStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// Días reales contra días comprometidos (SLA) en una etapa.
class StageTiming {
  const StageTiming({required this.dias, required this.sla});

  /// Días reales transcurridos. Nulo si la etapa aún no inicia.
  final int? dias;
  final int sla;

  factory StageTiming.fromMap(Map<String, dynamic> map) =>
      StageTiming(dias: (map['dias'] as num?)?.toInt(), sla: (map['sla'] as num).toInt());

  Map<String, dynamic> toMap() => {'dias': dias, 'sla': sla};
}

class Vacancy {
  const Vacancy({
    required this.id,
    required this.titulo,
    required this.area,
    required this.nivel,
    required this.etapaActual,
    required this.hiringManager,
    required this.hrbp,
    required this.reclutador,
    required this.bandaMax,
    required this.tiempos,
    this.cerrada = false,
  });

  final String id;
  final String titulo;
  final String area;
  final VacancyLevel nivel;
  final int etapaActual;
  final String hiringManager;
  final String hrbp;
  final String reclutador;
  final int bandaMax;

  /// Tiempos por etapa, en orden de la 1 a la 6.
  final List<StageTiming> tiempos;
  final bool cerrada;

  int get slaTotal => tiempos.fold(0, (sum, t) => sum + t.sla);

  /// Semáforo de SLA: vencido si alguna etapa supera su SLA en más de 30 %,
  /// en riesgo si alguna lo supera.
  SlaStatus get slaStatus {
    if (cerrada) return SlaStatus.cerrada;
    var status = SlaStatus.aTiempo;
    for (final t in tiempos) {
      final dias = t.dias;
      if (dias == null) continue;
      if (dias > t.sla * 1.3) return SlaStatus.vencido;
      if (dias > t.sla) status = SlaStatus.enRiesgo;
    }
    return status;
  }

  /// Días proyectados de retraso contra el SLA total.
  int get proyeccionRetraso {
    var total = 0;
    for (final t in tiempos) {
      total += (t.dias != null && t.dias! > t.sla) ? t.dias! : t.sla;
    }
    return total - slaTotal;
  }

  factory Vacancy.fromMap(String id, Map<String, dynamic> map) => Vacancy(
        id: id,
        titulo: map['titulo'] ?? '',
        area: map['area'] ?? '',
        nivel: VacancyLevel.fromLabel(map['nivel'] ?? ''),
        etapaActual: (map['etapa_actual'] as num?)?.toInt() ?? 1,
        hiringManager: map['hiring_manager'] ?? '',
        hrbp: map['hrbp'] ?? '',
        reclutador: map['reclutador'] ?? '',
        bandaMax: (map['banda_max'] as num?)?.toInt() ?? 0,
        tiempos: ((map['tiempos'] as List?) ?? [])
            .map((t) => StageTiming.fromMap(Map<String, dynamic>.from(t)))
            .toList(),
        cerrada: map['cerrada'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'area': area,
        'nivel': nivel.label,
        'etapa_actual': etapaActual,
        'hiring_manager': hiringManager,
        'hrbp': hrbp,
        'reclutador': reclutador,
        'banda_max': bandaMax,
        'tiempos': tiempos.map((t) => t.toMap()).toList(),
        'cerrada': cerrada,
      };
}
