import '../models/person.dart';
import 'models.dart';

/// Tono visual de una regla. La UI lo traduce a color.
enum Tone { ok, warn, bad, mute }

enum SlaLevel { none, green, amber, red }

typedef SlaInfo = ({SlaLevel level, String text, Tone tone});

/// SLA del candidato con el Hiring manager (5.1).
SlaInfo slaInfo(Candidato c, SlaConfig sla) {
  final d = c.diasEsperandoHm;
  if (c.status != StatusProceso.enProceso || !c.enviadoHm || d == null) {
    return (level: SlaLevel.none, text: 'Sin reloj', tone: Tone.mute);
  }
  if (d >= sla.alertaRojo) return (level: SlaLevel.red, text: 'Urgente, $d días', tone: Tone.bad);
  if (d >= sla.alertaAmbar) return (level: SlaLevel.amber, text: '$d días sin veredicto', tone: Tone.warn);
  return (level: SlaLevel.green, text: 'Al día, $d ${d == 1 ? 'día' : 'días'}', tone: Tone.ok);
}

bool enAlerta(Candidato c, SlaConfig sla) {
  final level = slaInfo(c, sla).level;
  return level == SlaLevel.amber || level == SlaLevel.red;
}

typedef BudgetInfo = ({Tone tone, String text});

/// Compensación deseada contra el presupuesto de la vacante (5.2).
BudgetInfo budgetInfo(Candidato c, Vacante v) {
  if (v.presupuestoMax <= 0) return (tone: Tone.mute, text: 'Sin presupuesto');
  final r = c.compensacionDeseada / v.presupuestoMax;
  final pct = ((r - 1) * 100).round();
  if (r <= 1.0) return (tone: Tone.ok, text: 'Dentro de presupuesto');
  if (r <= 1.1) return (tone: Tone.warn, text: 'Negociable (+$pct%)');
  return (tone: Tone.bad, text: 'Excede $pct%');
}

/// Días permitidos para la etapa [index] (0 a 5) según la complejidad (5.3).
int stageDays(Vacante v, int index, SlaConfig sla) {
  final base = sla.duracionBaseDias[stages[index]] ?? 1;
  final mult = sla.multiplicadorComplejidad[v.complejidad] ?? 1;
  final days = (base * mult).round();
  return days < 1 ? 1 : days;
}

/// Días estimados de todo el proceso: la suma de las 6 etapas.
int diasEstimadosProceso(Vacante v, SlaConfig sla) =>
    [for (var i = 0; i < stages.length; i++) stageDays(v, i, sla)].fold(0, (a, b) => a + b);

/// Días que lleva el proceso. El seed no trae fecha de apertura: cada etapa
/// terminada cuenta con su duración estimada y se suman los días reales de
/// la etapa actual.
int diasDelProceso(Vacante v, SlaConfig sla) =>
    [for (var i = 0; i < v.etapaActual - 1; i++) stageDays(v, i, sla)].fold(0, (a, b) => a + b) + v.diasEnEtapa;

bool etapaVencida(Vacante v, SlaConfig sla) => v.diasEnEtapa > stageDays(v, v.etapaActual - 1, sla);

// ---------------------------------------------------------------------------
// Visibilidad por rol (5.4). El rol Entrevistador se trata como solo lectura.

bool isHm(UserRole r) => r == UserRole.hiringManager;
bool isAt(UserRole r) => r == UserRole.reclutador;
bool isHrbp(UserRole r) => r == UserRole.hrbp;

bool candidatoVisible(Candidato c, UserRole r) => !isHm(r) || c.enviadoHm;

bool veCompensacionActual(UserRole r) => !isHm(r);
bool vePresupuesto(UserRole r) => !isHm(r);
bool puedeEnviarAHm(UserRole r) => isAt(r);
bool puedeDecidir(UserRole r) => isHm(r);

/// Menú lateral: "Candidatos" existe desde la Importación (etapa 3).
bool veMenuCandidatos(int etapa) => etapa >= 3;

/// Menú lateral: "Comparativa" solo en Atracción (4) y Selección (5), y
/// nunca para el HRBP, que no participa en esa decisión.
bool veComparativa(UserRole r, int etapa) => !isHrbp(r) && (etapa == 4 || etapa == 5);

/// Menú lateral: el Dashboard de Atracción de Talento es solo del Reclutador.
bool veDashboard(UserRole r) => isAt(r);

/// Máquina del tiempo: quién puede ver el detalle de una etapa pasada. Quien
/// no participó ve solo que la etapa se completó.
/// - Requisición (1): presupuesto confidencial, solo HRBP y HM.
/// - Alineación (2): solo Reclutador y HM.
bool veDetalleEtapa(UserRole r, int etapa) => switch (etapa) {
  1 => isHrbp(r) || isHm(r),
  2 => isAt(r) || isHm(r),
  _ => true,
};

String usuarioSimulado(Vacante v, UserRole r) => switch (r) {
  UserRole.reclutador => v.reclutador,
  UserRole.hiringManager => v.hiringManager,
  _ => v.hrbp,
};

String tituloBarraVacantes(UserRole r) => switch (r) {
  UserRole.reclutador => 'Tus vacantes',
  UserRole.hiringManager => 'Vacantes con candidatos para ti',
  _ => 'Vacantes de tu área',
};

// ---------------------------------------------------------------------------
// Normalización del radar, escala 0 a 10 (5.5).

const radarAxes = [
  'Compatibilidad',
  'Experiencia',
  'Inglés',
  'Liderazgo',
  'Visión estratégica',
  'Ajuste a presupuesto',
];

const _nivelIngles = {'A1': 1, 'A2': 2, 'B1': 4, 'B2': 6, 'C1': 8, 'C2': 10, 'Nativo': 10};

const _liderazgo = {
  'Transformacional': 9,
  'Coach': 8,
  'Situacional': 8,
  'Participativo': 7,
  'Democrático': 7,
  'Servicial': 7,
  'Directivo': 6,
  'Colaborador individual': 3,
  'En desarrollo': 2,
};

const _vision = {'Alta': 9, 'Media': 6, 'Baja': 3};

double inglesScore(Candidato c) {
  final ingles = c.idiomas.where((i) => i.idioma == 'Inglés').firstOrNull;
  return (_nivelIngles[ingles?.nivel] ?? 0).toDouble();
}

double liderazgoScore(Candidato c) => (_liderazgo[c.assessFirst.estiloLiderazgo] ?? 3).toDouble();

double visionScore(Candidato c) => (_vision[c.assessFirst.visionEstrategica] ?? 0).toDouble();

/// Nivel del medidor de 3 segmentos de visión estratégica (Baja 1, Media 2, Alta 3).
int visionSegments(String vision) => switch (vision) {
  'Alta' => 3,
  'Media' => 2,
  'Baja' => 1,
  _ => 0,
};

double presupuestoScore(Candidato c, Vacante v) {
  if (c.compensacionDeseada <= 0) return 10;
  final ratio = v.presupuestoMax / c.compensacionDeseada;
  return ((ratio < 1 ? ratio : 1) * 100).round() / 10;
}

/// Valores del radar en el orden de [radarAxes].
List<double> radarScore(Candidato c, Vacante v) => [
  c.assessFirst.compatibilidad / 10,
  c.anosExperiencia.clamp(0.5, 10).toDouble(),
  inglesScore(c),
  liderazgoScore(c),
  visionScore(c),
  presupuestoScore(c, v),
];

// ---------------------------------------------------------------------------
// Tabulador salarial de referencia por complejidad (MXN anuales). El seed no
// trae un tabulador: estos topes son valores de demo para la alerta del HRBP.

const tabuladorReferencia = {'Bajo': 450000, 'Medio': 800000, 'Alto': 900000, 'Complejo': 1400000};

/// La requisición pide más presupuesto que el tope del tabulador.
bool excedeTabulador(Vacante v) {
  final tope = tabuladorReferencia[v.complejidad];
  return tope != null && v.presupuestoMax > tope;
}
