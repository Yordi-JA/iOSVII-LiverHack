import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_alert.dart';
import 'models/candidate.dart';
import 'models/person.dart';
import 'models/vacancy.dart';
import 'repositories/mock_talent_repository.dart';
import 'repositories/talent_repository.dart';

/// Se sobrescribe en main.dart con FirestoreTalentRepository
/// cuando Firebase está configurado.
final talentRepositoryProvider = Provider<TalentRepository>((ref) => MockTalentRepository());

final vacanciesProvider = StreamProvider<List<Vacancy>>(
  (ref) => ref.watch(talentRepositoryProvider).watchVacancies(),
);

final alertsProvider = StreamProvider<List<AppAlert>>(
  (ref) => ref.watch(talentRepositoryProvider).watchAlerts(),
);

final peopleProvider = StreamProvider<List<Person>>(
  (ref) => ref.watch(talentRepositoryProvider).watchPeople(),
);

final allCandidatesProvider = StreamProvider<List<Candidate>>(
  (ref) => ref.watch(talentRepositoryProvider).watchCandidates(),
);

final candidatesByVacancyProvider = StreamProvider.family<List<Candidate>, String>(
  (ref, vacancyId) => ref.watch(talentRepositoryProvider).watchCandidates(vacancyId: vacancyId),
);
