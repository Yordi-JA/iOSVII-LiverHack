import 'package:puerta_liverpool/backend/candidatos/models.dart';

/// Datos de prueba con la forma de assets/seed_data_liverhack.json.
/// No son el seed real: solo cubren los casos de las reglas.
final fixtureJson = <String, dynamic>{
  'sla': {
    'duracion_base_dias': {'Requisición': 1, 'Alineación': 2, 'Búsqueda': 9, 'Atracción': 17, 'Selección': 8, 'Oferta': 10},
    'multiplicador_complejidad': {'Bajo': 0.75, 'Medio': 1, 'Alto': 1.25, 'Complejo': 1.5},
    'alerta_hm_dias': {'ambar': 3, 'rojo': 5},
  },
  'vacantes': [
    {
      'id': 'VAC-101',
      'titulo': 'Gerente de Proyectos E-commerce',
      'area': 'Tecnología',
      'complejidad': 'Alto',
      'presupuesto_max': 1250000,
      'etapa_actual': 5,
      'dias_en_etapa': 4,
      'hiring_manager': 'Aileen Vargas',
      'reclutador': 'Diana Cruz',
      'hrbp': 'Paola Núñez',
      'perfil_no_negociables': ['Inglés avanzado'],
    },
    {
      'id': 'VAC-102',
      'titulo': 'Analista de Datos',
      'area': 'Finanzas',
      'complejidad': 'Bajo',
      'presupuesto_max': 600000,
      'etapa_actual': 4,
      'dias_en_etapa': 14,
      'hiring_manager': 'Luis Mora',
      'reclutador': 'Diana Cruz',
      'hrbp': 'Paola Núñez',
      'perfil_no_negociables': [],
    },
    {
      'id': 'VAC-103',
      'titulo': 'Gerente de Tienda',
      'area': 'Operaciones',
      'complejidad': 'Alto',
      'presupuesto_max': 950000,
      'etapa_actual': 1,
      'dias_en_etapa': 1,
      'hiring_manager': 'Andrés Molina',
      'reclutador': 'Emilio Rangel',
      'hrbp': 'Paola Núñez',
      'perfil_no_negociables': ['Retail 5+ años'],
    },
    {
      'id': 'VAC-104',
      'titulo': 'Coordinador de Logística',
      'area': 'Cadena de Suministro',
      'complejidad': 'Medio',
      'presupuesto_max': 700000,
      'etapa_actual': 2,
      'dias_en_etapa': 3,
      'hiring_manager': 'Aileen Vargas',
      'reclutador': 'Diana Cruz',
      'hrbp': 'Gustavo Ibarra',
      'perfil_no_negociables': ['Última milla', 'SAP EWM'],
    },
  ],
  'candidatos': [
    _candidato(1, 'Ana López', 92, 1200000, enviado: true, dias: 2, entrevistas: [
      {'entrevista_id': 500, 'dias_desde_hoy': -12, 'entrevistadores': ['Sofia Rodriguez (Líder Técnico)'], 'notas': 'Sólida.', 'veredicto': 'Recomendado'},
      {'entrevista_id': 501, 'dias_desde_hoy': -3, 'entrevistadores': ['Aileen Vargas (HM)'], 'notas': '', 'veredicto': null},
    ]),
    _candidato(2, 'Patricia Ruiz', 88, 1300000, enviado: true, dias: 3),
    _candidato(3, 'Héctor Salas', 85, 1500000, enviado: true, dias: 6),
    _candidato(4, 'Mario Díaz', 80, 1100000),
    _candidato(5, 'Laura Pérez', 79, 1000000),
    _candidato(6, 'Iván Soto', 90, 700000, vacante: 'VAC-102', enviado: true, dias: 5),
    // Siguen en el ATS (Aira) hasta que Reclutamiento los importe en Búsqueda.
    _candidato(7, 'Luis Arriaga', 90, 650000, vacante: 'VAC-104', importado: false),
    _candidato(8, 'Karla Méndez', 86, 690000, vacante: 'VAC-104', importado: false),
  ],
};

Map<String, dynamic> _candidato(
  int id,
  String nombre,
  int compat,
  int deseada, {
  String vacante = 'VAC-101',
  bool enviado = false,
  int? dias,
  List<Map<String, dynamic>> entrevistas = const [],
  bool importado = true,
}) =>
    {
      'id': id,
      'vacante_id': vacante,
      'nombre': nombre,
      'puesto_actual': 'Gerente',
      'empresa_actual': 'Empresa $id',
      'resumen_profesional': 'Resumen de $nombre.',
      'anos_experiencia': 8,
      'compensacion_actual': 900000,
      'compensacion_deseada': deseada,
      'escolaridad': 'Licenciatura',
      'otros_estudios': 'PMP',
      'idiomas': [
        {'idioma': 'Inglés', 'nivel': 'C1'},
        {'idioma': 'Español', 'nivel': 'Nativo'},
      ],
      'cv_path': '/cvs/cv_$id.pdf',
      'assessfirst': {
        'compatibilidad': compat,
        'descripcion': 'Perfil analítico.',
        'fortalezas': ['Liderazgo'],
        'areas_oportunidad': ['Delegación'],
        'estilo_liderazgo': 'Transformacional',
        'vision_estrategica': 'Alta',
        'toma_decisiones': 'Basada en datos',
        'recomendaciones': 'Avanzar',
      },
      'status_proceso': 'En Proceso',
      'status_justificacion': '',
      'enviado_hm': enviado,
      'dias_esperando_hm': dias,
      'entrevistas': entrevistas,
      'importado': importado,
    };

LiverhackSeed fixtureSeed() => LiverhackSeed.fromJson(fixtureJson);
