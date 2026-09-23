import '../models/app_alert.dart';
import '../models/person.dart';
import '../models/vacancy.dart';

export 'seed_candidates.dart';

const seedVacancies = <Vacancy>[
  Vacancy(
    id: 'v1',
    titulo: 'Gerente de Proyectos Digitales',
    area: 'E-commerce',
    nivel: VacancyLevel.alto,
    etapaActual: 5,
    hiringManager: 'Aileen Vargas',
    hrbp: 'Mayra Cuandon',
    reclutador: 'Mariana Ortega',
    bandaMax: 1300000,
    tiempos: [
      StageTiming(dias: 4, sla: 5),
      StageTiming(dias: 3, sla: 4),
      StageTiming(dias: 8, sla: 10),
      StageTiming(dias: 7, sla: 8),
      StageTiming(dias: 9, sla: 12),
      StageTiming(dias: null, sla: 6),
    ],
  ),
  Vacancy(
    id: 'v2',
    titulo: 'Analista de Datos',
    area: 'Business Intelligence',
    nivel: VacancyLevel.medio,
    etapaActual: 4,
    hiringManager: 'Juan Perez',
    hrbp: 'Mayra Cuandon',
    reclutador: 'Mariana Ortega',
    bandaMax: 700000,
    tiempos: [
      StageTiming(dias: 3, sla: 4),
      StageTiming(dias: 3, sla: 3),
      StageTiming(dias: 7, sla: 8),
      StageTiming(dias: 9, sla: 7),
      StageTiming(dias: null, sla: 9),
      StageTiming(dias: null, sla: 4),
    ],
  ),
  Vacancy(
    id: 'v3',
    titulo: 'Desarrollador Frontend',
    area: 'Tecnología',
    nivel: VacancyLevel.medio,
    etapaActual: 3,
    hiringManager: 'Sofia Rodriguez',
    hrbp: 'Mayra Cuandon',
    reclutador: 'Fernanda Torres',
    bandaMax: 800000,
    tiempos: [
      StageTiming(dias: 5, sla: 4),
      StageTiming(dias: 3, sla: 3),
      StageTiming(dias: 12, sla: 7),
      StageTiming(dias: null, sla: 7),
      StageTiming(dias: null, sla: 9),
      StageTiming(dias: null, sla: 4),
    ],
  ),
  Vacancy(
    id: 'v4',
    titulo: 'HR Business Partner',
    area: 'Capital Humano',
    nivel: VacancyLevel.complejo,
    etapaActual: 6,
    hiringManager: 'Alejandra Escobar',
    hrbp: 'Mayra Cuandon',
    reclutador: 'Aileen Vargas',
    bandaMax: 950000,
    cerrada: true,
    tiempos: [
      StageTiming(dias: 5, sla: 6),
      StageTiming(dias: 4, sla: 5),
      StageTiming(dias: 11, sla: 12),
      StageTiming(dias: 9, sla: 10),
      StageTiming(dias: 13, sla: 15),
      StageTiming(dias: 6, sla: 7),
    ],
  ),
];

const seedAlerts = <AppAlert>[
  AppAlert(
    id: 'a1',
    tipo: AlertType.sla,
    severidad: AlertSeverity.alta,
    mensaje: 'Desarrollador Frontend lleva 12 días en Búsqueda (SLA 7)',
    accion: 'Escalado al HRBP',
  ),
  AppAlert(
    id: 'a2',
    tipo: AlertType.feedback,
    severidad: AlertSeverity.media,
    mensaje: 'Aileen Vargas no ha enviado el feedback final de Sofia Herrera (48 h)',
    accion: 'Recordatorio enviado',
  ),
  AppAlert(
    id: 'a3',
    tipo: AlertType.compensacion,
    severidad: AlertSeverity.media,
    mensaje: 'David Peña: compensación deseada 31 % arriba de la banda',
    accion: 'Revisar con HRBP',
  ),
  AppAlert(
    id: 'a4',
    tipo: AlertType.agenda,
    severidad: AlertSeverity.info,
    mensaje: 'Entrevista final de Sofia Herrera mañana a las 10:00',
    accion: '3 entrevistadores invitados',
  ),
];

const seedPeople = <Person>[
  Person(id: 'p1', nombre: 'Mariana Ortega', rol: UserRole.reclutador, puesto: 'Reclutadora Sr. de Atracción de Talento', vacantesAsignadas: 2),
  Person(id: 'p2', nombre: 'Fernanda Torres', rol: UserRole.reclutador, puesto: 'Especialista de Marca Empleadora', vacantesAsignadas: 1),
  Person(id: 'p3', nombre: 'Aileen Vargas', rol: UserRole.hiringManager, puesto: 'Hiring Manager E-commerce', vacantesAsignadas: 2),
  Person(id: 'p4', nombre: 'Juan Perez', rol: UserRole.hiringManager, puesto: 'Gerente de BI', vacantesAsignadas: 1),
  Person(id: 'p5', nombre: 'Mayra Cuandon', rol: UserRole.hrbp, puesto: 'HR Business Partner', vacantesAsignadas: 4),
  Person(id: 'p6', nombre: 'Sofia Rodriguez', rol: UserRole.entrevistador, puesto: 'Líder Técnico', vacantesAsignadas: 1),
  Person(id: 'p7', nombre: 'Carlos Sanchez', rol: UserRole.entrevistador, puesto: 'Director de Marketing', vacantesAsignadas: 0),
];
