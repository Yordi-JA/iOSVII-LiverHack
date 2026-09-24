/// Modelos del módulo de Candidatos. Se leen de
/// `assets/seed_data_liverhack.json` (ver [LiverhackSeed.fromJson]).
library;

/// Etapas del flujo, en orden. La posición coincide con `etapa_actual - 1`.
const stages = ['Requisición', 'Alineación', 'Búsqueda', 'Atracción', 'Selección', 'Oferta'];

enum StatusProceso {
  enProceso('En Proceso'),
  finalista('Finalista'),

  /// Elegido por el HM para la oferta final (etapa 6).
  oferta('Oferta'),
  descartado('Descartado');

  const StatusProceso(this.json);

  /// Valor tal como viene en el JSON.
  final String json;

  static StatusProceso fromJson(String? value) => values.firstWhere((s) => s.json == value, orElse: () => enProceso);
}

enum Veredicto {
  recomendado('Recomendado'),
  noRecomendado('No recomendado');

  const Veredicto(this.json);

  final String json;

  /// `null` significa veredicto pendiente.
  static Veredicto? fromJson(String? value) => switch (value) {
    'Recomendado' => recomendado,
    'No recomendado' => noRecomendado,
    _ => null,
  };
}

class SlaConfig {
  const SlaConfig({
    required this.duracionBaseDias,
    required this.multiplicadorComplejidad,
    required this.alertaAmbar,
    required this.alertaRojo,
  });

  factory SlaConfig.fromJson(Map<String, dynamic> json) {
    final alerta = (json['alerta_hm_dias'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SlaConfig(
      duracionBaseDias: {
        for (final e in ((json['duracion_base_dias'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      multiplicadorComplejidad: {
        for (final e in ((json['multiplicador_complejidad'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
      alertaAmbar: (alerta['ambar'] as num?)?.toInt() ?? 3,
      alertaRojo: (alerta['rojo'] as num?)?.toInt() ?? 5,
    );
  }

  final Map<String, int> duracionBaseDias;
  final Map<String, double> multiplicadorComplejidad;
  final int alertaAmbar;
  final int alertaRojo;
}

class Vacante {
  const Vacante({
    required this.id,
    required this.titulo,
    required this.area,
    required this.complejidad,
    required this.presupuestoMax,
    required this.etapaActual,
    required this.diasEnEtapa,
    required this.hiringManager,
    required this.reclutador,
    required this.hrbp,
    required this.perfilNoNegociables,
    this.ofertaAprobada = false,
  });

  factory Vacante.fromJson(Map<String, dynamic> json) => Vacante(
    id: json['id'] as String,
    titulo: json['titulo'] as String? ?? '',
    area: json['area'] as String? ?? '',
    complejidad: json['complejidad'] as String? ?? 'Medio',
    presupuestoMax: (json['presupuesto_max'] as num?)?.toInt() ?? 0,
    etapaActual: (json['etapa_actual'] as num?)?.toInt() ?? 1,
    diasEnEtapa: (json['dias_en_etapa'] as num?)?.toInt() ?? 0,
    hiringManager: json['hiring_manager'] as String? ?? '',
    reclutador: json['reclutador'] as String? ?? '',
    hrbp: json['hrbp'] as String? ?? '',
    perfilNoNegociables: _strings(json['perfil_no_negociables']),
    ofertaAprobada: json['oferta_aprobada'] as bool? ?? false,
  );

  final String id;
  final String titulo;
  final String area;

  /// "Bajo" | "Medio" | "Alto" | "Complejo".
  final String complejidad;
  final int presupuestoMax;

  /// 1 a 6, índice + 1 de [stages].
  final int etapaActual;
  final int diasEnEtapa;
  final String hiringManager;
  final String reclutador;
  final String hrbp;
  final List<String> perfilNoNegociables;

  /// El HRBP aprobó el paquete de la oferta: arrancan los trámites de contratación.
  final bool ofertaAprobada;

  String get etapaNombre => stages[(etapaActual - 1).clamp(0, stages.length - 1)];

  Vacante copyWith({
    int? etapaActual,
    int? diasEnEtapa,
    int? presupuestoMax,
    List<String>? perfilNoNegociables,
    bool? ofertaAprobada,
  }) => Vacante(
        id: id,
        titulo: titulo,
        area: area,
        complejidad: complejidad,
        presupuestoMax: presupuestoMax ?? this.presupuestoMax,
        etapaActual: etapaActual ?? this.etapaActual,
        diasEnEtapa: diasEnEtapa ?? this.diasEnEtapa,
        hiringManager: hiringManager,
        reclutador: reclutador,
        hrbp: hrbp,
        perfilNoNegociables: perfilNoNegociables ?? this.perfilNoNegociables,
        ofertaAprobada: ofertaAprobada ?? this.ofertaAprobada,
      );
}

class Idioma {
  const Idioma({required this.idioma, required this.nivel});

  factory Idioma.fromJson(Map<String, dynamic> json) =>
      Idioma(idioma: json['idioma'] as String? ?? '', nivel: json['nivel'] as String? ?? '');

  final String idioma;
  final String nivel;
}

class EvaluacionAssessFirst {
  const EvaluacionAssessFirst({
    required this.compatibilidad,
    required this.descripcion,
    required this.fortalezas,
    required this.areasOportunidad,
    required this.estiloLiderazgo,
    required this.visionEstrategica,
    required this.tomaDecisiones,
    required this.recomendaciones,
  });

  factory EvaluacionAssessFirst.fromJson(Map<String, dynamic> json) => EvaluacionAssessFirst(
    compatibilidad: (json['compatibilidad'] as num?)?.toInt() ?? 0,
    descripcion: json['descripcion'] as String? ?? '',
    fortalezas: _strings(json['fortalezas']),
    areasOportunidad: _strings(json['areas_oportunidad']),
    estiloLiderazgo: json['estilo_liderazgo'] as String? ?? '',
    visionEstrategica: json['vision_estrategica'] as String? ?? '',
    tomaDecisiones: json['toma_decisiones'] as String? ?? '',
    recomendaciones: json['recomendaciones'] as String? ?? '',
  );

  /// 0 a 100.
  final int compatibilidad;
  final String descripcion;
  final List<String> fortalezas;
  final List<String> areasOportunidad;
  final String estiloLiderazgo;

  /// "Alta" | "Media" | "Baja".
  final String visionEstrategica;
  final String tomaDecisiones;
  final String recomendaciones;
}

class Entrevista {
  const Entrevista({
    required this.id,
    required this.diasDesdeHoy,
    required this.entrevistadores,
    required this.notas,
    required this.veredicto,
  });

  factory Entrevista.fromJson(Map<String, dynamic> json) => Entrevista(
    id: (json['entrevista_id'] as num?)?.toInt() ?? 0,
    diasDesdeHoy: (json['dias_desde_hoy'] as num?)?.toInt() ?? 0,
    entrevistadores: _strings(json['entrevistadores']),
    notas: json['notas'] as String? ?? '',
    veredicto: Veredicto.fromJson(json['veredicto'] as String?),
  );

  final int id;

  /// Negativo: días atrás.
  final int diasDesdeHoy;
  final List<String> entrevistadores;
  final String notas;

  /// `null` = veredicto pendiente.
  final Veredicto? veredicto;

  DateTime get fecha => DateTime.now().add(Duration(days: diasDesdeHoy));
}

class Candidato {
  const Candidato({
    required this.id,
    required this.vacanteId,
    required this.nombre,
    required this.puestoActual,
    required this.empresaActual,
    required this.resumenProfesional,
    required this.anosExperiencia,
    required this.compensacionActual,
    required this.compensacionDeseada,
    required this.escolaridad,
    required this.otrosEstudios,
    required this.idiomas,
    required this.cvPath,
    required this.assessFirst,
    required this.status,
    required this.statusJustificacion,
    required this.enviadoHm,
    required this.diasEsperandoHm,
    required this.entrevistas,
    this.importado = true,
  });

  factory Candidato.fromJson(Map<String, dynamic> json) => Candidato(
    id: (json['id'] as num).toInt(),
    vacanteId: json['vacante_id'] as String,
    nombre: json['nombre'] as String? ?? '',
    puestoActual: json['puesto_actual'] as String? ?? '',
    empresaActual: json['empresa_actual'] as String? ?? '',
    resumenProfesional: json['resumen_profesional'] as String? ?? '',
    anosExperiencia: (json['anos_experiencia'] as num?)?.toDouble() ?? 0,
    compensacionActual: (json['compensacion_actual'] as num?)?.toInt() ?? 0,
    compensacionDeseada: (json['compensacion_deseada'] as num?)?.toInt() ?? 0,
    escolaridad: json['escolaridad'] as String? ?? '',
    otrosEstudios: json['otros_estudios'] as String? ?? '',
    idiomas: [
      for (final i in (json['idiomas'] as List?) ?? const []) Idioma.fromJson((i as Map).cast<String, dynamic>()),
    ],
    cvPath: json['cv_path'] as String? ?? '',
    assessFirst: EvaluacionAssessFirst.fromJson(((json['assessfirst'] as Map?) ?? const {}).cast<String, dynamic>()),
    status: StatusProceso.fromJson(json['status_proceso'] as String?),
    statusJustificacion: json['status_justificacion'] as String? ?? '',
    enviadoHm: json['enviado_hm'] as bool? ?? false,
    diasEsperandoHm: (json['dias_esperando_hm'] as num?)?.toInt(),
    entrevistas: [
      for (final e in (json['entrevistas'] as List?) ?? const [])
        Entrevista.fromJson((e as Map).cast<String, dynamic>()),
    ],
    importado: json['importado'] as bool? ?? true,
  );

  final int id;
  final String vacanteId;
  final String nombre;
  final String puestoActual;
  final String empresaActual;
  final String resumenProfesional;
  final double anosExperiencia;
  final int compensacionActual;
  final int compensacionDeseada;
  final String escolaridad;
  final String otrosEstudios;
  final List<Idioma> idiomas;
  final String cvPath;
  final EvaluacionAssessFirst assessFirst;

  /// Decisión final del HM. Es distinta del veredicto de cada entrevista.
  final StatusProceso status;
  final String statusJustificacion;
  final bool enviadoHm;

  /// Días enviado al HM sin decisión final; `null` si no aplica.
  final int? diasEsperandoHm;
  final List<Entrevista> entrevistas;

  /// `false` mientras el candidato solo existe en el ATS (Aira): no se
  /// muestra hasta que Reclutamiento lo importa en la etapa de Búsqueda.
  final bool importado;

  String get firstName => nombre.split(' ').first;

  String get cvFileName => cvPath.split('/').last;

  static const _unset = Object();

  Candidato copyWith({
    StatusProceso? status,
    String? statusJustificacion,
    bool? enviadoHm,
    Object? diasEsperandoHm = _unset,
    bool? importado,
    List<Entrevista>? entrevistas,
  }) => Candidato(
    id: id,
    vacanteId: vacanteId,
    nombre: nombre,
    puestoActual: puestoActual,
    empresaActual: empresaActual,
    resumenProfesional: resumenProfesional,
    anosExperiencia: anosExperiencia,
    compensacionActual: compensacionActual,
    compensacionDeseada: compensacionDeseada,
    escolaridad: escolaridad,
    otrosEstudios: otrosEstudios,
    idiomas: idiomas,
    cvPath: cvPath,
    assessFirst: assessFirst,
    status: status ?? this.status,
    statusJustificacion: statusJustificacion ?? this.statusJustificacion,
    enviadoHm: enviadoHm ?? this.enviadoHm,
    diasEsperandoHm: identical(diasEsperandoHm, _unset) ? this.diasEsperandoHm : diasEsperandoHm as int?,
    entrevistas: entrevistas ?? this.entrevistas,
    importado: importado ?? this.importado,
  );
}

enum TipoEvento { aprobacion, negociacion, importacion, envio, decision, oferta, contratacion }

/// Registro de una acción de negocio sobre una vacante, para el histórico
/// del proceso por etapa.
class Evento {
  const Evento({
    required this.vacanteId,
    required this.etapa,
    required this.tipo,
    required this.fecha,
    required this.actor,
    required this.texto,
    this.datos = const {},
  });

  factory Evento.fromJson(Map<String, dynamic> json) => Evento(
    vacanteId: json['vacante_id'] as String,
    etapa: (json['etapa'] as num).toInt(),
    tipo: TipoEvento.values.where((t) => t.name == json['tipo']).firstOrNull ?? TipoEvento.decision,
    fecha: DateTime.fromMillisecondsSinceEpoch((json['fecha'] as num).toInt()),
    actor: json['actor'] as String? ?? '',
    texto: json['texto'] as String? ?? '',
    datos: ((json['datos'] as Map?) ?? const {}).cast<String, Object?>(),
  );

  final String vacanteId;

  /// Etapa (1 a 6) en la que ocurrió la acción.
  final int etapa;
  final TipoEvento tipo;
  final DateTime fecha;

  /// Rol que hizo la acción ("Hiring manager", "HRBP"…).
  final String actor;
  final String texto;

  /// Valores estructurados del momento (por ejemplo, el presupuesto antes de
  /// una negociación) para reconstruir instantáneas del pasado.
  final Map<String, Object?> datos;

  Map<String, dynamic> toJson() => {
    'vacante_id': vacanteId,
    'etapa': etapa,
    'tipo': tipo.name,
    'fecha': fecha.millisecondsSinceEpoch,
    'actor': actor,
    'texto': texto,
    if (datos.isNotEmpty) 'datos': datos,
  };
}

class LiverhackSeed {
  const LiverhackSeed({required this.sla, required this.vacantes, required this.candidatos});

  factory LiverhackSeed.fromJson(Map<String, dynamic> json) => LiverhackSeed(
    sla: SlaConfig.fromJson(((json['sla'] as Map?) ?? const {}).cast<String, dynamic>()),
    vacantes: [
      for (final v in (json['vacantes'] as List?) ?? const []) Vacante.fromJson((v as Map).cast<String, dynamic>()),
    ],
    candidatos: [
      for (final c in (json['candidatos'] as List?) ?? const []) Candidato.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  final SlaConfig sla;
  final List<Vacante> vacantes;
  final List<Candidato> candidatos;
}

List<String> _strings(Object? value) => [for (final v in (value as List?) ?? const []) '$v'];
