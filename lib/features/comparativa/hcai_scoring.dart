import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/candidate.dart';

/// Factores del puntaje de potencial HCAI (Human-Centered AI).
///
/// Principios: cada punto del puntaje es explicable, los pesos los decide
/// la persona reclutadora, y nunca se usan nombre, foto, género, edad ni
/// ubicación.
enum HcaiFactor {
  aira('Match AIRA', 'Qué tanto cumple los requisitos de la vacante', AppColors.purple),
  assessFirst('AssessFirst', 'Compatibilidad conductual y de personalidad', AppColors.magenta),
  feedback('Feedback humano', 'Veredictos de reclutadores y entrevistadores', AppColors.orange),
  presupuesto('Presupuesto', 'Compensación deseada contra la banda', AppColors.success),
  avance('Avance', 'Qué tan lejos llegó en el proceso', AppColors.info);

  const HcaiFactor(this.label, this.description, this.color);

  final String label;
  final String description;
  final Color color;
}

/// Atributos que el modelo ignora a propósito para evitar sesgos.
const hcaiExcludedAttributes = ['Nombre', 'Foto', 'Género', 'Edad', 'Ciudad'];

/// Pesos en puntos (0 a 50) definidos por la persona usuaria.
class HcaiWeights {
  const HcaiWeights(this.values);

  static const defaults = HcaiWeights({
    HcaiFactor.aira: 35,
    HcaiFactor.assessFirst: 25,
    HcaiFactor.feedback: 20,
    HcaiFactor.presupuesto: 10,
    HcaiFactor.avance: 10,
  });

  final Map<HcaiFactor, int> values;

  int operator [](HcaiFactor f) => values[f] ?? 0;
  int get total => values.values.fold(0, (a, b) => a + b);

  HcaiWeights copyWith(HcaiFactor factor, int weight) => HcaiWeights({...values, factor: weight});

  /// Peso normalizado (0 a 1).
  double share(HcaiFactor f) => total == 0 ? 0 : this[f] / total;
}

/// Resultado explicable para un candidato.
class HcaiResult {
  const HcaiResult({required this.candidate, required this.values, required this.weights});

  final Candidate candidate;

  /// Valor de cada factor, de 0 a 1.
  final Map<HcaiFactor, double> values;
  final HcaiWeights weights;

  /// Aporte de cada factor al puntaje final (en puntos de 0 a 100).
  double contribution(HcaiFactor f) => (values[f] ?? 0) * weights.share(f) * 100;

  double get score => HcaiFactor.values.fold(0, (sum, f) => sum + contribution(f));

  HcaiFactor get strongest => HcaiFactor.values
      .where((f) => weights[f] > 0)
      .reduce((a, b) => (values[a] ?? 0) >= (values[b] ?? 0) ? a : b);

  HcaiFactor get weakest => HcaiFactor.values
      .where((f) => weights[f] > 0)
      .reduce((a, b) => (values[a] ?? 0) <= (values[b] ?? 0) ? a : b);
}

double _verdictValue(Verdict v) => switch (v) {
      Verdict.recomendado || Verdict.aprobado => 1,
      Verdict.enRevision => 0.5,
      Verdict.noRecomendado => 0,
    };

/// Calcula el resultado HCAI de un candidato contra la banda de su vacante.
HcaiResult scoreCandidate(Candidate c, {required int bandaMax, required HcaiWeights weights}) {
  final feedback = c.feedbackPorEtapa.values;
  final feedbackValue = feedback.isEmpty
      ? 0.5
      : feedback.map((f) => _verdictValue(f.veredicto)).reduce((a, b) => a + b) / feedback.length;
  final overBudget = bandaMax <= 0 ? 0.0 : (c.compensacionDeseada - bandaMax) / bandaMax;
  final budgetValue = overBudget <= 0 ? 1.0 : (1 - overBudget * 2).clamp(0.0, 1.0);

  return HcaiResult(
    candidate: c,
    weights: weights,
    values: {
      HcaiFactor.aira: c.airaScore / 100,
      HcaiFactor.assessFirst: c.assessFirst.compatibilidad / 100,
      HcaiFactor.feedback: feedbackValue,
      HcaiFactor.presupuesto: budgetValue,
      HcaiFactor.avance: c.etapaActual / 6,
    },
  );
}

/// Ranking completo, del mayor al menor potencial.
List<HcaiResult> rankCandidates(
  List<Candidate> candidates, {
  required int Function(Candidate) bandaFor,
  required HcaiWeights weights,
}) {
  return candidates.map((c) => scoreCandidate(c, bandaMax: bandaFor(c), weights: weights)).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
}
