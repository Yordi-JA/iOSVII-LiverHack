import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notas compartidas de la entrevista de un candidato (lienzo colaborativo
/// entre Reclutamiento y el Hiring manager). Es el único módulo que usa
/// Firestore; el resto de la app sigue en `LiverhackStore`.
abstract interface class EntrevistasRepository {
  /// `true` si las notas se sincronizan en tiempo real con Firestore.
  bool get enLinea;

  /// Notas actuales del candidato; emite de nuevo con cada cambio de cualquier usuario.
  Stream<String> watchNotas(int candidatoId);

  Future<void> actualizarNotas(int candidatoId, String texto, {String? autor});
}

/// Documento `entrevistas/candidato_{id}` con el campo `notas`.
class FirestoreEntrevistasRepository implements EntrevistasRepository {
  FirestoreEntrevistasRepository(this._db);

  final FirebaseFirestore _db;

  static const coleccion = 'entrevistas';

  DocumentReference<Map<String, dynamic>> _doc(int candidatoId) =>
      _db.collection(coleccion).doc('candidato_$candidatoId');

  @override
  bool get enLinea => true;

  @override
  Stream<String> watchNotas(int candidatoId) =>
      _doc(candidatoId).snapshots().map((s) => (s.data()?['notas'] as String?) ?? '');

  @override
  Future<void> actualizarNotas(int candidatoId, String texto, {String? autor}) => _doc(candidatoId).set({
    'notas': texto,
    'candidato_id': candidatoId,
    'actualizado': FieldValue.serverTimestamp(),
    'autor': ?autor,
  }, SetOptions(merge: true));
}

/// Respaldo en memoria cuando Firebase no está configurado: el lienzo
/// funciona dentro de la sesión, sin sincronizar con otros equipos.
class LocalEntrevistasRepository implements EntrevistasRepository {
  final _notas = <int, String>{};
  final _cambios = StreamController<int>.broadcast();

  @override
  bool get enLinea => false;

  @override
  Stream<String> watchNotas(int candidatoId) async* {
    yield _notas[candidatoId] ?? '';
    yield* _cambios.stream.where((id) => id == candidatoId).map((_) => _notas[candidatoId] ?? '');
  }

  @override
  Future<void> actualizarNotas(int candidatoId, String texto, {String? autor}) async {
    _notas[candidatoId] = texto;
    _cambios.add(candidatoId);
  }

  void dispose() => _cambios.close();
}

/// Si Firebase se inicializó. `main.dart` lo sobrescribe con el resultado de
/// `Firebase.initializeApp`; en tests queda en `false`.
final firebaseDisponibleProvider = Provider<bool>((ref) => false);

final entrevistasRepositoryProvider = Provider<EntrevistasRepository>((ref) {
  if (ref.watch(firebaseDisponibleProvider)) return FirestoreEntrevistasRepository(FirebaseFirestore.instance);
  final local = LocalEntrevistasRepository();
  ref.onDispose(local.dispose);
  return local;
});

/// Notas del lienzo colaborativo del candidato, en tiempo real.
final notasEntrevistaProvider = StreamProvider.family<String, int>(
  (ref, candidatoId) => ref.watch(entrevistasRepositoryProvider).watchNotas(candidatoId),
);
