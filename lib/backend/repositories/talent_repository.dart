import '../models/app_alert.dart';
import '../models/candidate.dart';
import '../models/hiring_record.dart';
import '../models/person.dart';
import '../models/vacancy.dart';

/// Contrato de acceso a datos. La UI solo depende de esta interfaz,
/// así se puede cambiar entre datos locales (demo) y Firestore.
abstract interface class TalentRepository {
  Stream<List<Candidate>> watchCandidates({String? vacancyId});
  Stream<List<Vacancy>> watchVacancies();
  Stream<List<AppAlert>> watchAlerts();
  Stream<List<Person>> watchPeople();

  /// Historial de vacantes del área para el Dashboard de Atracción de Talento.
  Stream<List<HiringRecord>> watchHiringHistory();
  Future<void> moveCandidate(String candidateId, int etapa);
}
