import 'dart:math';

import '../models/hiring_record.dart';

/// "Hoy" de la demo: fijo para que los indicadores no cambien con el día.
final demoToday = DateTime(2026, 9, 24);

/// Vacantes que el área se comprometió a cubrir en el año.
const metaAnual = 72;

/// Reclutadores del equipo (los mismos de los demás seeds).
const reclutadoresEquipo = ['Mariana Ortega', 'Fernanda Torres', 'Diana Cruz', 'Emilio Rangel'];

const fuentesContratacion = ['Match AIRA', 'LinkedIn', 'Referidos', 'Bolsa interna', 'Bolsas de empleo'];

const _puestos = [
  ('Analista de Datos BI', 'Inteligencia de Negocio'),
  ('Arquitecto(a) de Soluciones Cloud', 'Infraestructura TI'),
  ('Becario(a) de QA', 'Calidad de Software'),
  ('Coordinador(a) de Logística E-commerce', 'Cadena de Suministro'),
  ('Desarrollador(a) Frontend', 'Ingeniería de Software'),
  ('Diseñador(a) UX/UI Senior', 'Producto Digital'),
  ('Especialista en Marketing Digital', 'Marketing'),
  ('Gerente de Proyectos E-commerce', 'Canales Digitales'),
  ('Gerente de Tienda Departamental', 'Operaciones de Tienda'),
  ('HR Business Partner', 'Capital Humano'),
  ('Scrum Master', 'Transformación Ágil'),
];

// Resultado fijo en "Este año": 45 cubiertas (19 dentro de SLA, time to fill
// de 38 días), 15 abiertas (7 tardías, 3 vencen esta semana), 2 en stand-by
// y 2 canceladas. 64 vacantes en total.
const _cubiertas = 45;
const _cubiertasEnSla = 19;
const _timeToFill = 38;

// Reclutador de cada abierta y stand-by, para que todos tengan pendientes.
const _tardias = [
  'Mariana Ortega',
  'Diana Cruz',
  'Emilio Rangel',
  'Mariana Ortega',
  'Fernanda Torres',
  'Diana Cruz',
  'Emilio Rangel',
];
const _vencen = ['Mariana Ortega', 'Fernanda Torres', 'Emilio Rangel'];
const _aTiempo = ['Diana Cruz', 'Mariana Ortega', 'Fernanda Torres', 'Emilio Rangel', 'Diana Cruz'];
const _standby = [
  ('Mariana Ortega', 'Presupuesto congelado por el negocio'),
  ('Emilio Rangel', 'Reestructura del área'),
];

// Cubiertas por mes de enero a septiembre (suman 45; la meta mensual es 6).
const _porMes = [2, 3, 4, 5, 6, 7, 6, 7, 5];

/// Historial simulado de 2026. Usa una semilla fija: siempre produce los
/// mismos registros y, por lo tanto, los mismos indicadores.
List<HiringRecord> generateHiringHistory() {
  final rng = Random(2026);
  final inicioAnio = DateTime(2026, 1, 1);
  final records = <HiringRecord>[];
  var n = 0;
  String id() => 'h${(++n).toString().padLeft(2, '0')}';
  (String, String) puesto() => _puestos[rng.nextInt(_puestos.length)];
  NivelVacante nivel() => const [
    NivelVacante.bajo,
    NivelVacante.medio,
    NivelVacante.medio,
    NivelVacante.alto,
    NivelVacante.alto,
    NivelVacante.complejo,
  ][rng.nextInt(6)];

  // Cubiertas: primero el nivel y si cerró dentro de SLA; luego los días.
  final enSla = [for (var i = 0; i < _cubiertas; i++) i < _cubiertasEnSla]..shuffle(rng);
  final niveles = [for (var i = 0; i < _cubiertas; i++) nivel()];
  int minDias(int i) => enSla[i] ? 8 : niveles[i].diasSla + 1;
  int maxDias(int i) => enSla[i] ? niveles[i].diasSla : niveles[i].diasSla + 35;
  final dias = [
    for (var i = 0; i < _cubiertas; i++)
      enSla[i]
          ? niveles[i].diasSla - rng.nextInt((niveles[i].diasSla * 0.5).round())
          : niveles[i].diasSla + 1 + rng.nextInt(25),
  ];
  // Ajuste determinista hasta que el promedio sea exactamente el esperado.
  var diff = _timeToFill * _cubiertas - dias.fold(0, (a, b) => a + b);
  for (var i = 0; diff != 0; i = (i + 1) % _cubiertas) {
    if (diff > 0 && dias[i] < maxDias(i)) {
      dias[i]++;
      diff--;
    } else if (diff < 0 && dias[i] > minDias(i)) {
      dias[i]--;
      diff++;
    }
  }

  // Cada mes toma cubiertas al azar entre las que caben (su apertura debe
  // caer en 2026): los primeros meses reciben solo las rápidas y el resto
  // queda mezclado, así ningún periodo corto concentra las más lentas.
  final pendientes = [for (var i = 0; i < _cubiertas; i++) i];
  final meses = [for (var m = 0; m < _porMes.length; m++) ...List.filled(_porMes[m], m + 1)];
  for (final mes in meses) {
    final finDeMes = DateTime(2026, mes + 1, 0).difference(inicioAnio).inDays;
    final caben = pendientes.where((i) => dias[i] < finDeMes).toList();
    final i = caben.isEmpty
        ? pendientes.reduce((a, b) => dias[a] <= dias[b] ? a : b)
        : caben[rng.nextInt(caben.length)];
    pendientes.remove(i);
    final ultimoDia = mes == demoToday.month ? demoToday.day : DateTime(2026, mes + 1, 0).day;
    var cierre = DateTime(2026, mes, 1 + rng.nextInt(ultimoDia));
    final minimo = inicioAnio.add(Duration(days: dias[i]));
    if (cierre.isBefore(minimo)) cierre = minimo;
    final (p, area) = puesto();
    records.add(
      HiringRecord(
        id: id(),
        puesto: p,
        area: area,
        nivel: niveles[i],
        reclutador: reclutadoresEquipo[rng.nextInt(reclutadoresEquipo.length)],
        apertura: cierre.subtract(Duration(days: dias[i])),
        cierre: cierre,
        estado: EstadoVacante.cubierta,
        diasSla: niveles[i].diasSla,
        fuente: fuentesContratacion[const [0, 0, 0, 1, 1, 2, 2, 3, 4][rng.nextInt(9)]],
        ofertaAceptada: rng.nextDouble() < 0.8,
        satisfaccionHm: (30 + rng.nextInt(21)) / 10,
      ),
    );
  }

  HiringRecord abierta(String reclutador, int diasAbierta, NivelVacante nv) {
    final (p, area) = puesto();
    return HiringRecord(
      id: id(),
      puesto: p,
      area: area,
      nivel: nv,
      reclutador: reclutador,
      apertura: demoToday.subtract(Duration(days: diasAbierta)),
      estado: EstadoVacante.abierta,
      diasSla: nv.diasSla,
    );
  }

  for (final r in _tardias) {
    final nv = nivel();
    records.add(abierta(r, nv.diasSla + 1 + rng.nextInt(30), nv));
  }
  for (final r in _vencen) {
    final nv = nivel();
    records.add(abierta(r, nv.diasSla - rng.nextInt(7), nv));
  }
  for (final r in _aTiempo) {
    final nv = nivel();
    records.add(abierta(r, 2 + rng.nextInt(nv.diasSla - 12), nv));
  }

  for (final (r, motivo) in _standby) {
    final (p, area) = puesto();
    final nv = nivel();
    records.add(
      HiringRecord(
        id: id(),
        puesto: p,
        area: area,
        nivel: nv,
        reclutador: r,
        apertura: demoToday.subtract(Duration(days: 40 + rng.nextInt(40))),
        estado: EstadoVacante.standby,
        diasSla: nv.diasSla,
        motivoStandby: motivo,
      ),
    );
  }

  for (var i = 0; i < 2; i++) {
    final (p, area) = puesto();
    final nv = nivel();
    final apertura = DateTime(2026, 2 + i * 2, 3 + rng.nextInt(20));
    records.add(
      HiringRecord(
        id: id(),
        puesto: p,
        area: area,
        nivel: nv,
        reclutador: reclutadoresEquipo[rng.nextInt(reclutadoresEquipo.length)],
        apertura: apertura,
        cierre: apertura.add(Duration(days: 10 + rng.nextInt(20))),
        estado: EstadoVacante.cancelada,
        diasSla: nv.diasSla,
      ),
    );
  }

  return records;
}
