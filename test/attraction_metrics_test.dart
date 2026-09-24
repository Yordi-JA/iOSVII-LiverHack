import 'package:flutter_test/flutter_test.dart';
import 'package:puerta_liverpool/backend/models/hiring_record.dart';
import 'package:puerta_liverpool/backend/seed/seed_history.dart';
import 'package:puerta_liverpool/frontend/features/dashboard/attraction_metrics.dart';

AttractionMetrics metricas([Periodo periodo = Periodo.anio]) =>
    AttractionMetrics(records: generateHiringHistory(), hoy: demoToday, metaAnual: metaAnual, periodo: periodo);

void main() {
  test('el historial simulado es determinista', () {
    final a = generateHiringHistory().map((r) => r.toMap()).toList();
    final b = generateHiringHistory().map((r) => r.toMap()).toList();
    expect(a, b);
    expect(a, hasLength(64));
    expect(generateHiringHistory().every((r) => r.apertura.year == 2026 && !r.apertura.isAfter(demoToday)), isTrue);
  });

  test('"Este año" da los indicadores de la demo', () {
    final m = metricas();
    expect(m.cubiertas, hasLength(45));
    expect(metaAnual, 72);
    expect(m.ritmoMeta, -7);
    expect(m.abiertas, hasLength(15));
    expect(m.tardias, hasLength(7));
    expect(m.standby, hasLength(2));
    expect(m.timeToFill, 38);
    expect((m.enSla * 100).round(), 42);
  });

  test('los indicadores son coherentes', () {
    final m = metricas();
    expect(m.cubiertasPorMes.fold(0, (a, b) => a + b), m.cubiertasDelAnio.length);
    expect(m.tardias.every((r) => r.estado == EstadoVacante.abierta), isTrue);
    expect(m.tardias.every((r) => m.retraso(r) > 0), isTrue);
    expect(m.requierenAtencion, hasLength(m.tardias.length + m.standby.length));
  });

  test('un periodo más corto nunca tiene más cubiertas que el año', () {
    final anio = metricas().cubiertas.length;
    final d90 = metricas(Periodo.dias90).cubiertas.length;
    final d30 = metricas(Periodo.dias30).cubiertas.length;
    expect(d90, lessThanOrEqualTo(anio));
    expect(d30, lessThanOrEqualTo(d90));
    expect(d30, lessThan(anio));
  });

  test('el ranking está ordenado de mayor a menor puntaje', () {
    for (final p in Periodo.values) {
      final ranking = metricas(p).ranking;
      expect(ranking, hasLength(reclutadoresEquipo.length));
      for (var i = 1; i < ranking.length; i++) {
        expect(ranking[i - 1].puntaje, greaterThanOrEqualTo(ranking[i].puntaje));
      }
      expect(ranking.every((d) => d.puntaje >= 0 && d.puntaje <= 100), isTrue);
    }
  });

  test('HiringRecord se serializa ida y vuelta', () {
    final r = generateHiringHistory().first;
    expect(HiringRecord.fromMap(r.id, r.toMap()).toMap(), r.toMap());
  });
}
