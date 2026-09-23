import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/candidate.dart';
import '../../data/models/vacancy.dart';
import '../../data/providers.dart';
import 'hcai_scoring.dart';

/// Pesos elegidos por la persona reclutadora.
class HcaiWeightsNotifier extends Notifier<HcaiWeights> {
  @override
  HcaiWeights build() => HcaiWeights.defaults;

  void set(HcaiFactor factor, int weight) => state = state.copyWith(factor, weight);

  void reset() => state = HcaiWeights.defaults;
}

final hcaiWeightsProvider = NotifierProvider<HcaiWeightsNotifier, HcaiWeights>(HcaiWeightsNotifier.new);

/// Modo ciego: oculta nombre y foto para evaluar sin sesgos.
class BlindModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final blindModeProvider = NotifierProvider<BlindModeNotifier, bool>(BlindModeNotifier.new);

/// Candidatos elegidos para compararse lado a lado (máximo 3).
class CompareSelectionNotifier extends Notifier<List<String>> {
  static const max = 3;

  @override
  List<String> build() => const [];

  void toggle(String id) {
    if (state.contains(id)) {
      state = state.where((e) => e != id).toList();
    } else if (state.length < max) {
      state = [...state, id];
    }
  }

  void clear() => state = const [];
}

final compareSelectionProvider =
    NotifierProvider<CompareSelectionNotifier, List<String>>(CompareSelectionNotifier.new);

/// Top 10 por potencial HCAI con los pesos actuales.
final hcaiRankingProvider = Provider<List<HcaiResult>?>((ref) {
  final candidates = ref.watch(allCandidatesProvider).value;
  final vacancies = ref.watch(vacanciesProvider).value;
  if (candidates == null || vacancies == null) return null;
  return rankCandidates(
    candidates,
    bandaFor: (c) => _banda(vacancies, c),
    weights: ref.watch(hcaiWeightsProvider),
  ).take(10).toList();
});

int _banda(List<Vacancy> vacancies, Candidate c) =>
    vacancies.where((v) => v.id == c.vacanteId).firstOrNull?.bandaMax ?? 0;
