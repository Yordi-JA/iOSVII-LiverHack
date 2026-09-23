import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vacante que se muestra en Procesos durante la demo.
const procesosVacancyId = 'v1';

/// Candidato con el popup abierto (al tocar su rostro).
class SelectedCandidateNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedCandidateProvider =
    NotifierProvider<SelectedCandidateNotifier, String?>(SelectedCandidateNotifier.new);

/// Etapa por la que se filtran los carriles (al tocar un círculo del flujo).
class StageFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void toggle(int stage) => state = state == stage ? null : stage;

  void clear() => state = null;
}

final stageFilterProvider = NotifierProvider<StageFilterNotifier, int?>(StageFilterNotifier.new);
