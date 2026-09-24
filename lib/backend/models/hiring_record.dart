/// Nivel de la vacante: define los días comprometidos de su SLA.
enum NivelVacante {
  bajo('Bajo', 20),
  medio('Medio', 35),
  alto('Alto', 45),
  complejo('Complejo', 60);

  const NivelVacante(this.label, this.diasSla);

  final String label;

  /// Días comprometidos para cubrir la vacante.
  final int diasSla;
}

enum EstadoVacante { abierta, standby, cubierta, cancelada }

/// Registro del historial de vacantes del área (colección `historial_vacantes`).
class HiringRecord {
  const HiringRecord({
    required this.id,
    required this.puesto,
    required this.area,
    required this.nivel,
    required this.reclutador,
    required this.apertura,
    required this.estado,
    required this.diasSla,
    this.cierre,
    this.fuente,
    this.ofertaAceptada,
    this.satisfaccionHm,
    this.motivoStandby,
  });

  final String id;
  final String puesto;
  final String area;
  final NivelVacante nivel;
  final String reclutador;
  final DateTime apertura;

  /// Fecha en que se cubrió o se canceló; `null` si sigue abierta o en stand-by.
  final DateTime? cierre;
  final EstadoVacante estado;
  final int diasSla;

  /// Fuente de la contratación (solo cubiertas).
  final String? fuente;

  /// El candidato aceptó la primera oferta (solo cubiertas).
  final bool? ofertaAceptada;

  /// Calificación del Hiring Manager, de 1 a 5 (solo cubiertas).
  final double? satisfaccionHm;
  final String? motivoStandby;

  /// Días entre apertura y cierre (time to fill); `null` si no ha cerrado.
  int? get diasParaCubrir => cierre?.difference(apertura).inDays;

  /// Días que lleva abierta a la fecha [hoy].
  int diasAbierta(DateTime hoy) => hoy.difference(apertura).inDays;

  factory HiringRecord.fromMap(String id, Map<String, dynamic> map) => HiringRecord(
    id: id,
    puesto: map['puesto'] as String? ?? '',
    area: map['area'] as String? ?? '',
    nivel: NivelVacante.values.byName(map['nivel'] as String? ?? 'medio'),
    reclutador: map['reclutador'] as String? ?? '',
    apertura: _fecha(map['apertura'])!,
    cierre: _fecha(map['cierre']),
    estado: EstadoVacante.values.byName(map['estado'] as String? ?? 'abierta'),
    diasSla: (map['dias_sla'] as num?)?.toInt() ?? 0,
    fuente: map['fuente'] as String?,
    ofertaAceptada: map['oferta_aceptada'] as bool?,
    satisfaccionHm: (map['satisfaccion_hm'] as num?)?.toDouble(),
    motivoStandby: map['motivo_standby'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'puesto': puesto,
    'area': area,
    'nivel': nivel.name,
    'reclutador': reclutador,
    'apertura': apertura.toIso8601String(),
    'cierre': cierre?.toIso8601String(),
    'estado': estado.name,
    'dias_sla': diasSla,
    'fuente': fuente,
    'oferta_aceptada': ofertaAceptada,
    'satisfaccion_hm': satisfaccionHm,
    'motivo_standby': motivoStandby,
  };

  /// Las fechas se guardan como texto ISO 8601; también acepta un
  /// `Timestamp` de Firestore (cualquier objeto con `toDate()`).
  static DateTime? _fecha(Object? v) => switch (v) {
    null => null,
    DateTime d => d,
    String s => DateTime.parse(s),
    _ => (v as dynamic).toDate() as DateTime,
  };
}
