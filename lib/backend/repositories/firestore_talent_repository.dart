import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_alert.dart';
import '../models/candidate.dart';
import '../models/hiring_record.dart';
import '../models/person.dart';
import '../models/vacancy.dart';
import 'talent_repository.dart';

/// Implementación con Cloud Firestore. Los listeners en tiempo real hacen
/// que cualquier cambio (por ejemplo, un feedback) se vea al instante.
class FirestoreTalentRepository implements TalentRepository {
  FirestoreTalentRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Candidate>> watchCandidates({String? vacancyId}) {
    Query<Map<String, dynamic>> query = _db.collection('candidatos');
    if (vacancyId != null) query = query.where('vacante_id', isEqualTo: vacancyId);
    return query.snapshots().map(
          (s) => s.docs.map((d) => Candidate.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Stream<List<Vacancy>> watchVacancies() => _db
      .collection('vacantes')
      .snapshots()
      .map((s) => s.docs.map((d) => Vacancy.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<AppAlert>> watchAlerts() => _db
      .collection('alertas')
      .snapshots()
      .map((s) => s.docs.map((d) => AppAlert.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<Person>> watchPeople() => _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => Person.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<HiringRecord>> watchHiringHistory() => _db
      .collection('historial_vacantes')
      .snapshots()
      .map((s) => s.docs.map((d) => HiringRecord.fromMap(d.id, d.data())).toList());

  @override
  Future<void> moveCandidate(String candidateId, int etapa) async {
    await _db.collection('candidatos').doc(candidateId).update({'etapa_actual': etapa});
    await _db.collection('eventos').add({
      'accion': 'cambio_etapa',
      'candidato_id': candidateId,
      'etapa': etapa,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
