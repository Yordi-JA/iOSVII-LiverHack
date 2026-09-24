import 'package:cloud_firestore/cloud_firestore.dart';

import 'seed_data.dart';
import 'seed_history.dart';

/// Sube los datos de prueba a Firestore. Se ejecuta una sola vez
/// después de configurar Firebase (ver README).
Future<void> seedFirestore(FirebaseFirestore db) async {
  final batch = db.batch();
  for (final c in seedCandidates) {
    batch.set(db.collection('candidatos').doc(c.id), c.toMap());
  }
  for (final v in seedVacancies) {
    batch.set(db.collection('vacantes').doc(v.id), v.toMap());
  }
  for (final a in seedAlerts) {
    batch.set(db.collection('alertas').doc(a.id), a.toMap());
  }
  for (final p in seedPeople) {
    batch.set(db.collection('users').doc(p.id), p.toMap());
  }
  for (final h in generateHiringHistory()) {
    batch.set(db.collection('historial_vacantes').doc(h.id), h.toMap());
  }
  await batch.commit();
}
