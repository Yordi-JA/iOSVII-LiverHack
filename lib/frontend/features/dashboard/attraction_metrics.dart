import '../../../backend/models/hiring_record.dart';

/// Periodo del dashboard.
enum Periodo {
  anio('Este año'),
  dias90('90 días'),
  dias30('30 días');

  const Periodo(this.label);

  final String label;
}

/// Desempeño de un reclutador en el periodo.
typedef DesempenoReclutador = ({
  String nombre,
  int cubiertas,
  int diasPromedio,
  double enSla,
  double aceptacion,
  double satisfaccionHm,
  int puntaje,
});

/// Vacante que requiere intervención: tardía (con días de retraso) o en stand-by.
typedef VacanteEnAtencion = ({HiringRecord vacante, int? retraso});

/// Indicadores del Dashboard de Atracción de Talento. Sin dependencias de UI
/// para poder probarlos y reutilizarlos.
class AttractionMetrics {
  AttractionMetrics({required this.records, required this.hoy, required this.metaAnual, this.periodo = Periodo.anio});

  final List<HiringRecord> records;
  final DateTime hoy;
  final int metaAnual;
  final Periodo periodo;

  DateTime get desde => switch (periodo) {
    Periodo.anio => DateTime(hoy.year, 1, 1),
    Periodo.dias90 => hoy.subtract(const Duration(days: 90)),
    Periodo.dias30 => hoy.subtract(const Duration(days: 30)),
  };

  bool _enRango(DateTime d, DateTime desde) => !d.isBefore(desde) && !d.isAfter(hoy);

  List<HiringRecord> _cubiertasDesde(DateTime desde) => records
      .where((r) => r.estado == EstadoVacante.cubierta && r.cierre != null && _enRango(r.cierre!, desde))
      .toList();

  // --- Estado actual (no depende del periodo) ---------------------------

  List<HiringRecord> get abiertas => records.where((r) => r.estado == EstadoVacante.abierta).toList();

  /// Abiertas que ya superaron su SLA, de la más atrasada a la menos.
  List<HiringRecord> get tardias =>
      abiertas.where((r) => r.diasAbierta(hoy) > r.diasSla).toList()..sort((a, b) => retraso(b).compareTo(retraso(a)));

  List<HiringRecord> get standby => records.where((r) => r.estado == EstadoVacante.standby).toList();

  /// Días que una abierta lleva por encima de su SLA.
  int retraso(HiringRecord r) => r.diasAbierta(hoy) - r.diasSla;

  /// Abiertas a tiempo que vencen en los próximos 7 días.
  List<HiringRecord> get vencenEstaSemana => abiertas.where((r) {
    final restantes = r.diasSla - r.diasAbierta(hoy);
    return restantes >= 0 && restantes <= 7;
  }).toList()..sort((a, b) => (a.diasSla - a.diasAbierta(hoy)).compareTo(b.diasSla - b.diasAbierta(hoy)));

  // --- Meta anual -------------------------------------------------------

  List<HiringRecord> get cubiertasDelAnio => _cubiertasDesde(DateTime(hoy.year, 1, 1));

  /// Meta proporcional a los días transcurridos del año.
  int get metaALaFecha {
    final diaDelAnio = hoy.difference(DateTime(hoy.year, 1, 1)).inDays + 1;
    final diasDelAnio = DateTime(hoy.year + 1, 1, 1).difference(DateTime(hoy.year, 1, 1)).inDays;
    return (metaAnual * diaDelAnio / diasDelAnio).floor();
  }

  /// Cubiertas del año menos la meta a la fecha (negativo = abajo del ritmo).
  int get ritmoMeta => cubiertasDelAnio.length - metaALaFecha;

  double get metaMensual => metaAnual / 12;

  /// Cubiertas por mes del año en curso (índice 0 = enero).
  List<int> get cubiertasPorMes {
    final porMes = List.filled(12, 0);
    for (final r in cubiertasDelAnio) {
      porMes[r.cierre!.month - 1]++;
    }
    return porMes;
  }

  // --- Indicadores del periodo -----------------------------------------

  List<HiringRecord> get cubiertas => _cubiertasDesde(desde);

  /// Promedio de días entre apertura y cierre.
  int get timeToFill => _diasPromedio(cubiertas);

  /// Proporción de cubiertas cerradas dentro de su SLA (0 a 1).
  double get enSla => _enSla(cubiertas);

  /// Proporción de cubiertas cuyo candidato aceptó la primera oferta.
  double get aceptacionOferta => _aceptacion(cubiertas);

  /// Contrataciones por fuente, de la que más aporta a la que menos.
  List<(String, int)> get fuentes {
    final conteo = <String, int>{};
    for (final r in cubiertas) {
      final f = r.fuente;
      if (f != null) conteo[f] = (conteo[f] ?? 0) + 1;
    }
    return conteo.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
  }

  /// Ranking del periodo, de mayor a menor puntaje. El puntaje (0 a 100) es:
  /// 40 % SLA + 25 % aceptación + 20 % satisfacción del HM (÷ 5) +
  /// 15 % cubiertas (÷ máximo del equipo).
  List<DesempenoReclutador> get ranking {
    final nombres = {for (final r in records) r.reclutador};
    final porReclutador = {for (final n in nombres) n: cubiertas.where((r) => r.reclutador == n).toList()};
    final maxCubiertas = porReclutador.values.fold(0, (m, l) => l.length > m ? l.length : m);
    final ranking = [
      for (final MapEntry(key: nombre, value: suyas) in porReclutador.entries)
        () {
          final sla = _enSla(suyas);
          final aceptacion = _aceptacion(suyas);
          final satisfaccion = suyas.isEmpty
              ? 0.0
              : suyas.fold(0.0, (s, r) => s + (r.satisfaccionHm ?? 0)) / suyas.length;
          final volumen = maxCubiertas == 0 ? 0.0 : suyas.length / maxCubiertas;
          return (
            nombre: nombre,
            cubiertas: suyas.length,
            diasPromedio: _diasPromedio(suyas),
            enSla: sla,
            aceptacion: aceptacion,
            satisfaccionHm: satisfaccion,
            puntaje: (100 * (0.40 * sla + 0.25 * aceptacion + 0.20 * satisfaccion / 5 + 0.15 * volumen)).round(),
          );
        }(),
    ];
    return ranking..sort((a, b) => b.puntaje.compareTo(a.puntaje));
  }

  /// Primero las tardías (por días de retraso) y después las de stand-by.
  List<VacanteEnAtencion> get requierenAtencion => [
    for (final r in tardias) (vacante: r, retraso: retraso(r)),
    for (final r in standby) (vacante: r, retraso: null),
  ];

  /// Frases generadas a partir de los datos del periodo.
  List<String> get hallazgos {
    final frases = <String>[];

    final promedio = timeToFill;
    final masRapido = ranking
        .where((d) => d.cubiertas >= 2 && d.diasPromedio < promedio)
        .fold<DesempenoReclutador?>(
          null,
          (mejor, d) => mejor == null || d.diasPromedio < mejor.diasPromedio ? d : mejor,
        );
    if (masRapido != null) {
      frases.add(
        '${masRapido.nombre} cubre en ${masRapido.diasPromedio} días, '
        '${promedio - masRapido.diasPromedio} menos que el promedio del equipo.',
      );
    }

    final total = cubiertas.length;
    if (fuentes.isNotEmpty && total > 0) {
      final (fuente, n) = fuentes.first;
      frases.add('$fuente aportó el ${(n / total * 100).round()} % de las contrataciones.');
    }

    if (abiertas.isNotEmpty) {
      frases.add(
        'El ${(tardias.length / abiertas.length * 100).round()} % de las vacantes abiertas está fuera de SLA.',
      );
    }

    final ritmo = ritmoMeta;
    frases.add(
      ritmo < 0
          ? 'Faltan ${-ritmo} vacantes cubiertas para ir al ritmo de la meta anual.'
          : 'El área va ${ritmo == 0 ? 'justo al' : '$ritmo arriba del'} ritmo de la meta anual.',
    );
    return frases;
  }

  // --- Auxiliares -------------------------------------------------------

  static int _diasPromedio(List<HiringRecord> l) =>
      l.isEmpty ? 0 : (l.fold(0, (s, r) => s + r.diasParaCubrir!) / l.length).round();

  static double _enSla(List<HiringRecord> l) =>
      l.isEmpty ? 0 : l.where((r) => r.diasParaCubrir! <= r.diasSla).length / l.length;

  static double _aceptacion(List<HiringRecord> l) =>
      l.isEmpty ? 0 : l.where((r) => r.ofertaAceptada == true).length / l.length;
}
