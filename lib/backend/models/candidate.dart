import 'package:flutter/material.dart';

import '../../frontend/core/theme/app_colors.dart';
import '../../frontend/core/utils/formatters.dart';

enum CandidateStatus {
  enProceso('En proceso', AppColors.info),
  finalista('Finalista', AppColors.success),
  descartado('Descartado', AppColors.danger);

  const CandidateStatus(this.label, this.color);

  final String label;
  final Color color;

  static CandidateStatus fromLabel(String label) =>
      values.firstWhere((s) => s.label.toLowerCase() == label.toLowerCase(), orElse: () => enProceso);
}

enum Verdict {
  recomendado('Recomendado', AppColors.success),
  noRecomendado('No recomendado', AppColors.danger),
  aprobado('Aprobado', AppColors.success),
  enRevision('En revisión', AppColors.warning);

  const Verdict(this.label, this.color);

  final String label;
  final Color color;

  static Verdict fromLabel(String label) =>
      values.firstWhere((v) => v.label.toLowerCase() == label.toLowerCase(), orElse: () => enRevision);
}

class AssessFirst {
  const AssessFirst({
    required this.compatibilidad,
    required this.descripcion,
    required this.fortalezas,
    required this.areasOportunidad,
    required this.recomendaciones,
    this.estiloLiderazgo,
    this.visionEstrategica,
    this.tomaDecisiones,
  });

  final int compatibilidad;
  final String descripcion;
  final String fortalezas;
  final String areasOportunidad;
  final String recomendaciones;
  final String? estiloLiderazgo;
  final String? visionEstrategica;
  final String? tomaDecisiones;

  factory AssessFirst.fromMap(Map<String, dynamic> map) => AssessFirst(
        compatibilidad: map['compatibilidad'] is num
            ? (map['compatibilidad'] as num).toInt()
            : int.tryParse('${map['compatibilidad']}'.replaceAll('%', '')) ?? 0,
        descripcion: map['descripcion'] ?? '',
        fortalezas: map['fortalezas'] ?? '',
        areasOportunidad: map['areas_oportunidad'] ?? '',
        recomendaciones: map['recomendaciones'] ?? '',
        estiloLiderazgo: map['estilo_liderazgo'],
        visionEstrategica: map['vision_estrategica'],
        tomaDecisiones: map['toma_decisiones'],
      );

  Map<String, dynamic> toMap() => {
        'compatibilidad': compatibilidad,
        'descripcion': descripcion,
        'fortalezas': fortalezas,
        'areas_oportunidad': areasOportunidad,
        'recomendaciones': recomendaciones,
        'estilo_liderazgo': estiloLiderazgo,
        'vision_estrategica': visionEstrategica,
        'toma_decisiones': tomaDecisiones,
      };
}

/// Feedback registrado en una etapa del proceso.
class StageFeedback {
  const StageFeedback({
    required this.autor,
    required this.rol,
    required this.nota,
    required this.veredicto,
    required this.fecha,
  });

  final String autor;
  final String rol;
  final String nota;
  final Verdict veredicto;
  final String fecha;

  factory StageFeedback.fromMap(Map<String, dynamic> map) => StageFeedback(
        autor: map['autor'] ?? '',
        rol: map['rol'] ?? '',
        nota: map['nota'] ?? '',
        veredicto: Verdict.fromLabel(map['veredicto'] ?? ''),
        fecha: map['fecha'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'autor': autor,
        'rol': rol,
        'nota': nota,
        'veredicto': veredicto.label,
        'fecha': fecha,
      };
}

/// Datos de contacto y enlaces profesionales. Todos opcionales.
class ContactInfo {
  const ContactInfo({this.telefono, this.email, this.linkedin, this.github, this.portafolio, this.ciudad});

  final String? telefono;
  final String? email;
  final String? linkedin;
  final String? github;
  final String? portafolio;
  final String? ciudad;

  factory ContactInfo.fromMap(Map<String, dynamic> map) => ContactInfo(
        telefono: map['telefono'],
        email: map['email'],
        linkedin: map['linkedin'],
        github: map['github'],
        portafolio: map['portafolio'],
        ciudad: map['ciudad'],
      );

  Map<String, dynamic> toMap() => {
        'telefono': telefono,
        'email': email,
        'linkedin': linkedin,
        'github': github,
        'portafolio': portafolio,
        'ciudad': ciudad,
      };
}

class Candidate {
  const Candidate({
    required this.id,
    required this.nombre,
    required this.puestoActual,
    required this.empresaActual,
    required this.resumenProfesional,
    required this.cvPath,
    required this.compensacionActual,
    required this.compensacionDeseada,
    required this.escolaridad,
    required this.otrosEstudios,
    required this.idiomas,
    required this.assessFirst,
    required this.status,
    required this.statusJustificacion,
    required this.vacanteId,
    required this.etapaActual,
    required this.airaScore,
    required this.diasEnProceso,
    this.feedbackPorEtapa = const {},
    this.fotoUrl,
    this.contacto = const ContactInfo(),
  });

  final String id;
  final String nombre;
  final String puestoActual;
  final String empresaActual;
  final String resumenProfesional;
  final String cvPath;
  final int compensacionActual;
  final int compensacionDeseada;
  final String escolaridad;
  final String otrosEstudios;
  final String idiomas;
  final AssessFirst assessFirst;
  final CandidateStatus status;
  final String statusJustificacion;
  final String vacanteId;

  /// Etapa del flujo (1 a 6).
  final int etapaActual;

  /// Puntaje de match calculado por AIRA (0 a 100).
  final int airaScore;
  final int diasEnProceso;
  final Map<int, StageFeedback> feedbackPorEtapa;
  final String? fotoUrl;
  final ContactInfo contacto;

  String get initials => initialsOf(nombre);
  String get firstName => nombre.split(' ').first;

  /// Nivel de inglés extraído de "Inglés (C1), Español (Nativo)".
  String get nivelIngles {
    final match = RegExp(r'Ingl[eé]s \(([^)]+)\)').firstMatch(idiomas);
    return match?.group(1) ?? '—';
  }

  /// Última etapa con feedback registrado, o la etapa actual si no hay.
  int get latestFeedbackStage =>
      feedbackPorEtapa.isEmpty ? etapaActual : feedbackPorEtapa.keys.reduce((a, b) => a > b ? a : b);

  factory Candidate.fromMap(String id, Map<String, dynamic> map) {
    final rawFeedback = (map['feedback_por_etapa'] as Map<String, dynamic>?) ?? {};
    return Candidate(
      id: id,
      nombre: map['nombre'] ?? '',
      puestoActual: map['puesto_actual'] ?? '',
      empresaActual: map['empresa_actual'] ?? '',
      resumenProfesional: map['resumen_profesional'] ?? '',
      cvPath: map['cv_path'] ?? '',
      compensacionActual: (map['compensacion_actual'] as num?)?.toInt() ?? 0,
      compensacionDeseada: (map['compensacion_deseada'] as num?)?.toInt() ?? 0,
      escolaridad: map['escolaridad'] ?? '',
      otrosEstudios: map['otros_estudios'] ?? '',
      idiomas: map['idiomas'] ?? '',
      assessFirst: AssessFirst.fromMap(Map<String, dynamic>.from(map['assessfirst'] ?? {})),
      status: CandidateStatus.fromLabel(map['status_proceso'] ?? ''),
      statusJustificacion: map['status_justificacion'] ?? '',
      vacanteId: map['vacante_id'] ?? '',
      etapaActual: (map['etapa_actual'] as num?)?.toInt() ?? 1,
      airaScore: (map['aira_score'] as num?)?.toInt() ?? 0,
      diasEnProceso: (map['dias_en_proceso'] as num?)?.toInt() ?? 0,
      feedbackPorEtapa: rawFeedback.map(
        (k, v) => MapEntry(int.parse(k), StageFeedback.fromMap(Map<String, dynamic>.from(v))),
      ),
      fotoUrl: map['foto_url'],
      contacto: ContactInfo.fromMap(Map<String, dynamic>.from(map['contacto'] ?? {})),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'puesto_actual': puestoActual,
        'empresa_actual': empresaActual,
        'resumen_profesional': resumenProfesional,
        'cv_path': cvPath,
        'compensacion_actual': compensacionActual,
        'compensacion_deseada': compensacionDeseada,
        'escolaridad': escolaridad,
        'otros_estudios': otrosEstudios,
        'idiomas': idiomas,
        'assessfirst': assessFirst.toMap(),
        'status_proceso': status.label,
        'status_justificacion': statusJustificacion,
        'vacante_id': vacanteId,
        'etapa_actual': etapaActual,
        'aira_score': airaScore,
        'dias_en_proceso': diasEnProceso,
        'feedback_por_etapa': feedbackPorEtapa.map((k, v) => MapEntry('$k', v.toMap())),
        'foto_url': fotoUrl,
        'contacto': contacto.toMap(),
      };
}
