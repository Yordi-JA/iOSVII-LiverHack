import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend/candidatos/seed_repository.dart';
import 'backend/entrevistas/entrevistas_repository.dart';
import 'backend/providers.dart';
import 'firebase_options.dart';
import 'frontend/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rol, vacante activa y decisiones del módulo de Candidatos sobreviven a
  // una recarga. Si el almacenamiento falla, la demo arranca desde el seed.
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}

  // Firebase solo alimenta el lienzo colaborativo de entrevistas. Si faltan
  // credenciales (lib/firebase_options.dart provisional) la app sigue
  // funcionando y el lienzo usa su modo local.
  var firebaseListo = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseListo = true;
  } catch (e) {
    debugPrint('Firebase no disponible, el lienzo de entrevistas usará modo local: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        liverhackStoreProvider.overrideWithValue(LiverhackStore(prefs)),
        firebaseDisponibleProvider.overrideWithValue(firebaseListo),
      ],
      child: const PuertaLiverpoolApp(),
    ),
  );
}
