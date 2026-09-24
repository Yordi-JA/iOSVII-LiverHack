import 'dart:async';

import '../models/app_alert.dart';
import '../models/candidate.dart';
import '../models/hiring_record.dart';
import '../models/person.dart';
import '../models/vacancy.dart';
import '../seed/seed_data.dart';
import '../seed/seed_history.dart';
import 'talent_repository.dart';

/// Repositorio en memoria con los datos de prueba. Permite correr la demo
/// sin Firebase configurado.
class MockTalentRepository implements TalentRepository {
  MockTalentRepository() : _candidates = [...seedCandidates];

  final List<Candidate> _candidates;
  final _candidatesController = StreamController<List<Candidate>>.broadcast();

  @override
  Stream<List<Candidate>> watchCandidates({String? vacancyId}) async* {
    List<Candidate> filter(List<Candidate> all) =>
        vacancyId == null ? all : all.where((c) => c.vacanteId == vacancyId).toList();
    yield filter(_candidates);
    yield* _candidatesController.stream.map(filter);
  }

  @override
  Stream<List<Vacancy>> watchVacancies() => Stream.value(seedVacancies);

  @override
  Stream<List<AppAlert>> watchAlerts() => Stream.value(seedAlerts);

  @override
  Stream<List<Person>> watchPeople() => Stream.value(seedPeople);

  @override
  Stream<List<HiringRecord>> watchHiringHistory() => Stream.value(generateHiringHistory());

  @override
  Future<void> moveCandidate(String candidateId, int etapa) async {
    final index = _candidates.indexWhere((c) => c.id == candidateId);
    if (index == -1) return;
    final current = _candidates[index];
    _candidates[index] = Candidate.fromMap(current.id, {...current.toMap(), 'etapa_actual': etapa});
    _candidatesController.add(List.unmodifiable(_candidates));
  }
}
