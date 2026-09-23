import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/data/seed/seed_data.dart';
import 'package:pulso/features/comparativa/hcai_scoring.dart';

void main() {
  int banda(c) => seedVacancies.firstWhere((v) => v.id == c.vacanteId).bandaMax;

  test('el ranking ordena de mayor a menor y Ana queda primero', () {
    final ranking = rankCandidates(seedCandidates, bandaFor: banda, weights: HcaiWeights.defaults);
    expect(ranking.first.candidate.nombre, 'Ana López');
    for (var i = 1; i < ranking.length; i++) {
      expect(ranking[i - 1].score, greaterThanOrEqualTo(ranking[i].score));
    }
  });

  test('los aportes de cada factor suman el puntaje total', () {
    final r = scoreCandidate(seedCandidates.first, bandaMax: 1300000, weights: HcaiWeights.defaults);
    final sum = HcaiFactor.values.fold<double>(0, (s, f) => s + r.contribution(f));
    expect(sum, closeTo(r.score, 0.001));
  });

  test('una compensación fuera de banda baja el factor de presupuesto', () {
    final david = seedCandidates.firstWhere((c) => c.nombre == 'David Peña');
    final r = scoreCandidate(david, bandaMax: 1300000, weights: HcaiWeights.defaults);
    expect(r.values[HcaiFactor.presupuesto], lessThan(0.5));
    // Su feedback es "No recomendado" (0), así que ese es su punto más débil.
    expect(r.weakest, HcaiFactor.feedback);
  });

  test('cambiar los pesos cambia el orden', () {
    final soloAssess = HcaiWeights({for (final f in HcaiFactor.values) f: f == HcaiFactor.assessFirst ? 50 : 0});
    final ranking = rankCandidates(seedCandidates, bandaFor: banda, weights: soloAssess);
    expect(ranking.first.candidate.nombre, 'Sofia Herrera'); // AssessFirst 95 %
  });
}
