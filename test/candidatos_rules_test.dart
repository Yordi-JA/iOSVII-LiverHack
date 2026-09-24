import 'package:flutter_test/flutter_test.dart';
import 'package:puerta_liverpool/backend/candidatos/models.dart';
import 'package:puerta_liverpool/backend/candidatos/rules.dart';
import 'package:puerta_liverpool/backend/candidatos/seed_repository.dart';
import 'package:puerta_liverpool/frontend/core/utils/formatters.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'candidatos_fixture.dart';

void main() {
  final seed = fixtureSeed();
  final vac101 = seed.vacantes.first;
  Candidato byId(int id) => seed.candidatos.firstWhere((c) => c.id == id);

  test('el SLA del HM es verde de 0 a 2 días, ámbar de 3 a 4 y rojo desde 5', () {
    expect(slaInfo(byId(1), seed.sla), (level: SlaLevel.green, text: 'Al día, 2 días', tone: Tone.ok));
    expect(slaInfo(byId(2), seed.sla).level, SlaLevel.amber);
    expect(slaInfo(byId(2), seed.sla).text, '3 días sin veredicto');
    expect(slaInfo(byId(3), seed.sla).text, 'Urgente, 6 días');
    expect(slaInfo(byId(4), seed.sla).text, 'Sin reloj');
    final decidido = byId(3).copyWith(status: StatusProceso.finalista, diasEsperandoHm: null);
    expect(slaInfo(decidido, seed.sla).level, SlaLevel.none);
  });

  test('el tiempo del proceso suma las etapas terminadas y los días de la actual', () {
    final estimados = [for (var i = 0; i < stages.length; i++) stageDays(vac101, i, seed.sla)];
    expect(diasEstimadosProceso(vac101, seed.sla), estimados.fold(0, (a, b) => a + b));
    final previas = estimados.take(vac101.etapaActual - 1).fold(0, (a, b) => a + b);
    expect(diasDelProceso(vac101, seed.sla), previas + vac101.diasEnEtapa);
    // Al pasar de etapa, el total no retrocede.
    final siguiente = vac101.copyWith(etapaActual: vac101.etapaActual + 1, diasEnEtapa: 0);
    expect(diasDelProceso(siguiente, seed.sla), greaterThanOrEqualTo(previas));
  });

  test('el presupuesto marca dentro, negociable hasta +10% y excede después', () {
    expect(budgetInfo(byId(1), vac101).text, 'Dentro de presupuesto');
    expect(budgetInfo(byId(2), vac101).text, 'Negociable (+4%)');
    expect(budgetInfo(byId(3), vac101), (tone: Tone.bad, text: 'Excede 20%'));
  });

  test('los días por etapa usan el multiplicador de complejidad', () {
    // Alto = 1.25: Selección 8 → 10 días; Requisición 1 → 1.
    expect(stageDays(vac101, 4, seed.sla), 10);
    expect(stageDays(vac101, 0, seed.sla), 1);
    expect(etapaVencida(vac101, seed.sla), isFalse);
    // Bajo = 0.75: Atracción 17 → 13 días; lleva 14.
    expect(etapaVencida(seed.vacantes[1], seed.sla), isTrue);
  });

  test('el radar normaliza los 6 ejes a escala 0 a 10', () {
    expect(radarScore(byId(1), vac101), [9.2, 8, 8, 9, 9, 10]);
    // 1,250,000 / 1,500,000 = 0.833 → 8.3
    expect(radarScore(byId(3), vac101).last, 8.3);
  });

  test('el dinero corto no deja ceros sobrantes', () {
    expect(formatMoneyShort(1250000), r'$1.25M');
    expect(formatMoneyShort(1200000), r'$1.2M');
    expect(formatMoneyShort(1000000), r'$1M');
    expect(formatMoneyShort(950000), r'$950k');
  });

  test('la persistencia guarda solo lo que difiere del seed y lo reaplica', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LiverhackStore(await SharedPreferences.getInstance());
    final changed = [
      for (final c in seed.candidatos)
        switch (c.id) {
          4 => c.copyWith(enviadoHm: true, diasEsperandoHm: 0),
          3 => c.copyWith(status: StatusProceso.descartado, statusJustificacion: 'No cubre el presupuesto.', diasEsperandoHm: null),
          _ => c,
        },
    ];
    store.saveCandidatos(seed.candidatos, changed);
    store.role = 'hiringManager';

    final restored = store.applyOverrides(seed.candidatos);
    expect(restored.firstWhere((c) => c.id == 4).enviadoHm, isTrue);
    expect(restored.firstWhere((c) => c.id == 4).diasEsperandoHm, 0);
    expect(restored.firstWhere((c) => c.id == 3).status, StatusProceso.descartado);
    expect(restored.firstWhere((c) => c.id == 3).diasEsperandoHm, isNull);
    expect(restored.firstWhere((c) => c.id == 1).diasEsperandoHm, 2);
    expect(store.role, 'hiringManager');
  });

  test('la persistencia guarda la etapa de las vacantes que avanzaron', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LiverhackStore(await SharedPreferences.getInstance());
    final avanzadas = [
      for (final v in seed.vacantes) v.id == 'VAC-103' ? v.copyWith(etapaActual: 2, diasEnEtapa: 0) : v,
    ];
    store.saveVacantes(seed.vacantes, avanzadas);

    final restored = store.applyVacanteOverrides(seed.vacantes);
    expect(restored.firstWhere((v) => v.id == 'VAC-103').etapaActual, 2);
    expect(restored.firstWhere((v) => v.id == 'VAC-103').diasEnEtapa, 0);
    expect(restored.firstWhere((v) => v.id == 'VAC-101').etapaActual, 5);
  });
}
